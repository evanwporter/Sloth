# May change to double depending on what I use
# this function for
cdef np.int64_t ns_to_days(np.int64_t ns):
    # 10^9 ns to 1 sec
    # 60 sec to 1 min
    # 60 min to 1 hour
    # 24 hour to 1 day
    # (10 ** 9) * 60 * 60 * 24
    # 86400000000000 ns = 1 day
    return ns / 86400000000000

cdef np.int64_t days_to_ns(np.int64_t days):
    return days * 86400000000000

cdef np.int64_t weekday(np.int64_t dt):
    # 259200000000000 ns = 3 days
    return days_to_ns((dt - (259200000000000)) % 7)