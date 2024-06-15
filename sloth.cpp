#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/stl.h>

#include <memory>
#include <vector>
#include <string>
#include <sstream>
#include <stdexcept>
#include <numeric>
#include <algorithm>

#include <Eigen/Dense>
#include "lib/robinhood.h"

namespace py = pybind11;

// Using Eigen::RowMajor for easier conversion to NumPy
using MatrixXdRowMajor = Eigen::Matrix<double, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor>;

template <typename T>
struct slice {
    T start;
    T stop;
    int step;

    slice(T start_, T stop_, int step_) : start(start_), stop(stop_), step(step_) {}

    void normalize(Eigen::Index length = 0) {
        if (start < 0) start += length;
        if (stop < 0) stop += length;
        if (step == 0) throw std::invalid_argument("Step cannot be zero");

        if (start < 0) start = 0;
        if (stop > length) stop = length;
    }

    Eigen::Index length() const {
        if (step > 0) {
            return (stop - start + step - 1) / step;
        } else {
            return (start - stop + (-step) - 1) / (-step);
        }
    }

    T get_start() const { return start; }
    T get_stop() const { return stop; }
    int get_step() const { return step; }

    std::string repr() const {
        std::ostringstream oss;
        oss << "slice(" << start << ", " << stop << ", " << step << ")";
        return oss.str();
    }
};

slice<int> combine_slices(const slice<int>& mask, const slice<int>& overlay, Eigen::Index length_mask) {
    int mask_start = mask.start;
    int mask_stop = mask.stop;
    int mask_step = mask.step;

    Eigen::Index length_overlay = (mask_stop - mask_start + (mask_step - 1)) / mask_step;

    int overlay_start = overlay.start;
    int overlay_stop = overlay.stop;
    int overlay_step = overlay.step;

    int start = mask_start + (overlay_start * mask_step);
    int stop = mask_start + (overlay_stop * mask_step);
    int step = mask_step * overlay_step;

    return slice<int>(start, stop, step);
}

// Forward declarations
class DataFrame;
class Series;

class Index_ {
public:
    virtual ~Index_() = default;
};

class ObjectIndex : public Index_ {
public:
    robin_hood::unordered_map<std::string, int> index_;
    std::vector<std::string> keys_;
    std::shared_ptr<slice<int>> mask_;

    ObjectIndex(robin_hood::unordered_map<std::string, int> index, std::vector<std::string> keys)
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

    std::shared_ptr<slice<int>> get_mask() const {
        return mask_;
    }
};

class ColumnIndex : public ObjectIndex {
public:
    using ObjectIndex::ObjectIndex;
};

class Series {
public:
    Eigen::VectorXd values_;
    std::shared_ptr<ObjectIndex> index_;
    std::shared_ptr<slice<int>> mask_;

    // Constructor
    Series(Eigen::VectorXd values, std::shared_ptr<ObjectIndex> index) : 
        values_(std::move(values)), 
        index_(std::move(index)), 
        mask_(std::make_shared<slice<int>>(0, values_.size(), 1)) {}

    // Constructor for a simple 1D array
    Series(py::array_t<double> values, py::array index) {
        // Convert numpy array to Eigen::VectorXd
        auto buf = values.unchecked<1>(); // Use 1D unchecked access for 1D data
        values_.resize(buf.shape(0));
        for (std::ptrdiff_t i = 0; i < buf.shape(0); ++i) {
            values_(i) = buf(i);
        }

        // Build index from python array to std map
        std::vector<std::string> keys = py::cast<std::vector<std::string>>(index);
        robin_hood::unordered_map<std::string, int> index_map;
        for (size_t i = 0; i < keys.size(); ++i) {
            index_map[keys[i]] = i;
        }
        index_ = std::make_shared<ObjectIndex>(std::move(index_map), keys);
    }

    class LocProxy {
    private:
        Series& parent_;

    public:
        LocProxy(Series& parent) : parent_(parent) {}

        double operator[](std::string idx) const {
            auto it = parent_.index_->index_.find(idx);
            if (it == parent_.index_->index_.end()) {
                throw std::out_of_range("Index out of range");
            }
            return parent_.values_(it->second);
        }
    };

    LocProxy loc() {
        return LocProxy(*this);
    }

    class IlocProxy {
    private:
        Series& parent_;

    public:
        IlocProxy(Series& parent) : parent_(parent) {}

