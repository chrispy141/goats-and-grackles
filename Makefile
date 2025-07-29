# Variables
CL65 = cl65
CA65 = ca65
CFG = c64-asm.cfg
OUTDIR = build
TARGET = $(OUTDIR)/game.prg
MAIN_SRC = src/main.s
MAIN_OBJ = $(OUTDIR)/main.o
EMU = x64

# Default target
all: $(TARGET)

# Build PRG by linking main object and library object
$(TARGET): $(MAIN_OBJ) | $(OUTDIR)
	$(CL65) -C $(CFG) -u __EXEHDR__ -o $@ $(MAIN_OBJ) 

# Assemble main.s into build/main.o
$(MAIN_OBJ): $(MAIN_SRC) | $(OUTDIR)
	$(CA65) -o $@ $(MAIN_SRC)

# Create build directory if missing
$(OUTDIR):
	mkdir -p $(OUTDIR)

# Run in VICE emulator
run: $(TARGET)
	$(EMU) $(TARGET)

# Clean build artifacts
clean:
	rm -f $(OUTDIR)/*