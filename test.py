import dataframe as dfmod

def test_dataframe():
    # Create an ObjectIndex and ColumnIndex
    row_index = dfmod.ObjectIndex(
        {'row1': 0, 'row2': 1, 'row3': 2}, 
        ['row1', 'row2', 'row3']
    )
    col_index = dfmod.ColumnIndex(
        {'col1': 0, 'col2': 1}, 
        ['col1', 'col2']
    )

    # Create a DataFrame
    values = [
        [1.0, 2.0],
        [3.0, 4.0],
        [5.0, 6.0]
    ]
    dataframe = dfmod.DataFrame(values, row_index, col_index)

    # Test DataFrame attributes
    print("DataFrame repr:")
    print(dataframe.repr())
    
    shape = dataframe.shape()
    print(f"DataFrame shape: {shape}")
    assert shape == (3, 2), f"Expected shape (3, 2), got {shape}"

    # Test getting a column
    col1 = dataframe.get_col('col1')
    print(f"Column 'col1': {col1}")
    assert col1 == [1.0, 3.0, 5.0], f"Expected [1.0, 3.0, 5.0], got {col1}"

    # Test getting values
    vals = dataframe.values()
    print(f"Values: {vals}")
    assert vals == values, f"Expected {values}, got {vals}"

    # Test IntegerLocation
    iloc = dfmod.IntegerLocation(dataframe)
    row2 = iloc.get(1)
    print(f"Row 1 via iloc: {row2}")
    assert row2 == [3.0, 4.0], f"Expected [3.0, 4.0], got {row2}"

    # Test Location
    loc = dfmod.Location(dataframe)
    row2_loc = loc.get('row2')
    print(f"Row 'row2' via loc: {row2_loc}")
    assert row2_loc == [3.0, 4.0], f"Expected [3.0, 4.0], got {row2_loc}"

    print("All tests passed.")

if __name__ == "__main__":
    test_dataframe()
