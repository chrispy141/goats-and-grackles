# Project settings
TARGET = game
BUILD_DIR = build
SRC_DIR = src

# Tools
CL65 = cl65
X64 = x64

# Config
CFG = c64-asm.cfg
PRG = $(BUILD_DIR)/$(TARGET).prg
MAIN = $(SRC_DIR)/main.s

# Default target
all: $(PRG)

# Build PRG
$(PRG): $(MAIN)
	@mkdir -p $(BUILD_DIR)
	$(CL65) -C $(CFG) -u __EXEHDR__ -o $(PRG) $(MAIN)

# Run in VICE
run: $(PRG)
	$(X64) $(PRG)

# Clean build files
clean:
	rm -rf $(BUILD_DIR)/*.o $(BUILD_DIR)/*.prg
