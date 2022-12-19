import praw


reddit = praw.Reddit(client_id='8YXqLXM2-g4M24mD3aavhg', client_secret='GRJgYoDt3I5bSnawcfHNdCyycJ5jFA', user_agent='scraper')


def votes_per_month():
    score = 0
    with open("subreddits.txt", "r") as a_file:
        for line in a_file:
            stripped_line = line.strip()

            # get 10 hot posts from the MachineLearning subreddit
            hot_posts = reddit.subreddit(stripped_line).top(time_filter="month")
            for post in hot_posts:
                #print(post.title)
                #print(post.score)
                score += post.score

            print(score)
            score = 0

def votes_per_year():
    score = 0
    with open("subreddits.txt", "r") as a_file:
        for line in a_file:
            stripped_line = line.strip()

            # get 10 hot posts from the MachineLearning subreddit
            hot_posts = reddit.subreddit(stripped_line).top(time_filter="year")
            for post in hot_posts:
                #print(post.title)
                #print(post.score)
                score += post.score

            print(score)
            score = 0

votes_per_month()

#votes_per_year()