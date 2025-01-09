import os
from pathlib import Path

def combine_swift_files(directory):
    # Get the Downloads directory path
    downloads_path = str(Path.home() / "Downloads")
    output_file = os.path.join(downloads_path, "combined.swift")
    
    # Create the combined file in Downloads directory
    with open(output_file, "w") as outfile:
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith(".swift"):
                    file_path = os.path.join(root, file)
                    with open(file_path, "r") as infile:
                        outfile.write(f"// Contents of {file_path}\n")
                        outfile.write(infile.read())
                        outfile.write("\n\n")
    print(f"Swift files combined into {output_file}")

# Specify the directory to start from (e.g., '.')
combine_swift_files(".")