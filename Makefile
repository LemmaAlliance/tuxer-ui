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
.PHONY: all run clean