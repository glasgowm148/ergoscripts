import requests
from config import HEADERS
# Import the required libraries
from IPython.core.display import HTML


def get_all_pages(url):
    page = 1
    all_items = []

    while True:
        response = requests.get(url, headers=HEADERS, params={'page': page, 'per_page': 100})

        if response.status_code != 200:
            print(f"Error fetching data. Status code: {response.status_code}")
            break

        items = response.json()

        if not items:
            break

        all_items.extend(items)
        page += 1

    return all_items


def style_dataframe(df, overview):
    styles = '''
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        table {
            border-collapse: collapse;
            width: 80%;
            margin: auto;
        }
        th, td {
            border: 1px solid #dddddd;
            text-align: left;
            padding: 8px;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        th {
            background-color: #333;
            color: white;
        }
    </style>
    '''
    return HTML(styles + f'<div class="overview">{overview_text}</div>' + df.to_html(index=False))


