#!/usr/bin/env python3

import re
import statistics

def analyze_log(log_file_path):
    # Dictionary to store counts, sums, max, and min for each category
    data = {}

    # Regular expression pattern to match the log entries
    pattern = re.compile(r'(\d+:\d+:\d+\.\d+) \[info\] (World tick|Adding \w+) took: (\d+)')

    # Read the log file
    with open(log_file_path, 'r') as file:
        for line in file:
            match = pattern.match(line)
            if match:
                timestamp, category, time_taken = match.groups()
                time_taken = int(time_taken)

                # Update the count, sum, max, min, and values for the category
                if category not in data:
                    data[category] = {'count': 0, 'sum': 0, 'max': float('-inf'), 'min': float('inf'), 'values': []}
                print(time_taken)
                data[category]['count'] += 1
                data[category]['sum'] += time_taken
                data[category]['max'] = max(data[category]['max'], time_taken)
                data[category]['min'] = min(data[category]['min'], time_taken)
                data[category]['values'].append(time_taken)

    # Calculate and print the statistics
    for category, values in data.items():
        count = values['count']
        average_time = values['sum'] / count if count > 0 else 0
        max_time = values['max']
        min_time = values['min']
        std_dev = statistics.stdev(values['values']) if count > 1 else 0

        print(f'{category} -> Average: {average_time:.2f} nanoseconds, Max: {max_time}, Min: {min_time}, Std Dev: {std_dev:.2f}')

if __name__ == "__main__":
    log_file_path = '/tmp/myrra.lo
