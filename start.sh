#!/bin/sh

set -e

MODEL_DIR="/app/models"
MODEL="$MODEL_DIR/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"

mkdir -p "$MODEL_DIR"

echo "=============================================="
echo "        CODING AI - RAILWAY START"
echo "=============================================="

echo "Checking llama-server..."

if [ ! -x "/app/llama.cpp/build/bin/llama-server" ]; then
    echo "ERROR: llama-server not found."
    exit 1
fi

echo "Checking model..."

if [ ! -f "$MODEL" ]; then

    echo "Downloading Qwen2.5-Coder 1.5B Q4_K_M..."

    curl -L \
        --fail \
        --retry 5 \
        --retry-delay 5 \
        -o "$MODEL" \
        "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"

fi

echo "Starting local LLM..."

/app/llama.cpp/build/bin/llama-server \
    -m "$MODEL" \
    -c "${LLAMA_CONTEXT_SIZE:-2048}" \
    --host 127.0.0.1 \
    --port 8080 \
    --threads "${LLAMA_THREADS:-2}" \
    --parallel 1 \
    > /tmp/llama.log 2>&1 &

LLAMA_PID=$!

echo "llama-server PID: $LLAMA_PID"

echo "Waiting for llama-server..."

READY=0

for i in $(seq 1 60); do

    if curl -fsS \
        "http://127.0.0.1:8080/health" \
        >/dev/null 2>&1; then

        READY=1
        echo "✓ Local LLM ready"
        break

    fi

    if ! kill -0 "$LLAMA_PID" 2>/dev/null; then

        echo "ERROR: llama-server stopped."

        echo "----- llama-server log -----"
        cat /tmp/llama.log
        echo "----------------------------"

        exit 1
    fi

    sleep 2

done

if [ "$READY" -ne 1 ]; then

    echo "ERROR: llama-server did not become ready."

    echo "----- llama-server log -----"
    cat /tmp/llama.log
    echo "----------------------------"

    exit 1
fi

echo "Starting Coding AI API..."

exec uvicorn api:app \
    --host 0.0.0.0 \
    --port "${PORT:-8000}"