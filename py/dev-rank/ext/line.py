import json
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
import matplotlib.dates as mdates

# Open the JSON file and load the data
with open('dl.json', 'r') as f:
    data = json.load(f)

# Filter out all data before 28th July 2020
cutoff_date = pd.to_datetime('2020-07-28')
data = [row for row in data if pd.to_datetime(row['date']) >= cutoff_date]

# Convert the data to a pandas DataFrame
df = pd.DataFrame(data)
df['date'] = pd.to_datetime(df['date'], format='%Y-%m-%d')
df.set_index('date', inplace=True)

# Calculate the total for each date
df['Total'] = df['Ergo Core'] + df['Sub-Ecosystems']

# Calculate the rolling mean (moving average) for the total
df['Total MA'] = df['Total'].rolling(window=30).mean()

# Load price data
df_price = pd.read_csv('normalized_price.csv')
df_price['snapped_at'] = pd.to_datetime(df_price['snapped_at'])
df_price.set_index('snapped_at', inplace=True)

# Round price to nearest cent
df_price['price'] = df_price['price'].round(2)

# Merge developer and price dataframes
df_merged = pd.merge(df, df_price, left_index=True, right_index=True, how='left')

# Forward fill any missing prices
df_merged['price'].fillna(method='ffill', inplace=True)

# Create the plot for line graph
fig, ax = plt.subplots(figsize=(10, 6))

ax.plot(df_merged.index, df_merged['Ergo Core'], label='Ergo Core', color='orange', linewidth=2)
ax.plot(df_merged.index, df_merged['Sub-Ecosystems'], label='Sub-Ecosystems', color='white', linewidth=2)

# Add moving average line to the line plot
ax.plot(df_merged.index, df_merged['Total MA'], label='Total MA', color='green', linewidth=2)

# Add price line to the plot
ax2 = ax.twinx()  # instantiate a second axes that shares the same x-axis
ax2.plot(df_merged.index, df_merged['price'], label='Price', color='blue', linewidth=2)

# Set the date format on the x-axis
ax.xaxis.set_major_locator(mdates.MonthLocator())
ax.xaxis.set_major_formatter(mdates.DateFormatter('%b %Y'))

# Rotate the x-axis tick labels for better visibility
plt.xticks(rotation=45, color='white')

# Set the plot title and labels
ax.set_title('Weekly Active Developers and Price', color='white')
ax.set_ylabel('Number of Developers', color='white')
ax.set_xlabel('Date', color='white')
ax2.set_ylabel('Price', color='blue')

# Set the axis line color
ax.spines['bottom'].set_color('white')
ax.spines['left'].set_color('white')
ax.spines['top'].set_color('white')
ax.spines['right'].set_color('white')

# Set the tick parameters
ax.tick_params(axis='x', colors='white')
ax.tick_params(axis='y', colors='white')

# Set the legend
fig.legend(loc="upper left")

# Save the line graph as a transparent PNG
plt.savefig('line_graph.png', transparent=True)
plt.show()
