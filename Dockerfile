FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PORT=8080

WORKDIR /app

# System dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    libopenblas-dev \
    libomp-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY requirements.txt .
COPY coding_ai.py .
COPY api.py .
COPY start.sh .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Clone llama.cpp
RUN git clone --depth 1 https://github.com/ggml-org/llama.cpp.git /app/llama.cpp

# Build llama.cpp server
RUN cmake \
    -S /app/llama.cpp \
    -B /app/llama.cpp/build \
    -DGGML_NATIVE=OFF \
    -DGGML_BLAS=ON \
    -DGGML_BLAS_VENDOR=OpenBLAS \
    -DLLAMA_BUILD_SERVER=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=ON \
    -DCMAKE_BUILD_TYPE=Release

RUN cmake --build /app/llama.cpp/build --config Release -j2

# Make server available in PATH
ENV PATH="/app/llama.cpp/build/bin:${PATH}"

RUN chmod +x /app/start.sh

EXPOSE 8080

CMD ["./start.sh"]
