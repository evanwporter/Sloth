import numpy as np
cimport numpy as np

from cpython cimport str

from conversions import Conversions

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

# cdef np.int64_t weekday(np.int64_t dt):
#     # 259200000000000 ns = 3 days
#     return days_to_ns((dt - (259200000000000)) % 7)

cdef datetime64 floor_(datetime64 dt, str timeframe):
    c = Conversions()
    if timeframe == "W":
        i = (dt // c.D) * c.D
        d = i - ( ( (i - 259200000000000) % 7 ) * c.D)
    else:
        d = (dt // getattr(c, timeframe)) * getattr(c, timeframe)
    return d

cdef datetime64 ceil_(datetime64 dt, str timeframe):
    c = Conversions()

    if timeframe == "W":
        i = np.ceil(dt / c.D) * c.D
        d = i + ((7 - ( (i - 259200000000000) % 7 )) * c.D)
    else:
        d = np.ceil(dt / getattr(c, timeframe)) * getattr(c, timeframe)
    return (d)

# cdef (int, int, int) _normalize_slice(slice s, int length):
#     cdef int start
#     cdef int stop
#     cdef int step
    
#     # Handle None for start, stop, and step
#     start = s.start if s.start is not None else (0 if s.step is None or s.step > 0 else length - 1)
#     stop = s.stop if s.stop is not None else (length if s.step is None or s.step > 0 else -1)
#     step = s.step if s.step is not None else 1
    
#     # Handle negative indices
#     if start < 0:
#         start += length
#     if stop < 0:
#         stop += length
    
#     return start, stop, step