        // Integer indexing directly in Series
        double operator[](int idx) const {
            if (idx < 0 || idx >= parent_.values_.size()) {
                throw std::out_of_range("Index out of range");
            }
            return parent_.values_(idx);
        }
    };

    IlocProxy iloc() {
        return IlocProxy(*this);
    }

    // Sum function
    double sum() const {
        return values_.sum();
    }

    // Mean function
    double mean() const {
        return values_.mean();
    }

    // Min function
    double min() const {
        return values_.minCoeff();
    }

    // Max function
    double max() const {
        return values_.maxCoeff();
    }

    // Override the repr function
    std::string repr() const {
        std::ostringstream oss;
        oss << "Series, Length: " << values_.size() << "\nValues:\n";
        for (Eigen::Index i = 0; i < values_.size(); ++i) {
            oss << values_(i) << "\n";
        }
        return oss.str();
    }
};

// Define DataFrame class
class DataFrame : public std::enable_shared_from_this<DataFrame> {
public:
    MatrixXdRowMajor values_;
    std::shared_ptr<ObjectIndex> index_;
    std::shared_ptr<ColumnIndex> columns_;
    std::shared_ptr<slice<int>> mask_;

    // Delete copy constructor and copy assignment operator
    DataFrame(const DataFrame&) = delete;
    DataFrame& operator=(const DataFrame&) = delete;

    // Define move constructor
    DataFrame(DataFrame&& other) noexcept
        : values_(std::move(other.values_)),
          index_(std::move(other.index_)),
          columns_(std::move(other.columns_)),
          mask_(std::move(other.mask_)) {}

    // Define move assignment operator
    DataFrame& operator=(DataFrame&& other) noexcept {
        if (this != &other) {
            values_ = std::move(other.values_);
            index_ = std::move(other.index_);
            columns_ = std::move(other.columns_);
            mask_ = std::move(other.mask_);
        }
        return *this;
    }

    // Constructor for C++ types
    DataFrame(MatrixXdRowMajor values, std::shared_ptr<ObjectIndex> index, std::shared_ptr<ColumnIndex> columns, std::shared_ptr<slice<int>> mask)
        : values_(std::move(values)),
          index_(std::move(index)),
          columns_(std::move(columns)),
          mask_(std::move(mask)) {}

    // Constructor for Python Lists (list[list[float]])
    DataFrame(py::list values, py::list index, py::list columns)
        : mask_(std::make_shared<slice<int>>(0, static_cast<Eigen::Index>(values.size()), 1)) {
        // Convert list of list to Eigen::MatrixXd
        Eigen::Index rows = static_cast<Eigen::Index>(values.size());
        Eigen::Index cols = static_cast<Eigen::Index>(py::len(values[0]));
        values_ = MatrixXdRowMajor(rows, cols);

        for (Eigen::Index i = 0; i < rows; ++i) {
            auto row = py::cast<py::list>(values[i]);
            for (Eigen::Index j = 0; j < cols; ++j) {
                values_(i, j) = py::cast<double>(row[j]);
            }
        }

        robin_hood::unordered_map<std::string, int> index_map;
        std::vector<std::string> index_keys;
        for (py::ssize_t i = 0; i < index.size(); ++i) {
            std::string key = py::cast<std::string>(index[i]);
            index_map[key] = static_cast<int>(i);
            index_keys.push_back(key);
        }

        robin_hood::unordered_map<std::string, int> column_map;
        std::vector<std::string> column_keys;
        for (py::ssize_t i = 0; i < columns.size(); ++i) {
            std::string key = py::cast<std::string>(columns[i]);
            column_map[key] = static_cast<int>(i);
            column_keys.push_back(key);
        }

        index_ = std::make_shared<ObjectIndex>(std::move(index_map), std::move(index_keys));
        columns_ = std::make_shared<ColumnIndex>(std::move(column_map), std::move(column_keys));
    }

