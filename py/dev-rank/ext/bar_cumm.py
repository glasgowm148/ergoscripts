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

# Filter data up to May 2023
df_merged = df_merged.loc[:'2023-05']

# Resample the data to monthly frequency and take average for incomplete months
def custom_resampler(array_like):
    if array_like.any():
        return array_like.mean()
    elif array_like.isna().any():
        return array_like.ffill().mean()
    else:
        return None

df_merged_monthly = df_merged.resample('M').apply(custom_resampler)

# Create the stacked bar plot
fig, ax = plt.subplots(figsize=(10, 6))

# Calculate cumulative sums for stacked bar plot
ergo_core_cumsum = df_merged_monthly['Ergo Core'].cumsum()
sub_ecosystems_cumsum = df_merged_monthly['Sub-Ecosystems'].cumsum()

# Plot the stacked bars
ax.fill_between(df_merged_monthly.index, 0, ergo_core_cumsum, label='Ergo Core', color='orange')
ax.fill_between(df_merged_monthly.index, ergo_core_cumsum, sub_ecosystems_cumsum, label='Sub-Ecosystems', color='purple')

# Set the x-axis formatting
ax.xaxis.set_major_locator(mdates.YearLocator())
ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
plt.xticks(rotation=45)

# Set the plot title and labels
ax.set_title('Monthly Active Developers', color='black')
ax.set_ylabel('Number of Developers', color='black')
ax.set_xlabel('Date', color='black')

# Set the axis line colors
ax.spines['bottom'].set_color('black')
ax.spines['left'].set_color('black')
ax.spines['top'].set_color('black')
ax.spines['right'].set_color('black')

# Set the legend
ax.legend(loc="upper left")

# Save the bar plot as a transparent PNG
plt.savefig('stacked_bar_plot.png', transparent=True)
plt.show()
