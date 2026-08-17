from google import genai
client = genai.Client()

## pip install google-genai
## export GEMINI_API_KEY=<your-api-key-here>

## Models tested and confirmed working on the free tier:
## gemini-flash-lite-latest   -- fast, cheap, good default
## gemini-3.6-flash           -- best all-round pick per user testing (see coding_agents.md)

response = client.models.generate_content(
    model='gemini-flash-lite-latest',
    contents='Tell me a joke in 100 words.'
)
print(response.text)