    // Constructor for Numpy Array
    DataFrame(py::array_t<double> values, py::array index, py::array columns)
        : mask_(std::make_shared<slice<int>>(0, static_cast<Eigen::Index>(values.shape(0)), 1)) {
        auto buf = values.unchecked<2>(); // Use py::array_t::unchecked<2> for direct access

        Eigen::Index rows = static_cast<Eigen::Index>(buf.shape(0));
        Eigen::Index cols = static_cast<Eigen::Index>(buf.shape(1));

        values_ = MatrixXdRowMajor(rows, cols);

        // Map the numpy array to the Eigen matrix
        for (Eigen::Index i = 0; i < rows; ++i) {
            for (Eigen::Index j = 0; j < cols; ++j) {
                values_(i, j) = buf(i, j);
            }
        }

        robin_hood::unordered_map<std::string, int> index_map;
        std::vector<std::string> index_keys;

        auto index_array = index.cast<py::list>();
        auto columns_array = columns.cast<py::list>();

        for (py::ssize_t i = 0; i < index_array.size(); ++i) {
            std::string key = py::cast<std::string>(index_array[i]);
            index_map[key] = static_cast<int>(i);
            index_keys.push_back(key);
        }

        robin_hood::unordered_map<std::string, int> column_map;
        std::vector<std::string> column_keys;
        for (py::ssize_t i = 0; i < columns_array.size(); ++i) {
            std::string key = py::cast<std::string>(columns_array[i]);
            column_map[key] = static_cast<int>(i);
            column_keys.push_back(key);
        }

        index_ = std::make_shared<ObjectIndex>(std::move(index_map), std::move(index_keys));
        columns_ = std::make_shared<ColumnIndex>(std::move(column_map), std::move(column_keys));
    }

    // Constructor for Index Objects
    DataFrame(MatrixXdRowMajor values, ObjectIndex index, ColumnIndex columns)
        : DataFrame(std::move(values),
                    std::make_shared<ObjectIndex>(std::move(index)),
                    std::make_shared<ColumnIndex>(std::move(columns)),
                    std::make_shared<slice<int>>(0, values_.rows(), 1)) {}

    // Sum function using Eigen's colwise and rowwise sum
    std::vector<double> sum(int axis) const {
        std::vector<double> result;
        if (axis == 0) {
            // Sum along rows
            Eigen::VectorXd rowSum = values_.rowwise().sum();
            result.assign(rowSum.data(), rowSum.data() + rowSum.size());
        } else if (axis == 1) {
            // Sum along columns
            Eigen::VectorXd colSum = values_.colwise().sum();
            result.assign(colSum.data(), colSum.data() + colSum.size());
        } else {
            throw std::invalid_argument("Invalid axis value. Use 0 for rows and 1 for columns.");
        }
        return result;
    }

    // Mean function using Eigen's colwise and rowwise mean
    std::vector<double> mean(int axis) const {
        std::vector<double> result;
        if (axis == 0) {
            // Mean along rows
            Eigen::VectorXd rowMean = values_.rowwise().mean();
            result.assign(rowMean.data(), rowMean.data() + rowMean.size());
        } else if (axis == 1) {
            // Mean along columns
            Eigen::VectorXd colMean = values_.colwise().mean();
            result.assign(colMean.data(), colMean.data() + colMean.size());
        } else {
            throw std::invalid_argument("Invalid axis value. Use 0 for rows and 1 for columns.");
        }
        return result;
    }

    // Min function using Eigen's colwise and rowwise min
    std::vector<double> min(int axis) const {
        std::vector<double> result;
        if (axis == 0) {
            // Min along rows
            Eigen::VectorXd rowMin = values_.rowwise().minCoeff();
            result.assign(rowMin.data(), rowMin.data() + rowMin.size());
        } else if (axis == 1) {
            // Min along columns
            Eigen::VectorXd colMin = values_.colwise().minCoeff();
            result.assign(colMin.data(), colMin.data() + colMin.size());
        } else {
            throw std::invalid_argument("Invalid axis value. Use 0 for rows and 1 for columns.");
        }
        return result;
    }

    // Max function using Eigen's colwise and rowwise max
    std::vector<double> max(int axis) const {
        std::vector<double> result;
        if (axis == 0) {
            // Max along rows
            Eigen::VectorXd rowMax = values_.rowwise().maxCoeff();
            result.assign(rowMax.data(), rowMax.data() + rowMax.size());
        } else if (axis == 1) {
            // Max along columns
            Eigen::VectorXd colMax = values_.colwise().maxCoeff();
            result.assign(colMax.data(), colMax.data() + colMax.size());
        } else {
            throw std::invalid_argument("Invalid axis value. Use 0 for rows and 1 for columns.");
        }
        return result;
    }

    std::string repr() const {
        std::ostringstream oss;
        oss << "Columns: " << columns_->keys().size() << ", Rows: " << values_.rows() << "\nValues:\n";
        for (Eigen::Index i = 0; i < values_.rows(); ++i) {
            for (Eigen::Index j = 0; j < values_.cols(); ++j) {
                oss << values_(i, j) << " ";
            }
            oss << "\n";
        }
        return oss.str();
    }

