from setuptools import setup, find_packages, Extension
import os

def get_extensions():
    return [
        # Extension("Sloth.conversions", ["Sloth/conversions.c"]),
        Extension("Sloth.frame", ["Sloth/frame.c"]),
        Extension("Sloth.indexer", ["Sloth/indexer.c"]),
        Extension("Sloth.resample", ["Sloth/resample.c"]),
        Extension("Sloth.rolling", ["Sloth/rolling.c"]),
        Extension("Sloth.util", ["Sloth/util.c"]),
    ]

setup(
    name="Sloth",
    version="0.1",
    description="Sloth module",
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    author="Your Name",
    author_email="your.email@example.com",
    url="https://github.com/yourusername/sloth",
    packages=find_packages(),
    ext_modules=get_extensions(),
    include_package_data=True,
    install_requires=[
        "numpy"
    ],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
)

# python setup1.py sdist bdist_wheel