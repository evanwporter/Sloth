// dataframe.cpp
#include <vector>
#include <stdexcept>

class DataFrame {
public:
    DataFrame(const std::vector<std::vector<double>>& values) : values_(values) {}

    std::vector<std::vector<double>> values() const {
        return values_;
    }

    size_t num_rows() const {
        return values_.size();
    }

    size_t num_cols() const {
        return values_.empty() ? 0 : values_[0].size();
    }

    std::vector<double> get_row(size_t index) const {
        if (index >= values_.size()) {
            throw std::out_of_range("Index out of range");
        }
        return values_[index];
    }

    std::vector<double> get_col(size_t index) const {
        if (values_.empty() || index >= values_[0].size()) {
            throw std::out_of_range("Index out of range");
        }
        std::vector<double> column(values_.size());
        for (size_t i = 0; i < values_.size(); ++i) {
            column[i] = values_[i][index];
        }
        return column;
    }

    void set_row(size_t index, const std::vector<double>& row) {
        if (index >= values_.size() || row.size() != num_cols()) {
            throw std::invalid_argument("Invalid row size");
        }
        values_[index] = row;
    }

    void set_col(size_t index, const std::vector<double>& column) {
        if (column.size() != num_rows()) {
            throw std::invalid_argument("Invalid column size");
        }
        for (size_t i = 0; i < values_.size(); ++i) {
            values_[i][index] = column[i];
        }
    }

private:
    std::vector<std::vector<double>> values_;
};
