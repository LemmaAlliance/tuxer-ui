#!/bin/bash
# Should compile to a .o file when going into prod, will compile to a bin for now.

nasm -f elf64 -o build/print.o src/print.asm
if [[ $? -ne 0 ]]; then
    echo "Error assembling hello.asm"
    exit 1
fi

nasm -f elf64 -o build/initsock.o src/initsock.asm
if [[ $? -ne 0 ]]; then
    echo "Error assembling initsock.asm"
    exit 1
fi

nasm -f elf64 -o build/main.o src/main.asm
if [[ $? -ne 0 ]]; then
    echo "Error assembling main.asm"
    exit 1
fi

gcc -o build/main build/main.o build/print.o build/initsock.o -static -nostartfiles -no-pie -Wl,--gc-sections
if [[ $? -ne 0 ]]; then
    echo "Error linking object files"
    exit 1
fi