#ifndef DATAFRAME_H
#define DATAFRAME_H

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <memory>
#include <vector>
#include <unordered_map>
#include <stdexcept>
#include <string>
#include <sstream>

namespace py = pybind11;

// Slice template class
template <typename T>
class Slice {
public:
    T start;
    T stop;
    int step;

    Slice(T start = 0, T stop = 0, int step = 1)
        : start(start), stop(stop), step(step) {}

    void normalize(int length) {
        if (start < 0) start += length;
        if (stop < 0) stop += length;
        if (step == 0) throw std::invalid_argument("Step cannot be zero");
        if (start < 0) start = 0;
        if (stop > length) stop = length;
    }

    int length() const {
        return step > 0 ? (stop - start + step - 1) / step : (start - stop + (-step) - 1) / (-step);
    }
};

// Index_ class
class Index_ {
    // Base class for indexes
};

// ObjectIndex class
class ObjectIndex : public Index_ {
public:
    std::unordered_map<std::string, int> index_;
    std::vector<std::string> keys_;
    std::shared_ptr<Slice<int>> mask_;

    ObjectIndex() : mask_(std::make_shared<Slice<int>>()) {}

    std::shared_ptr<ObjectIndex> fast_init(std::shared_ptr<Slice<int>> mask) const {
        auto new_index = std::make_shared<ObjectIndex>(*this);
        new_index->mask_ = mask;
        return new_index;
    }

    std::vector<std::string> keys() const {
        std::vector<std::string> result;
        for (int i = mask_->start; i < mask_->stop; i += mask_->step) {
            result.push_back(keys_[i]);
        }
        return result;
    }
};

// ColumnIndex class
class ColumnIndex : public ObjectIndex {
    // Same as ObjectIndex but for columns, no fast_init method
};

// DataFrame class
class DataFrame {
public:
    std::shared_ptr<std::vector<std::vector<double>>> values_;
    std::shared_ptr<ObjectIndex> index_;
    std::shared_ptr<ColumnIndex> columns_;
    std::shared_ptr<Slice<int>> mask_;
    std::shared_ptr<class IntegerLocation> iloc;
    std::shared_ptr<class Location> loc;

    DataFrame()
        : values_(std::make_shared<std::vector<std::vector<double>>>()),
          index_(std::make_shared<ObjectIndex>()),
          columns_(std::make_shared<ColumnIndex>()),
          mask_(std::make_shared<Slice<int>>()),
          iloc(std::make_shared<IntegerLocation>(this)),
          loc(std::make_shared<Location>(this)) {}

    std::string repr() const {
        std::ostringstream repr;
        repr << "DataFrame\nColumns: ";
        for (const auto &key : columns_->keys()) {
            repr << key << " ";
        }
        repr << "\nRows: " << index_->keys().size() << "\nValues:\n";
        for (int i = mask_->start; i < mask_->stop; i += mask_->step) {
            for (const auto &val : values_->at(i)) {
                repr << val << " ";
            }
            repr << "\n";
        }
        return repr.str();
    }

    std::pair<int, int> shape() const {
        return {static_cast<int>(values_->size()), static_cast<int>(values_->at(0).size())};
    }

    std::vector<double> get_col(const std::string &col) const {
        int col_index = columns_->index_.at(col);
        std::vector<double> column;
        for (int i = mask_->start; i < mask_->stop; i += mask_->step) {
            column.push_back(values_->at(i)[col_index]);
        }
        return column;
    }

    std::vector<std::vector<double>> values() const {
        std::vector<std::vector<double>> result;
        for (int i = mask_->start; i < mask_->stop; i += mask_->step) {
            result.push_back(values_->at(i));
        }
        return result;
    }

    std::shared_ptr<DataFrame> fast_init(std::shared_ptr<Slice<int>> mask) const {
        auto frame = std::make_shared<DataFrame>(*this);
        frame->index_ = index_->fast_init(mask);
        frame->mask_ = mask;
        return frame;
    }
};

// IntegerLocation class
class IntegerLocation {
public:
    DataFrame* frame;
    std::shared_ptr<std::vector<std::vector<double>>> values_;
    std::shared_ptr<ObjectIndex> index_;

    IntegerLocation(DataFrame* frame)
        : frame(frame), values_(frame->values_), index_(frame->index_) {}

    std::vector<double> get(int arg) {
        arg = calculate_index(frame->mask_, arg);
        return values_->at(arg);
    }

    std::shared_ptr<DataFrame> get(Slice<int> arg) {
        arg.normalize(index_->keys().size());
        auto combined_slice = combine_slices(*frame->mask_, arg, index_->keys().size());
        return frame->fast_init(std::make_shared<Slice<int>>(combined_slice));
    }

private:
    int calculate_index(std::shared_ptr<Slice<int>> mask, int arg) const {
        arg = mask->start + (arg * mask->step);
        return arg;
    }

