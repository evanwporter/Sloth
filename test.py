import numpy as np
import pydataframe as sl

data = np.array([[1, 2, 3], [4, 5, 6]], dtype=np.float64)
df = sl.DataFrame(data.tolist())

print(df.to_numpy())

slice_obj = sl.slice(start=1, stop=10, step=2)

print(f"Start: {slice_obj.start}, Stop: {slice_obj.stop}, Step: {slice_obj.step}")

slice_obj.start = 0
slice_obj.stop = 8
slice_obj.step = 1

print(f"Updated Start: {slice_obj.start}, Updated Stop: {slice_obj.stop}, Updated Step: {slice_obj.step}")

print(type(df.sum(axis=1)))

from pydataframe import ObjectIndex, RangeIndex

def test_object_index():
    print("Testing ObjectIndex...")
    obj_idx = ObjectIndex(['a', 'b', 'c', 'd', 'e'])

    # Test keys
    print("Keys:", obj_idx.keys())  # Should print: [0, 1, 2, 3, 4]

    # Test get_item
    print("Get item 'b':", obj_idx.get_item('b'))  # Should print: 1
    try:
        print("Get item 'z':", obj_idx.get_item('z'))  # Should raise KeyError
    except IndexError as e:
        print("Error:", e)

    # Test contains
    print("'c' in ObjectIndex:", 'c' in obj_idx)  # Should print: True
    print("'z' in ObjectIndex:", 'z' in obj_idx)  # Should print: False

    # Test repr
    print("Repr:", repr(obj_idx))  # Should print: ObjectIndex(['a', 'b', 'c', 'd', 'e'])

def test_range_index():
    print("\nTesting RangeIndex...")
    range_idx = RangeIndex(0, 10, 2)

    # Test keys
    print("Keys:", range_idx.keys())  # Should print: [0, 2, 4, 6, 8]

    # Test get_item
    print("Get item 4:", range_idx.get_item(4))  # Should print: 2
    try:
        print("Get item 5:", range_idx.get_item(5))  # Should raise KeyError
    except IndexError as e:
        print("Error:", e)

    # Test size
    print("Size:", range_idx.size())  # Should print: 5

if __name__ == "__main__":
    test_object_index()
    test_range_index()

