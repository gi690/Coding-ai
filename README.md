# Coding AI

Personal Coding AI using:

- Local Qwen2.5-Coder
- llama.cpp
- Aiven OpenSearch
- RAG
- FastAPI
- Railway

## Architecture

User
  |
  v
FastAPI
  |
  +----> Aiven OpenSearch
  |          |
  |          +---- coding_ai_chunks
  |
  +----> llama-server
             |
             +---- Qwen2.5-Coder 1.5B Q4_K_M

No Gemini.
No OpenAI Cloud.

## Environment Variables

Set these in Railway:

AIVEN_OPENSEARCH_PASSWORD

Optional:

LOCAL_LLM_URL=http://127.0.0.1:8080

LOCAL_LLM_MODEL=local-model

LLAMA_CONTEXT_SIZE=2048

LLAMA_THREADS=2

## API

GET /

GET /health

GET /stats

POST /chat

Example:

POST /chat

{
  "question": "What is HTML?"
}

## Local testing

Install dependencies:

pip install -r requirements.txt

Run:

uvicorn api:app --host 0.0.0.0 --port 8000

## Railway

Railway automatically detects the Dockerfile.

The Docker container:

1. Builds llama.cpp.
2. Downloads Qwen2.5-Coder.
3. Starts llama-server.
4. Starts the FastAPI API.
5. Connects to Aiven OpenSearch.

## Security

Never commit:

- Aiven passwords
- API keys
- Railway tokens
- GGUF model files
- .env files
