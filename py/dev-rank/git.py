import datetime
import pandas as pd
from config import GITHUB_API, orgs, users, repos, HEADERS
from utils import get_all_pages, style_dataframe
import requests 

from collections import defaultdict
import csv

one_week_ago = datetime.datetime.now() - datetime.timedelta(weeks=1)

active_repos = []
inactive_repos = []
commit_count = 0
active_devs = set()


def get_all_repos():

    print("Iterating through provided organisations")
    # Retrieve all repositories from the organizations and users
    for org in orgs:
        org_repos_url = f'{GITHUB_API}/orgs/{org}/repos'
        org_repos = get_all_pages(org_repos_url)
        org_repos_names = [repo['full_name'] for repo in org_repos]
        repos.extend(org_repos_names)
        

    print(f"Found {len(repos)} repositories. Now iterating through provided users...")

    for user in users:
        user_repos_url = f'{GITHUB_API}/users/{user}/repos'
        user_repos = get_all_pages(user_repos_url)
        user_repos_names = [repo['full_name'] for repo in user_repos]
        repos.extend(user_repos_names)

    print(f"Found {len(repos)} repositories. Checking commits for the past week...")

def get_stats():
    global commit_count

    for i, repo_name in enumerate(repos):
        repo_url = f"{GITHUB_API}/repos/{repo_name}/commits"
        response = requests.get(repo_url, headers=HEADERS, params={"since": one_week_ago.isoformat()})

        if response.status_code == 200:
            commits = response.json()

            if commits:
                devs = set(commit["author"]["login"] for commit in commits if commit["author"])
                active_devs.update(devs)
                active_repos.append(f"{repo_name} ({', '.join(devs)})")
                commit_count += len(commits)
                # Print active repo information
                print(f"{i+1}/{len(repos)} Repositories Checked. Active: {len(active_repos)}, Inactive: {len(inactive_repos)}, Commits: {commit_count}, Active Devs: {len(active_devs)}", end='\r')
            else:
                inactive_repos.append(repo_name)
                # Print inactive repo information
                print(f"{i+1}/{len(repos)} Repositories Checked. Active: {len(active_repos)}, Inactive: {len(inactive_repos)}, Commits: {commit_count}, Active Devs: {len(active_devs)}", end='\r')

        else:
            print(f"Error fetching commit data for {repo_name}. Status code: {response.status_code}")

def create_df():
    ## DATAFRAME
    repo_data = []
    for repo in active_repos:
        repo_name, devs = repo.split(" (")
        devs = devs.strip(")").split(", ")
        org, repo_name = repo_name.split('/')
        repo_data.append({"Organization": org, "Repository": repo_name, "Active Developers": devs})

    for repo in inactive_repos:
        org, repo_name = repo.split('/')
        repo_data.append({"Organization": org, "Repository": repo_name, "Active Developers": "0"})

    # Create a pandas DataFrame
    df = pd.DataFrame(repo_data)

    # Export the DataFrame to a CSV file
    df.to_csv("active_repos.csv", index=False)

    return df


def print_term():

    print(f"All Repositories Checked. Active: {len(active_repos)}, Inactive: {len(inactive_repos)}, Commits: {commit_count}, Active Devs: {len(active_devs)}", end='\r')

    # Print final results after loop completes
    #print("\nNo commits:", ', '.join(inactive_repos))
    print("Commits:", ', '.join(active_repos))
    print("Total commits across all repositories:", commit_count)
    print("Active developers:", len(active_devs), ', '.join(active_devs))




if __name__ == "__main__":
    
    # Iterate through provided Orgs and Users and get repos
    get_all_repos()

    # Get stats on all repos
    get_stats()
    
    # Create and return a dataframe with both active and inactive repos + devs
    df = create_df()

    # Print result to terminal
    print_term()

    # Prepare the overview text
    overview_text = f"Active: {len(active_repos)}, Inactive: {len(inactive_repos)}, Commits: {commit_count}, Active Devs: {len(active_devs)}"

    # Save the styled dataframe to an HTML file
    with open('repo_activity.html', 'w') as f:
        f.write(style_dataframe(df, overview_text))