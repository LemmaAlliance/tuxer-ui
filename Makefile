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
	@if ! pgrep Xvfb > /dev/null; then \
		Xvfb :99 -screen 0 1024x768x16 & \
		echo "Started Xvfb"; \
	fi
	@export DISPLAY=:99
	@echo "Checking X11 environment..."
	@echo "DISPLAY=${DISPLAY}"
	@if [ -z "$$DISPLAY" ]; then \
		echo "Warning: No DISPLAY variable set"; \
	fi
	@echo "Installing X11 development files..."
	@if [ ! -d "libx11" ]; then \
		git clone https://gitlab.freedesktop.org/xorg/lib/libx11.git; \
	fi

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
.PHONY: all run clean deps