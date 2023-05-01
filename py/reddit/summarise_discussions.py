import os
from dotenv import load_dotenv
import praw
import datetime
import discord
import requests
from collections import defaultdict
import openai


# Load environment variables from .env file
load_dotenv()

# Set up Reddit API credentials
client_id = os.environ["REDDIT_CLIENT_ID"]
client_secret = os.environ["REDDIT_CLIENT_SECRET"]
user_agent = os.environ["REDDIT_USER_AGENT"]

reddit = praw.Reddit(client_id=client_id, client_secret=client_secret, user_agent=user_agent)

# Set up Discord API credentials
DISCORD_BOT_TOKEN = os.environ["DISCORD_BOT_TOKEN"]

# Set up OpenAI API credentials
OPENAI_API_KEY = os.environ["OPENAI_API_KEY"]
openai.api_key = OPENAI_API_KEY

def split_message(message, separator="\n\n"):
    parts = []
    current_part = ""

    for line in message.split(separator):
        if len(current_part + line) + len(separator) <= 2000:
            current_part += line + separator
        else:
            parts.append(current_part.strip())
            current_part = line + separator

    parts.append(current_part.strip())

    return parts



def trim_prompt(prompt, max_length):
    words = prompt.split()
    trimmed_prompt = ""

    for word in words:
        if len(trimmed_prompt + word) + 1 <= max_length:
            trimmed_prompt += " " + word
        else:
            break

    return trimmed_prompt.strip()

# Function to summarize text using ChatGPT
def get_post_summary(post):
    discussion = f"**{post.title} by ({post.author})** {post.permalink}\n\n"

    post.comments.replace_more(limit=None)
    top_comments = post.comments.list()[:5]

    for comment in top_comments:
        #discussion += f"\n- {comment.body}... ({comment.score} points)"
        discussion += f"\n- {comment.body}\n"
    
    discussion += "\n\n"
    print('####discussion input:', discussion)
    print('###end-discussion')
    #prompt = "Summarise this into a paragraph giving the title of the post in bold and the link at the start. Identify any questions that went unanswered or concerns that were raised. Include the hyperlink and https://www.reddit.com/r/always. Do not use the title for context in your summarisation:\n\n" + discussion

    prompt = """
                Summarise this comments given at the end of this string. Identify any questions that went unanswered or concerns that were raised.
                Output in the following format at all times: 
                    - **Post-Title**\n<your-summary>\n<questions unanswered>\n<concerns>\n <link> including https://reddit.com/r/
                    - Always include a title.
                 

                :""" + discussion

    
    response = openai.Completion.create(
        engine="text-davinci-003",
        prompt=prompt,
        max_tokens=1000,
        n=1,
        stop=None,
        temperature=0.7,
    )
    
    summary = response.choices[0].text.strip()
    print('Summary OUTPUT from GPT:', summary)
    return summary


# Discord bot setup
intents = discord.Intents.default()
client = discord.Client(intents=intents)

@client.event
async def on_ready():
    print(f"{client.user} has connected to Discord!")

@client.event
async def on_message(message):
     # Ignore messages sent by the bot itself
    if message.author == client.user:
        return
    if message.content == "/redditstats":

        now = datetime.datetime.now()
        one_week_ago = now - datetime.timedelta(days=1)
        timestamp = int(one_week_ago.timestamp())

        subreddit = reddit.subreddit("ergonauts")
        top_posts = subreddit.top("week", limit=2)

        all_summaries = ""

        for post in top_posts:
            summary = get_post_summary(post)
            all_summaries += f"{summary}\n\n\n"

            if summary:
                message_parts = ["Top posts from r/ergonauts this week - summarised!"]
                message_parts += split_message(summary)
            else:
                message_parts = ["Unable to generate summary."]

            channel_id = YOUR_CHANNEL_ID
            channel = client.get_channel(channel_id)
            message = ""

            if summary:
                message = f"{summary}"
            else:
                message = "Unable to generate summaries.\n"

            if message:
                message_parts = split_message(message)
            else:
                message_parts = ["Unable to generate summary."]

            for part in message_parts:
                await channel.send(part)

        
    
    
        await client.close()

# Replace YOUR_CHANNEL_ID with the actual Discord channel ID where you want to send the summaries
YOUR_CHANNEL_ID = int(os.environ["DISCORD_CHANNEL_ID"])

# Run the Discord bot
client.run(DISCORD_BOT_TOKEN)
