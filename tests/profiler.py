import cProfile
import pstats
import numpy as np
from Sloth import frame  # Import your compiled Cython module

def main():
    data = np.array([[1, 2, 3], [4, 5, 6]])
    df = frame.DataFrame(data)
    print(df.values)
    print(df.head(2))
    print(df.iloc[10:19:2])

if __name__ == "__main__":
    cProfile.run('main()', 'profile_output')
    
    p = pstats.Stats('profile_output')
    p.sort_stats('cumulative').print_stats()

    # main()
