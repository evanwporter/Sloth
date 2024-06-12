#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <memory>
#include <vector>
#include <unordered_map>
#include <string>
#include <sstream>
#include <stdexcept>

namespace py = pybind11;

template <typename T>
struct slice {
    T start;
    T stop;
    int step;

    slice(T start_, T stop_, int step_) : start(start_), stop(stop_), step(step_) {
        normalize();
    }

    void normalize(int length = 0) {
        if (start < 0) start += length;
        if (stop < 0) stop += length;
        if (step == 0) throw std::invalid_argument("Step cannot be zero");

        if (start < 0) start = 0;
        if (stop > length) stop = length;
    }

    int length() const {
        if (step > 0) {
            return (stop - start + step - 1) / step;
        } else {
            return (start - stop + (-step) - 1) / (-step);
        }
    }
};

slice<int> combine_slices(const slice<int>& mask, const slice<int>& overlay, int length_mask) {
    int mask_start = mask.start;
    int mask_stop = mask.stop;
    int mask_step = mask.step;

    int length_overlay = (mask_stop - mask_start + (mask_step - 1)) / mask_step;

    int overlay_start = overlay.start;
    int overlay_stop = overlay.stop;
    int overlay_step = overlay.step;

    int start = mask_start + (overlay_start * mask_step);
    int stop = mask_start + (overlay_stop * mask_step);
    int step = mask_step * overlay_step;

    return slice<int>(start, stop, step);
}

class DataFrame;  // Forward declaration

class Index_ {
public:
    virtual ~Index_() = default;
};

class ObjectIndex : public Index_ {
public:
    std::unordered_map<std::string, int> index_;
    std::vector<std::string> keys_;
    std::shared_ptr<slice<int>> mask_;

    ObjectIndex(std::unordered_map<std::string, int> index, std::vector<std::string> keys)
        : index_(index), keys_(keys), mask_(std::make_shared<slice<int>>(0, static_cast<int>(keys.size()), 1)) {}

    std::shared_ptr<ObjectIndex> fast_init(std::shared_ptr<slice<int>> mask) {
        auto new_index = std::make_shared<ObjectIndex>(*this);
        new_index->mask_ = mask;
        return new_index;
    }

    std::vector<std::string> keys() {
        std::vector<std::string> result;
        for (int i = mask_->start; i < mask_->stop; i += mask_->step) {
            result.push_back(keys_[i]);
        }
        return result;
    }
};

class ColumnIndex : public ObjectIndex {
public:
    using ObjectIndex::ObjectIndex;
};

class DataFrame : public std::enable_shared_from_this<DataFrame> {
public:
    std::shared_ptr<std::vector<std::vector<double>>> values_;
    std::shared_ptr<ObjectIndex> index_;
    std::shared_ptr<ColumnIndex> columns_;
    std::shared_ptr<slice<int>> mask_;

    DataFrame(std::vector<std::vector<double>> values, ObjectIndex index, ColumnIndex columns)
        : values_(std::make_shared<std::vector<std::vector<double>>>(values)),
          index_(std::make_shared<ObjectIndex>(index)),
          columns_(std::make_shared<ColumnIndex>(columns)),
          mask_(std::make_shared<slice<int>>(0, static_cast<int>(values.size()), 1)) {}

    std::string repr() {
        std::ostringstream oss;
        oss << "Columns: " << columns_->keys().size() << ", Rows: " << values_->size() << "\nValues:\n";
        for (const auto& row : *values_) {
            for (const auto& val : row) {
                oss << val << " ";
            }
            oss << "\n";
        }
        return oss.str();
    }

    std::pair<int, int> shape() {
        return {static_cast<int>(values_->size()), static_cast<int>((*values_)[0].size())};
    }

    std::vector<double> get_col(const std::string& col) {
        // Check if the column name exists in the column index
        if (columns_->index_.find(col) == columns_->index_.end()) {
            throw std::invalid_argument("Column name not found");
        }
        
        // Get the column index
        int col_index = columns_->index_.at(col);
        
        // Retrieve the column values
        std::vector<double> column;
        for (int i = mask_->start; i < mask_->stop; i += mask_->step) {
            column.push_back((*values_)[i][col_index]);
        }
        
        return column;
    }

