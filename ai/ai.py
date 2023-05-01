import os
import openai

docs_dir = '../../ergodocs'
docs = []

for filename in os.listdir(docs_dir):
    filepath = os.path.join(docs_dir, filename)
    if os.path.isfile(filepath):
        with open(filepath, 'r') as f:
            docs.append(f.read())




model_engine = "davinci"
model_name = "my-mkdocs-model"

openai.Model.create(
    model=model_name,
    training_data=docs,
    training_configuration={
        'language': 'en',
        'input_size': len(docs),
        'output_size': 2048,
        'batch_size': 4,
        'epochs': 10,
        'learning_rate': 1e-4,
    },
    engine=model_engine,
    prompt=None,
    max_tokens=1024,
    temperature=0.5,
)

prompt = "What is the meaning of life?"
model = "my-mkdocs-model"

response = openai.Completion.create(
    engine=model_engine,
    prompt=prompt,
    max_tokens=1024,
    n=1,
    stop=None,
    temperature=0.5,
    model=model,
)

generated_text = response.choices[0].text
print(generated_text)



