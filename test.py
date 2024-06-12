import dataframe

values = [
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0]
]
row_keys = ["row1", "row2"]
column_keys = ["col1", "col2", "col3"]

df = pydataframe.DataFrame(values, row_keys, column_keys)
print(df.iloc[0])

