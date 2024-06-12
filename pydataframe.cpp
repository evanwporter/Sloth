#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>
#include "dataframe.h"
#include "index.h"
#include "Slice.h"

namespace py = pybind11;

py::array_t<double> dataframe_to_numpy(const DataFrame& df) {
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
        .def("to_numpy", &dataframe_to_numpy)
        .def("sum", &DataFrame::sum, py::arg("axis") = 0); // Bind the sum method

    py::class_<slice>(m, "slice")
        .def(py::init<int, int, int>(), py::arg("start"), py::arg("stop"), py::arg("step"))
        .def_property("start", &slice::get_start, &slice::set_start)
        .def_property("stop", &slice::get_stop, &slice::set_stop)
        .def_property("step", &slice::get_step, &slice::set_step);
    
    py::class_<ObjectIndex>(m, "ObjectIndex")
        .def(py::init<const std::vector<std::string>&>())
        .def("keys", &ObjectIndex::keys)
        .def("get_item", &ObjectIndex::get_item)
        .def("__contains__", &ObjectIndex::contains)
        .def("__repr__", &ObjectIndex::repr);

    py::class_<RangeIndex>(m, "RangeIndex")
        .def(py::init<int, int, int>())
        .def("keys", &RangeIndex::keys)
        .def("get_item", &RangeIndex::get_item)
        .def("size", &RangeIndex::size);
}