    std::pair<Eigen::Index, Eigen::Index> shape() const {
        return {values_.rows(), values_.cols()};
    }

    py::array_t<double> get_col(const std::string& col) const {
        if (columns_->index_.find(col) == columns_->index_.end()) {
            throw std::invalid_argument("Column name not found");
        }

        int col_index = columns_->index_.at(col);

        py::array_t<double> column(mask_->length());
        auto buf = column.request();

        double *ptr = static_cast<double *>(buf.ptr);
        
        for (Eigen::Index i = mask_->start, idx = 0; i < mask_->stop; i += mask_->step, ++idx) {
            ptr[idx] = values_(i, col_index);
        }

        return column;
    }

    py::array_t<double> values() const {
        // Calculate shape of values based on mask
        Eigen::Index num_rows = mask_->length();
        Eigen::Index num_cols = values_.cols();  

        // Create a 2D NumPy array with the appropriate shape
        py::array_t<double> result({num_rows, num_cols});
        auto buf = result.request();
        double* ptr = static_cast<double*>(buf.ptr);

        // Fill the NumPy array with values from the masked DataFrame
        for (Eigen::Index i = 0, mask_row = mask_->start; i < num_rows; ++i, mask_row += mask_->step) {
            Eigen::VectorXd row = values_.row(mask_row);
            std::copy(row.data(), row.data() + num_cols, ptr + i * num_cols);
        }

        return result;
    }

    std::shared_ptr<DataFrame> fast_init(std::shared_ptr<slice<int>> mask) const {
        return std::make_shared<DataFrame>(values_, index_->fast_init(mask), columns_, mask);
    }

    std::shared_ptr<slice<int>> get_mask() const {
        return mask_;
    }

    class LocProxy {
    public:
        DataFrame* frame_;

        LocProxy(DataFrame* frame)
            : frame_(frame) {}

        py::array_t<double> get(const std::string& arg) const {
            auto& values_ = frame_->values_;
            auto index_ = frame_->index_;

            // Check if the key exists in the index
            if (index_->index_.find(arg) == index_->index_.end()) {
                throw std::out_of_range("Key '" + arg + "' not found in the DataFrame index.");
            }

            Eigen::Index row = combine_slices(*frame_->mask_, slice<int>(index_->index_.at(arg), index_->index_.at(arg) + 1, 1), values_.rows()).start;
            return py::array_t<double>(values_.cols(), values_.row(row).data());
        }

        std::shared_ptr<DataFrame> get(const slice<std::string>& arg) const {
            auto index_ = frame_->index_;
            auto start = index_->index_.at(arg.start);
            auto stop = index_->index_.at(arg.stop);
            auto new_arg = slice<int>(start, stop, arg.step);
            auto combined_slice = combine_slices(*frame_->mask_, new_arg, frame_->values_.rows());
            return frame_->fast_init(std::make_shared<slice<int>>(combined_slice));
        }

        std::shared_ptr<DataFrame> get(const py::slice& pySlice) const {
            // Extract attributes from py::slice
            py::object py_start = pySlice.attr("start");
            py::object py_stop = pySlice.attr("stop");
            py::object py_step = pySlice.attr("step");

            // Parse attributes to std::string and int
            std::string start = py::isinstance<py::none>(py_start) ? "" : py::cast<std::string>(py_start);
            std::string stop = py::isinstance<py::none>(py_stop) ? "" : py::cast<std::string>(py_stop);
            int step = py::isinstance<py::none>(py_step) ? 1 : py::cast<int>(py_step);

            // Create slice<std::string>
            slice<std::string> arg(start, stop, step);
            return get(arg);
        }
    };

    class IlocProxy {
    public:
        DataFrame* frame_;

        IlocProxy(DataFrame* frame)
            : frame_(frame) {}

        py::array_t<double> get(int arg) const {
            auto& values_ = frame_->values_;
            arg = combine_slices(*frame_->mask_, slice<int>(arg, arg + 1, 1), values_.rows()).start;
            return py::array_t<double>(values_.cols(), values_.row(arg).data());
        }

        std::shared_ptr<DataFrame> get(const slice<int>& arg) const {
            auto& values_ = frame_->values_;
            auto combined_slice = combine_slices(*frame_->mask_, arg, values_.rows());
            return frame_->fast_init(std::make_shared<slice<int>>(combined_slice));
        }