    Slice<int> combine_slices(const Slice<int> &mask, const Slice<int> &overlay, int length_mask) const {
        Slice<int> normalized_mask = mask;
        normalized_mask.normalize(length_mask);
        int length_overlay = (normalized_mask.stop - normalized_mask.start + (normalized_mask.step - 1)) / normalized_mask.step;

        Slice<int> normalized_overlay = overlay;
        normalized_overlay.normalize(length_overlay);

        int start = normalized_mask.start + (normalized_overlay.start * normalized_mask.step);
        int stop = normalized_mask.start + (normalized_overlay.stop * normalized_mask.step);
        int step = normalized_mask.step * normalized_overlay.step;

        return Slice<int>(start, stop, step);
    }
};

// Location class
class Location {
public:
    DataFrame* frame;
    std::shared_ptr<std::vector<std::vector<double>>> values_;
    std::shared_ptr<ObjectIndex> index_;

    Location(DataFrame* frame)
        : frame(frame), values_(frame->values_), index_(frame->index_) {}

    std::vector<double> get(const std::string &arg) {
        int arg_index = calculate_index(frame->mask_, index_->index_.at(arg));
        return values_->at(arg_index);
    }

    std::shared_ptr<DataFrame> get(const Slice<std::string> &arg) {
        Slice<int> new_arg(index_->index_.at(arg.start), index_->index_.at(arg.stop), arg.step);
        new_arg.normalize(index_->keys().size());
        auto combined_slice = combine_slices(*frame->mask_, new_arg, index_->keys().size());
        return frame->fast_init(std::make_shared<Slice<int>>(combined_slice));
    }

private:
    int calculate_index(std::shared_ptr<Slice<int>> mask, int arg) const {
        arg = mask->start + (arg * mask->step);
        return arg;
    }

    Slice<int> combine_slices(const Slice<int> &mask, const Slice<int> &overlay, int length_mask) const {
        Slice<int> normalized_mask = mask;
        normalized_mask.normalize(length_mask);
        int length_overlay = (normalized_mask.stop - normalized_mask.start + (normalized_mask.step - 1)) / normalized_mask.step;

        Slice<int> normalized_overlay = overlay;
        normalized_overlay.normalize(length_overlay);

        int start = normalized_mask.start + (normalized_overlay.start * normalized_mask.step);
        int stop = normalized_mask.start + (normalized_overlay.stop * normalized_mask.step);
        int step = normalized_mask.step * normalized_overlay.step;

        return Slice<int>(start, stop, step);
    }
};

// Pybind11 bindings
PYBIND11_MODULE(dataframe, m) {
    py::class_<Slice<int>>(m, "Slice")
        .def(py::init<int, int, int>(), py::arg("start") = 0, py::arg("stop") = 0, py::arg("step") = 1)
        .def_readwrite("start", &Slice<int>::start)
        .def_readwrite("stop", &Slice<int>::stop)
        .def_readwrite("step", &Slice<int>::step)
        .def("normalize", &Slice<int>::normalize)
        .def("length", &Slice<int>::length);

    py::class_<Index_>(m, "Index_");

    py::class_<ObjectIndex, Index_>(m, "ObjectIndex")
        .def(py::init<>())
        .def_readwrite("index_", &ObjectIndex::index_)
        .def_readwrite("keys_", &ObjectIndex::keys_)
        .def("fast_init", &ObjectIndex::fast_init)
        .def("keys", &ObjectIndex::keys);

    py::class_<ColumnIndex, ObjectIndex>(m, "ColumnIndex");

    py::class_<DataFrame>(m, "DataFrame")
        .def(py::init<>())
        .def_readwrite("values_", &DataFrame::values_)
        .def_readwrite("index_", &DataFrame::index_)
        .def_readwrite("columns_", &DataFrame::columns_)
        .def_readwrite("mask_", &DataFrame::mask_)
        .def_readwrite("iloc", &DataFrame::iloc)
        .def_readwrite("loc", &DataFrame::loc)
        .def("repr", &DataFrame::repr)
        .def("shape", &DataFrame::shape)
        .def("get_col", &DataFrame::get_col)
        .def("values", &DataFrame::values)
        .def("fast_init", &DataFrame::fast_init);

    py::class_<IntegerLocation>(m, "IntegerLocation")
        .def(py::init<DataFrame*>())
        .def("get", py::overload_cast<int>(&IntegerLocation::get))
        .def("get", py::overload_cast<Slice<int>>(&IntegerLocation::get));

    py::class_<Location>(m, "Location")
        .def(py::init<DataFrame*>())
        .def("get", py::overload_cast<const std::string&>(&Location::get))
        .def("get", py::overload_cast<const Slice<std::string>&>(&Location::get));
}

#endif // DATAFRAME_H
