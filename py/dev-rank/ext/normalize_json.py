import json
from datetime import datetime

# Load data from JSON file
with open("dl.json") as file:
    data = json.load(file)

# Normalize the date format in the data
for entry in data:
    date_str = entry["date"]
    date_obj = datetime.strptime(date_str, "%Y-%m-%d")
    entry["date"] = date_obj.strftime("%Y-%m-%d")

# Save the updated JSON data to a new file
with open("normalized_dl.json", "w") as file:
    json.dump(data, file, indent=4)

print("JSON data has been normalized and saved as 'normalized_dl.json'.")
