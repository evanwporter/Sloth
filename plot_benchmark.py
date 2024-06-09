# plot_benchmark.py

import pandas as pd
import json
import matplotlib.pyplot as plt

# Load the JSON benchmark file
with open(r'.benchmarks\Windows-CPython-3.9-64bit\0001_benchmark.json', 'r') as f:
    data = json.load(f)

# Extract the benchmarks
benchmarks = data['benchmarks']

# Convert JSON data to DataFrame
df = pd.json_normalize(benchmarks, sep='_')

# Select and rename relevant columns
columns = ['name', 'group', 'stats_mean', 'stats_stddev', 'stats_median', 'stats_min', 'stats_max', 'stats_ops', 'stats_total']
df = df[columns]
df.columns = ['Name', 'Group', 'Mean', 'StdDev', 'Median', 'Min', 'Max', 'Ops', 'Total']

# Save to CSV
df.to_csv('benchmark_results.csv', index=False)

# Save to HTML
df.to_html('benchmark_results.html', index=False)

# Display DataFrame
print(df)

# Sort DataFrame by 'Group' and 'Mean' for better plotting
df_sorted = df.sort_values(by=['Group', 'Mean'])

# Plot the results
plt.figure(figsize=(14, 10))

# Plot by groups
groups = df_sorted['Group'].unique()
for group in groups:
    group_data = df_sorted[df_sorted['Group'] == group]
    plt.barh(group_data['Name'], group_data['Mean'], xerr=group_data['StdDev'], label=group)

plt.xlabel('Mean Time (seconds)')
plt.title('Benchmark Results')
plt.legend(title='Group')
plt.grid(True)
plt.tight_layout()

# Save the plot as a PNG image
plt.savefig('benchmark_results.png')

# Show the plot
plt.show()
