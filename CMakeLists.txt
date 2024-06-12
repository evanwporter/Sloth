cmake_minimum_required(VERSION 3.13)
project(pydataframe)

set(CMAKE_CXX_STANDARD 11)

# Set the path to the pybind11 CMake files
set(pybind11_DIR "C:\\Users\\evanw\\miniconda3\\lib\\site-packages\\pybind11\\share\\cmake\\pybind11")
find_package(pybind11 REQUIRED)

# Use Pybind11 to create the Python module
pybind11_add_module(pydataframe pydataframe.cpp DataFrame.cpp)

# Specify output directory
set_target_properties(pydataframe PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/build"
)
