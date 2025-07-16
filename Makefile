# Compiler and assembler
NASM = nasm
GCC = gcc

# Directories
SRC_DIR = src
BUILD_DIR = build

# Source files
ASM_SOURCES = $(SRC_DIR)/print.asm $(SRC_DIR)/initsock.asm $(SRC_DIR)/createwindow.asm $(SRC_DIR)/main.asm
OBJ_FILES = $(BUILD_DIR)/print.o $(BUILD_DIR)/initsock.o $(BUILD_DIR)/createwindow.o $(BUILD_DIR)/main.o

# Output binary
OUTPUT = $(BUILD_DIR)/main

# Default target
all: $(OUTPUT)

# Install dependencies
deps:
	@echo "Installing dependencies..."
	@sudo apt-get update && sudo apt-get install -y nasm gcc xorg xserver-xorg xauth libx11-dev xvfb
	@echo "Setting up virtual framebuffer..."
	@sudo mkdir -p /tmp/.X11-unix
	@sudo chmod 1777 /tmp/.X11-unix
	@if ! pgrep Xvfb > /dev/null; then \
		Xvfb :99 -screen 0 1024x768x16 & \
		sleep 2; \
	fi
	@DISPLAY=:99.0 xset s off
	@echo "DISPLAY=:99.0" >> ~/.bashrc
	@echo "export DISPLAY" >> ~/.bashrc
	@echo "Checking X11 environment..."
	@echo "DISPLAY=${DISPLAY}"
	@if [ -z "$$DISPLAY" ]; then \
		echo "Please run: export DISPLAY=:99.0"; \
	fi
	@echo "Installing X11 development files..."
	@if [ ! -d "libx11" ]; then \
		git clone https://gitlab.freedesktop.org/xorg/lib/libx11.git; \
	fi

# Add this new target to run with proper display setting
run-x11: $(OUTPUT)
	DISPLAY=:99.0 ./$(OUTPUT)

# Compile assembly files into object files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm
	@mkdir -p $(BUILD_DIR)
	$(NASM) -f elf64 -o $@ $<
	@if [ $$? -ne 0 ]; then echo "Error assembling $<"; exit 1; fi

# Link object files into the final binary
$(OUTPUT): $(OBJ_FILES)
	$(GCC) -o $@ $^ -static -nostartfiles -no-pie -Wl,--gc-sections
	@if [ $$? -ne 0 ]; then echo "Error linking object files"; exit 1; fi

# Run the compiled binary
run: $(OUTPUT)
	./$(OUTPUT)

# Clean build directory
clean:
	rm -rf $(BUILD_DIR)

# Phony targets
.PHONY: all run clean deps run-x11