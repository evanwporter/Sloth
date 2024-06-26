import os
import re

# Define the base directory
base_dir = os.path.dirname(os.path.abspath(__file__))
source_dir = os.path.join(base_dir, 'docs', 'source')
sloth_dir = os.path.join(base_dir, 'Sloth')

# Ensure source directory exists
os.makedirs(source_dir, exist_ok=True)

# Regular expressions to identify classes, methods, and properties
class_pattern = re.compile(r'class\s+(\w+)')
method_pattern = re.compile(r'def\s+(\w+)\s*\(.*\)')
property_pattern = re.compile(r'^\s*@property', re.MULTILINE)

def parse_classes_and_methods(pyx_file):
    """ Parse the .pyx file to get classes and their methods """
    classes = {}
    current_class = None
    in_property = False
    
    with open(pyx_file, 'r') as f:
        lines = f.readlines()
        for i, line in enumerate(lines):
            if property_pattern.match(line):
                in_property = True
                continue

            if in_property and method_pattern.search(line):
                in_property = False
                continue

            class_match = class_pattern.search(line)
            if class_match:
                class_name = class_match.group(1)
                if not class_name.startswith('_'):
                    current_class = class_name
                    classes[current_class] = []
            if current_class:
                method_match = method_pattern.search(line)
                if method_match and not in_property:
                    method_name = method_match.group(1)
                    if not method_name.startswith('_'):
                        classes[current_class].append(method_name)
    
    return classes

def create_rst_files(classes, class_name, module_path, file_name):
    """ Create rst files for each class and method """
    # Create directory for the pyx file
    file_dir = os.path.join(source_dir, file_name.lower())
    os.makedirs(file_dir, exist_ok=True)
    
    # Create directory for the class within the pyx file directory
    class_dir = os.path.join(file_dir, class_name.lower())
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
                
                # Extract file name without extension for directory creation
                file_name = os.path.splitext(file)[0]
                
                for class_name in classes:
                    create_rst_files(classes, class_name, module_path, file_name)

if __name__ == "__main__":
    main()
