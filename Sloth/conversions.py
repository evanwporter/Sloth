# All numbers are in nanoseconds
class Conversions:
    # s = 10 ** 9 # ns
    def __init__(self):
        self.s = 1000000000
        # m = 60 * (10**9) 
        self.m = 60000000000
        # h = 60 * 60 * (10**9) 
        self.h = 3600000000000
        # D = 24 * 60 * 60 * (10**9)
        self.D = 86400000000000
        # W = 24 * 60 * 60 * (10**9) * 7
        self.W = 604800000000000
        