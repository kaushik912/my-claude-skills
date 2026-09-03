## export MISTRAL_API_KEY=<your-api-key-here>
## mistral-large-latest has a free/trial tier -- verify current limits at
## https://console.mistral.ai before relying on it.
curl --location "https://api.mistral.ai/v1/chat/completions" \
     --header 'Content-Type: application/json' \
     --header 'Accept: application/json' \
     --header "Authorization: Bearer $MISTRAL_API_KEY" \
     --data '{
    "model": "mistral-large-latest",
    "messages": [
     {
        "role": "user",
        "content": "How far is the moon from earth?"
      }
    ]
  }'
