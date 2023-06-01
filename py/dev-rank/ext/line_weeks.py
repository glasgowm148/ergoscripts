import json
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.dates as mdates

# Open the JSON file and load the data
with open('dl.json', 'r') as f:
    data = json.load(f)

# Filter out all data before 28th July 2020
cutoff_date = pd.to_datetime('2020-07-28')
data = [row for row in data if pd.to_datetime(row['date']) >= cutoff_date]

# Convert the data to a pandas DataFrame
df_developer = pd.DataFrame(data)
df_developer['date'] = pd.to_datetime(df_developer['date'], format='%Y-%m-%d')
df_developer.set_index('date', inplace=True)

# Calculate the total for each date
df_developer['Total'] = df_developer['Ergo Core'] + df_developer['Sub-Ecosystems']

# Calculate the rolling mean (moving average) for the total
df_developer['Total MA'] = df_developer['Total'].rolling(window=30).mean()

# Load price data
df_price_data = pd.read_csv('normalized_price.csv')
df_price_data['snapped_at'] = pd.to_datetime(df_price_data['snapped_at'])
df_price_data.set_index('snapped_at', inplace=True)

# Round price to nearest cent
df_price_data['price'] = df_price_data['price'].round(2)

# Merge developer and price dataframes
df_merged = pd.merge(df_developer, df_price_data, left_index=True, right_index=True, how='left')

# Forward fill any missing prices
df_merged['price'].fillna(method='ffill', inplace=True)

# Create the plot for line graph
fig, ax = plt.subplots(figsize=(10, 6))

ax.plot(df_merged.index, df_merged['Ergo Core'], label='Ergo Core', color='orange', linewidth=2)
ax.plot(df_merged.index, df_merged['Sub-Ecosystems'], label='Sub-Ecosystems', color='purple', linewidth=2)

# Add moving average line to the line plot
ax.plot(df_merged.index, df_merged['Total MA'], label='Active Devs Moving Average', color='red', linewidth=2)

# Add price line to the plot
ax2 = ax.twinx()  # instantiate a second axes that shares the same x-axis
ax2.plot(df_merged.index, df_merged['price'], label='Price', color='skyblue', linewidth=2, linestyle=':')
ax2.tick_params(axis='y', colors='skyblue')
ax.xaxis.set_major_locator(mdates.YearLocator())
ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y'))

# Rotate the tick labels for better readability
plt.xticks(rotation=45)

# Set the plot title and labels
ax.set_title('Weekly Active Developers and Price', color='black')
ax.set_ylabel('Number of Developers', color='black')
ax.set_xlabel('Date', color='black')
ax2.set_ylabel('Price', color='skyblue')

# Set the axis line color
ax.spines['bottom'].set_color('black')
ax.spines['left'].set_color('black')
ax.spines['top'].set_color('black')
ax.spines['right'].set_color('black')

# Set the tick parameters
ax.tick_params(axis='x', colors='black')
ax.tick_params(axis='y', colors='black')

# Set the legend
fig.legend(loc="upper left")

# Save the line graph as a transparent PNG
plt.savefig('line_graph.png', transparent=True)
plt.show()

