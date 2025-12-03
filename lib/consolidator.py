import os

def compile_codebase_to_text(root_dir, output_file):
    """
    Recursively gathers all files in a codebase and compiles them
    into a single text file with folder structure annotations.
    """
    with open(output_file, 'w', encoding='utf-8') as out_file:
        for dirpath, dirnames, filenames in os.walk(root_dir):
            # Write folder header
            relative_path = os.path.relpath(dirpath, root_dir)
            folder_header = f"\n{'='*80}\nFolder: {relative_path}\n{'='*80}\n"
            out_file.write(folder_header)
            
            for filename in filenames:
                file_path = os.path.join(dirpath, filename)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        file_content = f.read()
                except Exception as e:
                    file_content = f"Could not read file: {e}"
                
                # Write file header and content
                file_header = f"\n{'-'*60}\nFile: {filename}\n{'-'*60}\n"
                out_file.write(file_header)
                out_file.write(file_content + "\n")

    print(f"Codebase compiled successfully into {output_file}")


if __name__ == "__main__":
    # Current working directory
    root_directory = os.getcwd()
    output_text_file = os.path.join(root_directory, "compiled_codebase.txt")
    
    compile_codebase_to_text(root_directory, output_text_file)

