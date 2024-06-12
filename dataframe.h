#ifndef DATAFRAME_H
#define DATAFRAME_H

#include <vector>
#include <unordered_map>
#include <string>
#include <stdexcept>
#include <memory>
#include <cmath> // for NAN
#include <sstream>
#include <iostream>

// Forward declarations
class DataFrame;

struct Mask {
    int start;
    int stop;
    int step;
    Mask(int start = 0, int stop = 0, int step = 1)
        : start(start), stop(stop), step(step) {}
};

class ObjectIndex {
public:
    ObjectIndex(const std::vector<std::string>& keys, DataFrame* df = nullptr)
        : keys_(keys), df_(df), mask_(nullptr) {
        for (size_t i = 0; i < keys_.size(); ++i) {
            index_[keys_[i]] = static_cast<int>(i);  // Explicit cast to avoid warning
        }
    }

    int get_index(const std::string& key) const {
        auto it = index_.find(key);
        if (it == index_.end()) {
            throw std::out_of_range("Key not found in index");
        }
        return it->second;
    }

    const std::vector<std::string>& keys() const {
        return keys_;
    }

    const std::unordered_map<std::string, int>& index_map() const {
        return index_;
    }

    void set_mask(Mask* mask) {
        mask_ = mask;
    }

    std::string repr() const {
        std::ostringstream os;
        os << "ObjectIndex(";
        for (const auto& key : keys_) {
            os << key << " ";
        }
        os << ")";
        return os.str();
    }

private:
    std::vector<std::string> keys_;
    std::unordered_map<std::string, int> index_;
    DataFrame* df_;
    Mask* mask_;
};

// IntegerLocation class
class IntegerLocation {
public:
    IntegerLocation(DataFrame* df)
        : df_(df) {}

    std::vector<double> get(int arg) const;

private:
    DataFrame* df_;
};

// DataFrame class
class DataFrame {
public:
    DataFrame(const std::vector<std::vector<double>>& values,
              const std::vector<std::string>& row_keys,
              const std::vector<std::string>& column_keys)
        : values_(values), 
          index_(row_keys, this), 
          columns_(column_keys, this), 
          mask_(0, static_cast<int>(values.size()), 1),  // Explicit cast to avoid warning
          iloc(this) {
        if (values.size() != row_keys.size() || values.empty() || values[0].size() != column_keys.size()) {
            throw std::invalid_argument("Mismatch between DataFrame dimensions and index/columns sizes.");
        }
    }

    std::vector<std::vector<double>> values() const {
        std::vector<std::vector<double>> masked_values;
        for (int i = mask_.start; i < mask_.stop; i += mask_.step) {
            masked_values.push_back(values_[i]);
        }
        return masked_values;
    }

    std::vector<double> get_row(const std::string& key) const {
        int row_idx = index_.get_index(key);
        return values_[row_idx];
    }

    std::vector<double> get_column(const std::string& key) const {
        int col_idx = columns_.get_index(key);
        std::vector<double> col_values;
        for (const auto& row : values_) {
            col_values.push_back(row[col_idx]);
        }
        return col_values;
    }

    void set_mask(int start, int stop, int step) {
        mask_ = Mask(start, stop, step);
        index_.set_mask(&mask_);
        columns_.set_mask(&mask_);
    }

    std::pair<size_t, size_t> shape() const {
        return { values_.size(), values_.empty() ? 0 : values_[0].size() };
    }

    const ObjectIndex& index() const {
        return index_;
    }

    const ObjectIndex& columns() const {
        return columns_;
    }

    std::string repr() const {
        std::ostringstream os;
        os << "DataFrame:\n";
        os << "Rows: " << index_.repr() << "\n";
        os << "Columns: " << columns_.repr() << "\n";
        os << "Values: \n";
        for (const auto& row : values_) {
            for (const auto& val : row) {
                os << val << " ";
            }
            os << "\n";
        }
        return os.str();
    }

    IntegerLocation iloc;

    // Getter for values_
    const std::vector<std::vector<double>>& get_values() const {
        return values_;
    }

private:
    std::vector<std::vector<double>> values_;
    ObjectIndex index_;
    ObjectIndex columns_;
    Mask mask_;
};

// Definition of IntegerLocation's get method
std::vector<double> IntegerLocation::get(int arg) const {
    if (arg < 0 || arg >= static_cast<int>(df_->get_values().size())) {  // Cast for size comparison
        throw std::out_of_range("Index out of range");
    }
    return df_->get_values()[arg];
}

#endif // DATAFRAME_H
