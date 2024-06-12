import numpy as np
from pydataframe import DataFrame

data = np.array([[1, 2, 3], [4, 5, 6]], dtype=np.float64)
df = DataFrame(data.tolist())

print(df.to_numpy())
