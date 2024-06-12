#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include "dataframe.h"

namespace py = pybind11;

PYBIND11_MODULE(dataframe, m) {
    // Mask class
    py::class_<Mask>(m, "Mask")
        .def(py::init<int, int, int>(), py::arg("start") = 0, py::arg("stop") = 0, py::arg("step") = 1)
        .def_readwrite("start", &Mask::start)
        .def_readwrite("stop", &Mask::stop)
        .def_readwrite("step", &Mask::step);

    // ObjectIndex class
    py::class_<ObjectIndex>(m, "ObjectIndex")
        .def(py::init<const std::vector<std::string>&, DataFrame*>(), py::arg("keys"), py::arg("df") = nullptr)
        .def("get_index", &ObjectIndex::get_index)
        .def("keys", &ObjectIndex::keys)
        .def("index_map", &ObjectIndex::index_map)
        .def("repr", &ObjectIndex::repr)
        .def("__repr__", &ObjectIndex::repr);

    // IntegerLocation class
    py::class_<IntegerLocation>(m, "IntegerLocation")
        .def("__getitem__", &IntegerLocation::get);

    // DataFrame class
    py::class_<DataFrame>(m, "DataFrame")
        .def(py::init<const std::vector<std::vector<double>>&, const std::vector<std::string>&, const std::vector<std::string>&>(),
             py::arg("values"), py::arg("row_keys"), py::arg("column_keys"))
        .def("values", &DataFrame::values)
        .def("get_row", &DataFrame::get_row)
        .def("get_column", &DataFrame::get_column)
        .def("set_mask", &DataFrame::set_mask)
        .def("shape", &DataFrame::shape)
        .def("index", &DataFrame::index, py::return_value_policy::reference)
        .def("columns", &DataFrame::columns, py::return_value_policy::reference)
        .def("repr", &DataFrame::repr)
        .def_readonly("iloc", &DataFrame::iloc)
        .def("__repr__", &DataFrame::repr);
}
