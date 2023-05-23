import pandas as pd

# Load price data
df_price = pd.read_csv('price.csv')

# Convert timestamp to datetime and remove timezone
df_price['snapped_at'] = pd.to_datetime(df_price['snapped_at']).dt.tz_localize(None)

# Set 'snapped_at' column as index
df_price.set_index('snapped_at', inplace=True)

# Filter out all data before 28th July 2020
cutoff_date = pd.to_datetime('2020-07-28')
df_price = df_price[df_price.index >= cutoff_date]

# Calculate the moving average of price
df_price['Price MA'] = df_price['price'].rolling(window=30).mean()

# Save the normalized price data to a new CSV file
df_price.to_csv('normalized_price.csv')

# Display the normalized price data
print(df_price)
