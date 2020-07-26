// SPDX-License-Identifier: Apache-2.0 OR GPL-2.0-or-later
/*
 * hello_kernel.S!
 *
 * Because skiboot has its own stack, we don't even need that!
 * All we need to do is make an OPAL call to write to the console.
 *
 * Copyright 2014-2016 IBM Corp.
 * Copyright 2020 Cameron Kaiser
 */

        .text
        .align 2
	.globl _start
_start:

#ifdef __LITTLE_ENDIAN__
	/* OPAL calls must be made from big-endian */
#define OPAL_CALL bl le_opal_call

	/* Manually encode big-endian instructions, only (h)rfid can switch */
#define GO_LITTLE_ENDIAN \
	.long 0x05009f42 ;/* bcl 20,31,*+4 */ \
	.long 0xa602487d ;/* mflr r10 */ \
	.long 0x1c004a39 ;/* addi r10,r10,28 */ \
	.long 0xa600607d ;/* mfmsr r11 */ \
	.long 0x01006b69 ;/* xori r11,r11,1 */ \
	.long 0xa6035a7d ;/* mtsrr0 r10 */ \
	.long 0xa6037b7d ;/* mtsrr1 r11 */ \
	.long 0x2400004c  /* rfid */

	/* We start big-endian but immediately become little-endian */
	GO_LITTLE_ENDIAN

#else
	/* As the simplest case we can simply call OPAL directly in BE */
#define OPAL_CALL mr %r2, %r13 ; mtctr %r14 ; bctrl
#endif

/*
 * Save some values passed in from skiboot into registers that are
 * non-volatile over OPAL calls.
 *   r8 is the OPAL base
 *   r9 is the OPAL entry point
 */

	mr	%r13, %r8
	mr	%r14, %r9

	bl	here
here:	mflr	%r8 /* work out where we are running */

	li	%r0, 1 /* OPAL_CONSOLE_WRITE */
	li	%r3, 0 /* terminal 0 */
	addi	%r4, %r8, len - here /* ptr to length of string */
	addi	%r5, %r8, str - here /* ptr to string start */
	OPAL_CALL

	li	%r0, 5 /* OPAL_CEC_POWER_DOWN */
	li	%r3, 0 /* normal shutdown */
	OPAL_CALL

	/* We shouldn't get here but if we do, just wait here */
	b	.

len:
	/* This value is read by OPAL so it must be big-endian in both modes */
	.long 0x00
#ifdef __LITTLE_ENDIAN__
	/* byte-universal form of BE .long (strend - str) */
	.byte 0
	.byte 0
	.byte 0
	.byte (strend - str)
#else
	.long (strend - str)
#endif

str:
	.string "Hello World!\n"
strend:

#ifdef __LITTLE_ENDIAN__

	.align 2

le_opal_call:
	/* OPAL calls must be in big-endian mode; only (h)rfid can switch */
	/* On call, r0, r3 ... should already be set */
	/* Assume OPAL base is still in r13 and entry point is still in r14 */

	/* Save current MSR in non-volatile r15 */
	mfmsr	%r15
	/* Save return address in non-volatile r16 */
	mflr	%r16

	/* Turn off the LE bit in MSR (ordinarily also do DR, IR and EE) */
	li	%r11, 0x01
	andc	%r11, %r15, %r11

	/* Get address of trampoline */
	bl	.+4
	mflr	%r12 /* 0 */
	addi	%r12, %r12, 28 /* 32 bytes between the mflr and the return */
	mtlr	%r12
	
	/* 12 */
	/* We need a return trampoline to return to little endian mode */
	/* Put the trampoline address in LR, OPAL entry in SRR0, MSR in SRR1 */
	mr %r2, %r13
	mtsrr0 	%r14
	mtsrr1	%r11

	/* 24 */
	/* Do it */
	rfid

	/* 28 */
	/* Trampoline here returns us to LE and restores MSR and LR */
	GO_LITTLE_ENDIAN
	mtmsr	%r15
	mtlr	%r16
	blr

#endif
