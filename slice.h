#ifndef SLICE_H
#define SLICE_H

class slice {
public:
    slice(int start, int stop, int step)
        : start_(start), stop_(stop), step_(step) {}

    int get_start() const { return start_; }
    int get_stop() const { return stop_; }
    int get_step() const { return step_; }

    void set_start(int start) { start_ = start; }
    void set_stop(int stop) { stop_ = stop; }
    void set_step(int step) { step_ = step; }

private:
    int start_;
    int stop_;
    int step_;
};

#endif // SLICE_H
