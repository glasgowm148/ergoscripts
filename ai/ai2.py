# Note: you need to be using OpenAI Python v0.27.0 for the code below to work
import openai

response = openai.ChatCompletion.create(
  model="gpt-4",
  messages=[
    {"role": "user", "content": 'Are you GPT4?'}
    ]
)

for choice in response.choices:
    print(choice.message["content"])