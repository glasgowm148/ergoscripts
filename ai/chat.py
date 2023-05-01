import openai
import os
import logging

logging.basicConfig(level=logging.DEBUG)


model_engine = "gpt-4"  # can be any other GPT-3 engine

def get_response(prompt, model, stop, user_input):
    logging.debug(f"Sending prompt to OpenAI API: {prompt}")
    response = openai.Completion.create(
        engine=model,
        prompt=prompt,
        max_tokens=1024,
        n=1,
        stop=stop,
        temperature=0.7,
        top_p=1,
        presence_penalty=0.6,
        frequency_penalty=0.6,
    )

    message = response.choices[0].text.strip()
    logging.debug(f"Received response from OpenAI API: {message}")
    return message


    message = response.choices[0].text.strip()
    logging.debug(f"Received response from OpenAI API: {message}")
    return message

def main():
    prompt = ""
    stop = "\n"
    while True:
        user_input = input("> ")
        prompt += user_input.strip() + "\n"
        response = get_response(prompt, model_engine, stop, user_input)
        prompt += response + "\n"
        print(response)
        logging.debug(f"Current prompt: {prompt}")

if __name__ == "__main__":
    main()
