import os

import requests
import json

## export OPENROUTER_API_KEY=<your-api-key-here>
## "openrouter/free" auto-selects whichever free model is currently up.
## Swap the model string for a specific free model, e.g.:
##   "meta-llama/llama-3.3-70b-instruct"
##   "cohere/north-mini-code:free"   -- good for coding tasks

response = requests.post(
  url="https://openrouter.ai/api/v1/chat/completions",
  headers={
    "Authorization": "Bearer " + os.getenv("OPENROUTER_API_KEY"),
    "Content-Type": "application/json",
  },
  data=json.dumps({
    "model": "openrouter/free",
    "messages": [
        {
          "role": "user",
          "content": "How many r's are in the word 'strawberry'?"
        }
      ],
    "reasoning": {"enabled": True}
  })
)

response = response.json()
message = response['choices'][0]['message']
print(message.get('content'))
