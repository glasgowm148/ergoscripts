import openai

#openai.api_key = "your_api_key_here"

models = openai.Model.list()
for model in models['data']:
    print(model['id'])
