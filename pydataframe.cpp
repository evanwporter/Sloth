#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>  // Add this header to handle std::vector conversions
#include "DataFrame.h"

namespace py = pybind11;

py::array_t<double> to_numpy(const DataFrame& df) {
    auto values = df.getValues();
    size_t rows = df.rows();
    size_t cols = df.cols();
    py::array_t<double> array({rows, cols});
    auto buf = array.request();
    double* ptr = static_cast<double*>(buf.ptr);
    for (size_t i = 0; i < rows; ++i) {
        for (size_t j = 0; j < cols; ++j) {
            ptr[i * cols + j] = values[i][j];
        }
    }
    return array;
}

PYBIND11_MODULE(pydataframe, m) {
    py::class_<DataFrame>(m, "DataFrame")
        .def(py::init<const std::vector<std::vector<double>>&>())
        .def("get_values", &DataFrame::getValues)
        .def("rows", &DataFrame::rows)
        .def("cols", &DataFrame::cols)
        .def("to_numpy", &to_numpy);
}
