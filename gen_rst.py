import os
import re

# Define the base directory
base_dir = os.path.dirname(os.path.abspath(__file__))
source_dir = os.path.join(base_dir, 'docs', 'source')
sloth_dir = os.path.join(base_dir, 'Sloth')

# Ensure source directory exists
os.makedirs(source_dir, exist_ok=True)

# Regular expressions to identify classes and methods
class_pattern = re.compile(r'class\s+(\w+)')
method_pattern = re.compile(r'def\s+(\w+)\s*\(.*\)')

def parse_classes_and_methods(pyx_file):
    """ Parse the .pyx file to get classes and their methods """
    classes = {}
    current_class = None
    
    with open(pyx_file, 'r') as f:
        for line in f:
            class_match = class_pattern.search(line)
            if class_match:
                class_name = class_match.group(1)
                if not class_name.startswith('_'):
                    current_class = class_name
                    classes[current_class] = []
            if current_class:
                method_match = method_pattern.search(line)
                if method_match:
                    method_name = method_match.group(1)
                    if not method_name.startswith('_'):
                        classes[current_class].append(method_name)
    
    return classes

def create_rst_files(classes, class_name, module_path):
    """ Create rst files for each method in the class """
    class_dir = os.path.join(source_dir, class_name.lower())
    os.makedirs(class_dir, exist_ok=True)
    
    class_rst_path = os.path.join(class_dir, f'{class_name.lower()}.rst')
    with open(class_rst_path, 'w') as class_rst:
        class_rst.write(f"{class_name}\n{'=' * len(class_name)}\n\n")
        class_rst.write(f".. autoclass:: {module_path}.{class_name}\n\n")
        class_rst.write(f"Methods\n-------\n\n")

        class_rst.write(f".. toctree::\n   :maxdepth: 1\n\n")

        # Create method rst files
        for method in classes[class_name]:
            method_rst_path = os.path.join(class_dir, f'{method.lower()}.rst')
            with open(method_rst_path, 'w') as method_rst:
                method_rst.write(f"{method}\n{'=' * len(method)}\n\n")
                method_rst.write(f".. automethod:: {module_path}.{class_name}.{method}\n\n")

            # Add method reference in class rst
            class_rst.write(f"   {method}\n\n")

def main():
    # Iterate over pyx files and generate rst files
    for root, _, files in os.walk(sloth_dir):
        for file in files:
            if file.endswith('.pyx'):
                pyx_path = os.path.join(root, file)
                classes = parse_classes_and_methods(pyx_path)
                
                # Get the module path relative to the sloth_dir
                module_path = os.path.relpath(pyx_path, sloth_dir).replace(os.sep, '.')[:-4]
                module_path = f'Sloth.{module_path}'

                for class_name in classes:
                    create_rst_files(classes, class_name, module_path)

if __name__ == "__main__":
    main()
