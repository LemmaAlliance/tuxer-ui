# Should compile to a .o file when going into prod, will compile to a bin for now.

nasm -f elf64 -o build/hello.o src/hello.asm
if [ $? -ne 0 ]; then
    echo "Error assembling hello.asm"
    exit 1
fi

nasm -f elf64 -o build/main.o src/main.asm
if [ $? -ne 0 ]; then
    echo "Error assembling main.asm"
    exit 1
fi

gcc -o build/main build/main.o build/hello.o -static -nostartfiles
if [ $? -ne 0 ]; then
    echo "Error linking object files"
    exit 1
fi