    std::vector<std::vector<double>> values() {
        std::vector<std::vector<double>> result;
        for (int i = mask_->start; i < mask_->stop; i += mask_->step) {
            result.push_back((*values_)[i]);
        }
        return result;
    }

    std::shared_ptr<DataFrame> fast_init(std::shared_ptr<slice<int>> mask) {
        auto frame = std::make_shared<DataFrame>(*this);
        frame->index_ = index_->fast_init(mask);
        frame->mask_ = mask;
        return frame;
    }
};

class IntegerLocation {
public:
    std::shared_ptr<DataFrame> frame_;

    IntegerLocation(std::shared_ptr<DataFrame> frame)
        : frame_(frame) {}

    std::vector<double> get(int arg) {
        auto values_ = frame_->values_;
        arg = combine_slices(*frame_->mask_, slice<int>(arg, arg + 1, 1), static_cast<int>(values_->size())).start;
        return (*values_)[arg];
    }

    std::shared_ptr<DataFrame> get(const slice<int>& arg) {
        auto values_ = frame_->values_;
        auto combined_slice = combine_slices(*frame_->mask_, arg, static_cast<int>(values_->size()));
        return frame_->fast_init(std::make_shared<slice<int>>(combined_slice));
    }
};

class Location {
public:
    std::shared_ptr<DataFrame> frame_;

    Location(std::shared_ptr<DataFrame> frame)
        : frame_(frame) {}

    std::vector<double> get(const std::string& arg) {
        auto values_ = frame_->values_;
        auto index_ = frame_->index_;
        int row = combine_slices(*frame_->mask_, slice<int>(index_->index_.at(arg), index_->index_.at(arg) + 1, 1), static_cast<int>(values_->size())).start;
        return (*values_)[row];
    }

    std::shared_ptr<DataFrame> get(const slice<std::string>& arg) {
        auto index_ = frame_->index_;
        auto start = index_->index_.at(arg.start);
        auto stop = index_->index_.at(arg.stop);
        auto new_arg = slice<int>(start, stop, arg.step);
        auto combined_slice = combine_slices(*frame_->mask_, new_arg, static_cast<int>(frame_->values_->size()));
        return frame_->fast_init(std::make_shared<slice<int>>(combined_slice));
    }
};

PYBIND11_MODULE(dataframe, m) {
    py::class_<slice<int>>(m, "slice")
        .def(py::init<int, int, int>())
        .def("normalize", &slice<int>::normalize)
        .def("length", &slice<int>::length);

    py::class_<Index_, std::shared_ptr<Index_>>(m, "Index_");

    py::class_<ObjectIndex, Index_, std::shared_ptr<ObjectIndex>>(m, "ObjectIndex")
        .def(py::init<std::unordered_map<std::string, int>, std::vector<std::string>>())
        .def("keys", &ObjectIndex::keys);

    py::class_<ColumnIndex, ObjectIndex, std::shared_ptr<ColumnIndex>>(m, "ColumnIndex")
        .def(py::init<std::unordered_map<std::string, int>, std::vector<std::string>>());

    py::class_<DataFrame, std::shared_ptr<DataFrame>>(m, "DataFrame")
        .def(py::init<std::vector<std::vector<double>>, ObjectIndex, ColumnIndex>())
        .def("repr", &DataFrame::repr)
        .def("shape", &DataFrame::shape)
        .def("get_col", &DataFrame::get_col)
        .def("values", &DataFrame::values)
        .def("fast_init", &DataFrame::fast_init);

    py::class_<IntegerLocation>(m, "IntegerLocation")
        .def(py::init<std::shared_ptr<DataFrame>>())
        .def("get", (std::vector<double> (IntegerLocation::*)(int)) &IntegerLocation::get)
        .def("get", (std::shared_ptr<DataFrame> (IntegerLocation::*)(const slice<int>&)) &IntegerLocation::get);

    py::class_<Location>(m, "Location")
        .def(py::init<std::shared_ptr<DataFrame>>())
        .def("get", (std::vector<double> (Location::*)(const std::string&)) &Location::get)
        .def("get", (std::shared_ptr<DataFrame> (Location::*)(const slice<std::string>&)) &Location::get);
}