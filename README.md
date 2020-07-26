# microski

See [this Talospace article](https://www.talospace.com/2020/07/the-littlest-power9-booter.html).

## How to build

1. You will need either a real OpenPOWER machine (POWER8 and up) or a
cross-assembling toolchain such as a cross-building `gas` and `bintools`.

1. Edit the `Makefile` as appropriate to point to your toolchain.

1. `make` will generate `be_payload.elf` and `le_payload.elf`. You can
run them in QEMU using the `-kernel` option; you still need `skiboot.lid`
or the equivalent to actually kick it off.

Copyright 2014-2016 IBM Corp.
Copyright 2020 Cameron Kaiser.
Apache 2.0 or GPL 2.0 or later.
