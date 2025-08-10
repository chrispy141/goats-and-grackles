import json
import sys
import os

def spm_to_bytes(filename, out_path):
    with open(filename, 'r') as f:
        data = json.load(f)

    sprite = data['sprites'][0]
    pixels = sprite['pixels']

    lines = []
    num_pts = 0
    for y, row in enumerate(pixels):
        for x, pixel in enumerate(row):
            if pixel != 0:
                x_bin = f"%{x:08b}"
                y_bin = f"%{y:08b}"
                lines.append(f".byte {x_bin}, {y_bin}")
                num_pts += 1

    # Write to output file
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    lines.insert(0, f".byte ${num_pts:02X}")  # First line is the number of points in hex
    with open(out_path, 'w') as out_file:
        out_file.write("tree_points:\n")
        out_file.write("\n".join(lines))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} filename.spm")
        sys.exit(1)

    input_filename = sys.argv[1]
    output_filename = "src/objects/tree.inc"

    spm_to_bytes(input_filename, output_filename)
    print(f"Output written to {output_filename}")
