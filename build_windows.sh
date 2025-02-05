#!/bin/bash
set -e  # Exit if any command fails

# 🛠️ Step 1: Compile Assembly Code
echo "🔨 Compiling assembly files..."
mkdir -p build
nasm -f elf64 -o build/print.o src/print.asm
nasm -f elf64 -o build/initsock.o src/initsock.asm
nasm -f elf64 -o build/main.o src/main.asm

# 🏗️ Step 2: Link Object Files into a Static Binary
echo "🔗 Linking object files..."
gcc -o build/main build/main.o build/print.o build/initsock.o \
    -static -nostartfiles -no-pie -Wl,--gc-sections

# 🏗️ Step 3: Create Minimal Linux Filesystem
echo "📁 Creating minimal Linux filesystem..."
rm -rf rootfs
mkdir -p rootfs/bin rootfs/lib rootfs/usr/lib rootfs/tmp

# Copy the program
cp build/main rootfs/bin/
chmod +x rootfs/bin/main

# Create a startup script for TinyEMU
cat > rootfs/bin/run.sh <<EOF
#!/bin/sh
export DISPLAY=:0
Xvfb :0 -screen 0 1024x768x24 &
sleep 1
exec /bin/main
EOF
chmod +x rootfs/bin/run.sh

# 📦 Step 4: Pack Filesystem into a Compressed Image
echo "📦 Creating compressed root filesystem..."
cd rootfs
find . | cpio -o -H newc | gzip > ../rootfs.cpio.gz
cd ..

# 🚀 Step 5: Download TinyEMU for Windows
echo "🔽 Downloading TinyEMU for Windows..."
wget -nc -O tinyemu-windows64.exe https://bellard.org/tinyemu/tinyemu-windows64

# 🎬 Step 6: Create Windows Batch Launcher
echo "📜 Creating Windows batch script..."
cat > start.bat <<EOF
@echo off
tinyemu-windows64.exe -i rootfs.cpio.gz -m 256
EOF

# 📦 Step 7: Package Everything into a Self-Extracting EXE
echo "📦 Creating self-extracting EXE..."
mkdir -p package
cp tinyemu-windows64.exe rootfs.cpio.gz start.bat package/

# Use WinRAR or 7-Zip to create a single EXE (you need to have `rar` installed)
rar a -sfx myprogram.exe package/*

# 🎉 Done!
echo "✅ Build complete! Your Windows EXE is: myprogram.exe"
