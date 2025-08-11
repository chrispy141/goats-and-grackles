# Variables
CL65 = cl65
CA65 = ca65
CFG = c64-asm.cfg
OUTDIR = build
TARGET = $(OUTDIR)/game.prg
MAIN_SRC = src/main.s
MAIN_OBJ = $(OUTDIR)/main.o
EMU = x64

# Default target - build everything
all: tree $(TARGET)

# Build final linked PRG from object(s)
$(TARGET): $(MAIN_OBJ) | $(OUTDIR)
	$(CL65) -C $(CFG) -o $@ $(MAIN_OBJ)

# Assemble main.s to object file
$(MAIN_OBJ): $(MAIN_SRC) | $(OUTDIR)
	$(CA65) -o $@ $(MAIN_SRC)

# Run your tree generation script (generate assets, etc.)
tree:
	python3 tools/treegen.py tools/tree.spm tools/config.json

# Create output dir if needed
$(OUTDIR):
	mkdir -p $(OUTDIR)

# Clean: remove all build artifacts including objects and final binary
clean:
	rm -rf $(OUTDIR)/*
	rm src/objects/tree.inc

# Run emulator on the final PRG
run: $(TARGET)
	$(EMU) $(TARGET)
