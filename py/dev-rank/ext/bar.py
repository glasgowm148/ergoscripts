import json
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.patches import Patch

# Load data from JSON file
with open("normalized_dl.json") as file:
    data = json.load(file)

# Extract the dates, Ergo Core, and Sub-Ecosystems values
dates = [entry["date"] for entry in data]
ergo_core = [entry["Ergo Core"] for entry in data]
sub_ecosystems = [entry["Sub-Ecosystems"] for entry in data]

# Create a DataFrame for Seaborn
df = pd.DataFrame({"Date": dates, "Ergo Core": ergo_core, "Sub-Ecosystems": sub_ecosystems})

# Convert the Date column to datetime type
df["Date"] = pd.to_datetime(df["Date"])

# Filter data before August 2020
df = df[df["Date"] >= pd.Timestamp("2020-08-01")]

# Group the data by month and calculate the average of Ergo Core and Sub-Ecosystems
df_grouped = df.groupby(pd.Grouper(key="Date", freq="M")).mean().reset_index()

# Sort the data by date
df_grouped.sort_values("Date", inplace=True)

# Plotting with Seaborn
colors = ["skyblue", "tab:orange"]  # Set the colors for the bars
fig, ax = plt.subplots(figsize=(12, 6))  # Adjust the figsize as per your requirement

# Plot Sub-Ecosystems
sns.barplot(data=df_grouped, x="Date", y="Sub-Ecosystems", ax=ax, color=colors[0])

# Plot Ergo Core
sns.barplot(data=df_grouped, x="Date", y="Ergo Core", ax=ax, color=colors[1])

# Adjust the stacking order
ax.set_ylim(top=ax.get_ylim()[1] * 1.2)  # Increase the y-axis limit to accommodate the legend

# Adding labels and title
plt.xlabel("Date (Month)")
plt.ylabel("Average Weekly Active Devs")
plt.title("Average Weekly Active Devs over Time")

# Create custom legend
legend_labels = ["Sub-Ecosystems", "Ergo Core"]
legend_handles = [Patch(facecolor=color) for color in colors]
plt.legend(legend_handles, legend_labels)

# Formatting the x-axis tick labels as months
months = pd.date_range(start=df_grouped["Date"].min(), end=df_grouped["Date"].max(), freq="MS")
ax.set_xticks(range(len(months)))
ax.set_xticklabels([m.strftime("%Y-%m") for m in months], rotation=45, ha="right")

# Display the plot
plt.tight_layout()
plt.show()
