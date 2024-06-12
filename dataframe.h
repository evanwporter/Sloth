#ifndef DATAFRAME_H
#define DATAFRAME_H

#include <vector>
#include <stdexcept>

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

private:
    std::vector<std::vector<double>> values_;
};

#endif // DATAFRAME_H
