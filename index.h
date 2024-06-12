#ifndef INDEX_H
#define INDEX_H

#include <vector>
#include <unordered_map>
#include <stdexcept>
#include <algorithm>
#include <numeric>
#include <iterator>
#include <type_traits>
#include <sstream>
#include <iostream>

// Helper function to check if an index is within a slice range
inline bool in_slice(int index, int start, int stop, int step) {
    if (step > 0) {
        return (index >= start) && (index < stop) && ((index - start) % step == 0);
    } else {
        return (index <= start) && (index > stop) && ((index - start) % step == 0);
    }
}

// Helper function to convert std::vector to string for display
template <typename T>
std::string vector_to_string(const std::vector<T>& vec) {
    std::ostringstream os;
    os << "[";
    for (size_t i = 0; i < vec.size(); ++i) {
        os << vec[i];
        if (i < vec.size() - 1) os << ", ";
    }
    os << "]";
    return os.str();
}

// Base Index class
class _Index {
public:
    virtual ~_Index() = default;

    virtual std::vector<int> keys() const = 0;

    virtual _Index* fast_init(int start, int stop, int step) const = 0;

    virtual size_t size() const = 0;
};

// ObjectIndex class
class ObjectIndex : public _Index {
public:
    explicit ObjectIndex(const std::vector<std::string>& index)
        : keys_(index) {
        initialize();
        mask_ = {0, static_cast<int>(index.size()), 1};
    }

    std::vector<int> keys() const override {
        std::vector<int> result;
        result.reserve(keys_.size());
        for (int i = mask_.start; i < mask_.stop; i += mask_.step) {
            result.push_back(i);
        }
        return result;
    }

    int get_item(const std::string& arg) const {
        auto it = index_.find(arg);
        if (it == index_.end()) {
            throw std::out_of_range(arg + " is not a member of the index.");
        }
        int ret = it->second;
        if (in_slice(ret, mask_.start, mask_.stop, mask_.step)) {
            return ret;
        }
        throw std::out_of_range("Invalid key: " + arg);
    }

    bool contains(const std::string& item) const {
        return index_.find(item) != index_.end();
    }

    std::string repr() const {
        std::ostringstream os;
        os << "ObjectIndex(" << vector_to_string(keys_) << ")";
        return os.str();
    }

    _Index* fast_init(int start, int stop, int step) const override {
        return new ObjectIndex(*this, start, stop, step);
    }

    size_t size() const override {
        return keys_.size();
    }

private:
    std::vector<std::string> keys_;
    std::unordered_map<std::string, int> index_;
    struct Mask {
        int start, stop, step;
    } mask_;

    void initialize() {
        for (int i = 0; i < keys_.size(); ++i) {
            index_[keys_[i]] = i;
        }
    }

    ObjectIndex(const ObjectIndex& original, int start, int stop, int step)
        : keys_(original.keys_), index_(original.index_) {
        mask_ = {start, stop, step};
    }
};

// RangeIndex class
class RangeIndex : public _Index {
public:
    RangeIndex(int start = 0, int stop = 1, int step = 1)
        : start_(start), stop_(stop), step_(step) {}

    std::vector<int> keys() const override {
        std::vector<int> result;
        for (int i = start_; i < stop_; i += step_) {
            result.push_back(i);
        }
        return result;
    }

    int get_item(int arg) const {
        if (!in_slice(arg, start_, stop_, step_)) {
            throw std::out_of_range(std::to_string(arg) + " not in slice");
        }
        return (arg - start_) / step_;
    }

    _Index* fast_init(int start, int stop, int step) const override {
        return new RangeIndex(start, stop, step);
    }

    size_t size() const override {
        return (stop_ - start_ + step_ - 1) / step_;
    }

private:
    int start_, stop_, step_;
};

#endif // INDEX_H
