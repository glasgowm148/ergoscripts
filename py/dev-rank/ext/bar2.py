import json
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import seaborn as sns

def load_data():
    # Open the JSON file and load the data
    try:
        with open('normalized_dl.json', 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print('File not found.')
        return None

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

    return df_developer

def load_price_data():
    # Load price data
    df_price_data = pd.read_csv('normalized_price.csv')
    df_price_data['snapped_at'] = pd.to_datetime(df_price_data['snapped_at'])
    df_price_data.set_index('snapped_at', inplace=True)

    # Round price to nearest cent
    df_price_data['price'] = df_price_data['price'].round(2)

    return df_price_data

def merge_data(df_developer, df_price_data):
    # Merge developer and price dataframes
    df_dev_price_merged = pd.merge(df_developer, df_price_data, left_index=True, right_index=True, how='left')

    # Forward fill any missing prices
    df_dev_price_merged['price'].fillna(method='ffill', inplace=True)

    # Filter data up to May 2023
    df_dev_price_merged = df_dev_price_merged.loc[:'2023-05']

    # Resample the data to monthly frequency and take average for incomplete months
    df_merged_monthly = df_dev_price_merged.resample('M').mean()

    return df_merged_monthly

def plot_data(df_merged_monthly):
    # Calculate the maximum value of the number of developers
    max_devs = max(df_merged_monthly['Total'])

    # Create the bar plot
    fig, ax1 = plt.subplots(figsize=(10, 6))

    # Create a secondary y-axis for number of developers
    ax2 = ax1.twinx()

    # Calculate the average values for each group
    ergo_core_avg = df_merged_monthly['Ergo Core']
    sub_ecosystems_avg = df_merged_monthly['Sub-Ecosystems']

    # Set the width of the bars
    width = 25

    # Set the palette
    palette = sns.color_palette("deep", 4)
    palette[2] = sns.color_palette(["skyblue"])[0]

    # Plot the stacked bars against the number of developers
    bars1 = ax1.bar(df_merged_monthly.index, ergo_core_avg, width, label='Ergo Core', color=palette[0])
    bars2 = ax1.bar(df_merged_monthly.index, sub_ecosystems_avg, width, bottom=ergo_core_avg,
            label='Sub-Ecosystems', color=palette[1])

    # Plot the moving average line with dotted line
    line1 = ax1.plot(df_merged_monthly.index, df_merged_monthly['Total MA'], label='Active Devs Moving Average', color=palette[2], linewidth=2, linestyle='dotted')

    # Plot the price line, making sure it is plotted last
    line2 = ax1.plot(df_merged_monthly.index, df_merged_monthly['price'], label='Price', color=palette[3], linewidth=2)

    # Set the x-axis formatting
    ax1.xaxis.set_major_locator(mdates.YearLocator())
    ax1.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
    plt.xticks(rotation=45)

    # Set the plot title and labels
    ax1.set_title('Monthly Active Developers and Price', color='black')
    ax1.set_xlabel('Date', color='black')

    # Set the axis line colors
    ax1.spines['bottom'].set_color('black')
    ax1.spines['left'].set_color('black')
    ax1.spines['top'].set_color('black')
    ax1.spines['right'].set_color('black')

    # Set the tick colors for both y-axes
    ax1.tick_params(axis='y', colors='black')

    # Set the y-axis label for price
    ax1.set_ylabel('Price', color='black')

    # Adjust the limits and labels for ax2 (number of developers)
    ax2.set_ylim(0, 80)
    ax2.set_ylabel('Number of Developers', color='black')
    ax2.tick_params(axis='y', colors='black')

    # Remove duplicate legend
    lines, labels = ax1.get_legend_handles_labels()
    ax1.legend(lines, labels, loc='upper left')

    # Save the bar plot as a transparent PNG
    plt.savefig('stacked_bar_plot.png', transparent=True)
    plt.show()

# Load the data
df_developer = load_data()

# Load the price data
df_price_data = load_price_data()

# Merge the data
df_merged_monthly = merge_data(df_developer, df_price_data)

# Plot the data
plot_data(df_merged_monthly)
