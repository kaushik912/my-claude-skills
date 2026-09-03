## export OPENROUTER_API_KEY=<your-api-key-here>
curl -N https://openrouter.ai/api/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -d '{
  "model": "openrouter/free",
  "stream": true,
  "messages": [
    {"role": "user", "content": "Hello"}
  ]
}'
