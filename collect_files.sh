#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <input_dir> <output_dir> [--max_depth <depth>]"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
MAX_DEPTH=""

while [ $# -gt 2 ]; do
    case "$3" in
        --max_depth)
            shift
            if [[ ! "$3" =~ ^[0-9]+$ ]]; then
                echo "Error: --max_depth must be a positive integer"
                exit 1
            fi
            MAX_DEPTH="$3"
            shift
            ;;
        *)
            echo "Unknown option: $3"
            exit 1
            ;;
    esac
done

if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

PYTHON_SCRIPT=$(cat << 'EOF'
import os
import sys
from shutil import copy2

input_dir = sys.argv[1]
output_dir = sys.argv[2]
max_depth = int(sys.argv[3]) if sys.argv[3] else float('inf')

def get_unique_filename(out_dir, filename, counter=1):
    base, ext = os.path.splitext(filename)
    new_filename = filename
    while os.path.exists(os.path.join(out_dir, new_filename)):
        new_filename = f"{base}{counter}{ext}"
        counter += 1
    return new_filename

def copy_files(input_path, output_path, current_depth=0):
    if current_depth > max_depth:
        return
    for entry in os.listdir(input_path):
        full_path = os.path.join(input_path, entry)
        if os.path.isfile(full_path):
            unique_filename = get_unique_filename(output_path, entry)
            copy2(full_path, os.path.join(output_path, unique_filename))
        elif os.path.isdir(full_path):
            copy_files(full_path, output_path, current_depth + 1)

copy_files(input_dir, output_dir)
EOF
)

echo "$PYTHON_SCRIPT" | python3 - "$INPUT_DIR" "$OUTPUT_DIR" "$MAX_DEPTH"

exit 0
