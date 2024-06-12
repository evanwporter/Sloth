import numpy as np
from pydataframe import PyDataFrame

data = np.array([[1, 2, 3], [4, 5, 6]], dtype=np.float64)
df = PyDataFrame(data)

print(df.get_values())
