#!/bin/python3

import sys
from openai import OpenAI
import httpx

# Read the content of the document files
def read_document(file_path):
    try:
        with open(file_path, 'r') as file:
            return file.read()
    except FileNotFoundError:
        print(f"Error: The file '{file_path}' does not exist.")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

# Point to the local server
client = OpenAI(base_url="http://localhost:9090/v1", api_key="none", timeout=httpx.Timeout(3600))

# Read system message, document paths, user messages, and temperature
system = sys.argv[1]
doc1_path = sys.argv[2]
doc1_user_message = sys.argv[3]
doc2_path = sys.argv[4]
doc2_user_message = sys.argv[5]
doc3_path = sys.argv[6]
doc3_user_message = sys.argv[7]
task_user_message = sys.argv[8]
temp = float(sys.argv[9])

# Read the documents
doc1 = read_document(doc1_path)
doc2 = read_document(doc2_path)
doc3 = read_document(doc3_path)

completion = client.chat.completions.create(
  model="llama-3_2-3b-it-q8_0",
  messages=[
    {"role": "system", "content": system },
    {"role": "user", "content": doc1_user_message },
    {"role": "user", "content": doc1 },
    {"role": "user", "content": doc2_user_message },
    {"role": "user", "content": doc2 },
    {"role": "user", "content": doc3_user_message },
    {"role": "user", "content": doc3 },
    {"role": "user", "content": task_user_message }
  ],
  temperature=temp,
  stream=True,
)

for chunk in completion:
  if chunk.choices[0].delta.content:
    print(chunk.choices[0].delta.content, end="", flush=True)
print('\n')
