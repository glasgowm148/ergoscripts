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


def style_dataframe(df, overview_text):
    # Define the styles to be applied to the table
    styles = [
        {'selector': 'th', 'props': [('font-size', '120%'), ('text-align', 'left')]},
        {'selector': 'td', 'props': [('font-size', '110%')]},
        {'selector': 'thead th', 'props': [('background-color', '#f2f2f2')]}
    ]

    # Create the styled table
    styled_table = df.style.set_table_styles(styles).render()

    # Initialize the HTML string
    html_string = ''

    # Add a centered div element with the overview text
    html_string += f"<div style='text-align: center;'><p>{overview_text}</p></div><br>"

    # Add the styled table to the HTML string
    html_string += styled_table

    return html_string


