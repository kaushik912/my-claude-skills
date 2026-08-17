import os

from groq import Groq
## pip install groq
## export GROQ_API_KEY=<your-api-key-here>

client = Groq(
    api_key=os.environ.get("GROQ_API_KEY"),
)

chat_completion = client.chat.completions.create(
    messages=[
        {
            "role": "user",
            "content": "Explain the importance of fast language models. Keep it concise and clear, and provide examples of how they can be used in real-world applications.",
        }
    ],
    model="llama-3.3-70b-versatile",
)

print(chat_completion.choices[0].message.content)
