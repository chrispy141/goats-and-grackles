import json
import sys
import os

def spm_to_bytes(filename, config_path, out_path):
    # Load sprite data
    with open(filename, 'r') as f:
        data = json.load(f)

    # Load config mapping character -> { petscii, color }
    with open(config_path, 'r') as f:
        config = json.load(f)

    sprite = data['sprites'][0]
    pixels = sprite['pixels']

    lines = []
    num_pts = 0
    for y, row in enumerate(pixels):
        for x, pixel in enumerate(row):
            # Expect pixel to be a character key in config or zero/empty
            if pixel and pixel in config:
                x_bin = f"%{x:08b}"
                y_bin = f"%{y:08b}"

                petscii_char = config[pixel]['petscii']
                color_code = config[pixel]['color']

                # Format petscii and color as hex bytes
                petscii_hex = f"${petscii_char:02X}"
                color_hex = f"${color_code:02X}"

                # Output 4 bytes: x, y, petscii char, color code
                lines.append(f".byte {x_bin}, {y_bin}, {petscii_hex}, {color_hex}")
                num_pts += 1
                if num_pts > 63:
                    print("Error: More than 63 points found, Unsupported tree size.")
                    exit(1)
    print(f"Generated {num_pts} points.")
    # Write output file
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    lines.insert(0, f".byte ${num_pts:02X}")  # Number of points
    with open(out_path, 'w') as out_file:
        out_file.write("tree_points:\n")
        out_file.write("\n".join(lines))

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} filename.spm config.json")
        sys.exit(1)

    input_filename = sys.argv[1]
    config_filename = sys.argv[2]
    output_filename = "src/objects/tree.inc"

    spm_to_bytes(input_filename, config_filename, output_filename)
    print(f"Output written to {output_filename}")
