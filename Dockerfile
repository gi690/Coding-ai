FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apt-get update && \
    apt-get install -y \
        git \
        cmake \
        build-essential \
        curl \
        ca-certificates \
        libopenblas-dev \
        && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

RUN git clone \
    --depth 1 \
    https://github.com/ggml-org/llama.cpp.git \
    /app/llama.cpp

RUN cmake \
    -S /app/llama.cpp \
    -B /app/llama.cpp/build \
    -DGGML_NATIVE=OFF \
    -DGGML_BLAS=ON \
    -DGGML_BLAS_VENDOR=OpenBLAS \
    -DLLAMA_BUILD_SERVER=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=ON

RUN cmake \
    --build /app/llama.cpp/build \
    --config Release \
    -j2

COPY coding_ai.py .
COPY api.py .
COPY start.sh .

RUN chmod +x start.sh

RUN mkdir -p /app/models

EXPOSE 8000

CMD ["./start.sh"]