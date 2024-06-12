#ifndef DATAFRAME_H
#define DATAFRAME_H

#include <vector>
#include <stdexcept>
#include <numeric>

#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>


class DataFrame {
public:
    DataFrame(const std::vector<std::vector<double>>& values)
        : values_(values) {}

    std::vector<std::vector<double>> getValues() const {
        return values_;
    }

    size_t rows() const {
        return values_.size();
    }

    size_t cols() const {
        return values_.empty() ? 0 : values_[0].size();
    }

    pybind11::array_t<double> sum(int axis = 0) const;


private:
    std::vector<std::vector<double>> values_;
};

pybind11::array_t<double> DataFrame::sum(int axis) const {
    if (axis == 0) {
        // Sum columns
        std::vector<double> column_sums(cols(), 0.0);
        for (size_t col = 0; col < cols(); ++col) {
            for (size_t row = 0; row < rows(); ++row) {
                column_sums[col] += values_[row][col];
            }
        }
        // Return as a NumPy array
        return pybind11::array(column_sums.size(), column_sums.data());
    } else if (axis == 1) {
        // Sum rows
        std::vector<double> row_sums(rows(), 0.0);
        for (size_t row = 0; row < rows(); ++row) {
            row_sums[row] = std::accumulate(values_[row].begin(), values_[row].end(), 0.0);
        }
        // Return as a NumPy array
        return pybind11::array(row_sums.size(), row_sums.data());
    } else {
        throw std::invalid_argument("Invalid axis value; must be 0 or 1.");
    }
}


#endif // DATAFRAME_H