        std::shared_ptr<DataFrame> get(const py::slice& pySlice) const {
            py::ssize_t start, stop, step, slicelength;
            if (!pySlice.compute(frame_->values_.rows(), &start, &stop, &step, &slicelength)) {
                throw py::error_already_set();
            }

            slice<int> arg(static_cast<int>(start), static_cast<int>(stop), static_cast<int>(step));
            return get(arg);
        }
    };

    // Property access for loc and iloc
    LocProxy loc() {
        return LocProxy(this);
    }

    IlocProxy iloc() {
        return IlocProxy(this);
    }
};

PYBIND11_MODULE(sloth, m) {
    py::class_<slice<int>>(m, "slice")
        .def(py::init<int, int, int>())
        .def("normalize", &slice<int>::normalize)
        .def("length", &slice<int>::length)
        .def_property_readonly("start", &slice<int>::get_start)
        .def_property_readonly("stop", &slice<int>::get_stop)
        .def_property_readonly("step", &slice<int>::get_step)
        .def("__repr__", &slice<int>::repr);

    py::class_<Index_, std::shared_ptr<Index_>>(m, "Index_");

    py::class_<ObjectIndex, Index_, std::shared_ptr<ObjectIndex>>(m, "ObjectIndex")
        .def(py::init<robin_hood::unordered_map<std::string, int>, std::vector<std::string>>())
        .def("keys", &ObjectIndex::keys)
        .def("get_mask", &ObjectIndex::get_mask);

    py::class_<ColumnIndex, ObjectIndex, std::shared_ptr<ColumnIndex>>(m, "ColumnIndex")
        .def(py::init<robin_hood::unordered_map<std::string, int>, std::vector<std::string>>());

    py::class_<DataFrame, std::shared_ptr<DataFrame>>(m, "DataFrame")
        .def(py::init<MatrixXdRowMajor, ObjectIndex, ColumnIndex>())
        .def(py::init<py::list, py::list, py::list>()) // Updated to use py::list
        .def(py::init<py::array_t<double>, py::array, py::array>()) // Updated for py::array
        .def("repr", &DataFrame::repr)
        .def_property_readonly("shape", &DataFrame::shape)
        .def("__getitem__", &DataFrame::get_col)
        .def_property_readonly("values", &DataFrame::values)
        .def_property_readonly("mask", &DataFrame::get_mask)
        .def_property_readonly("loc", &DataFrame::loc)
        .def_property_readonly("iloc", &DataFrame::iloc)
        .def("sum", &DataFrame::sum)
        .def("mean", &DataFrame::mean)
        .def("min", &DataFrame::min)
        .def("max", &DataFrame::max);

    // Create a Python submodule to nest the IlocProxy and LocProxy classes
    py::class_<DataFrame::IlocProxy>(m, "DataFrameIlocProxy")
        .def(py::init<DataFrame*>())
        .def("__getitem__", (py::array_t<double> (DataFrame::IlocProxy::*)(int) const) &DataFrame::IlocProxy::get)
        .def("__getitem__", (std::shared_ptr<DataFrame> (DataFrame::IlocProxy::*)(const slice<int>&) const) &DataFrame::IlocProxy::get)
        .def("__getitem__", (std::shared_ptr<DataFrame> (DataFrame::IlocProxy::*)(const py::slice&) const) &DataFrame::IlocProxy::get);

    py::class_<DataFrame::LocProxy>(m, "DataFrameLocProxy")
        .def(py::init<DataFrame*>())
        .def("__getitem__", (py::array_t<double> (DataFrame::LocProxy::*)(const std::string&) const) &DataFrame::LocProxy::get)
        .def("__getitem__", (std::shared_ptr<DataFrame> (DataFrame::LocProxy::*)(const slice<std::string>&) const) &DataFrame::LocProxy::get)
        .def("__getitem__", (std::shared_ptr<DataFrame> (DataFrame::LocProxy::*)(const py::slice&) const) &DataFrame::LocProxy::get);

    py::class_<Series, std::shared_ptr<Series>>(m, "Series")
        .def(py::init<Eigen::VectorXd, std::shared_ptr<ObjectIndex>>())
        .def(py::init<py::array_t<double>, py::array>())
        .def("sum", &Series::sum)
        .def("mean", &Series::mean)
        .def("min", &Series::min)
        .def("max", &Series::max)
        .def("__repr__", &Series::repr)
        .def_property_readonly("iloc", &Series::iloc);

    py::class_<Series::IlocProxy>(m, "SeriesIlocProxy")
        .def("__getitem__", &Series::IlocProxy::operator[], py::is_operator());
}
