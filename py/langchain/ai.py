from langchain.llms import OpenAI

llm = OpenAI(temperature=0.9)

text = "Describe the eUTXO model"
print(llm(text))

from langchain.prompts import PromptTemplate

prompt = PromptTemplate(
    input_variables=["product"],
    template="What is a good name for a company that makes {product}?",
)
print(prompt.format(product="colorful socks"))


from langchain.document_loaders import TextLoader
loader = TextLoader('../state_of_the_union.txt')