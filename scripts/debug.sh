#!/usr/bin/env bash

set -e

make

qemu-system-arm \
    -M mps2-an385 \
    -kernel build/kernel.elf \
    -nographic \
    -S \
    -gdb tcp::1234