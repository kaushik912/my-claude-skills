## export GEMINI_API_KEY=<your-api-key-here>
## Lists every model currently exposed by the Gemini API for this key/tier.
curl "https://generativelanguage.googleapis.com/v1beta/models" -H "X-goog-api-key: $GEMINI_API_KEY"
