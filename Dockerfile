# syntax=docker/dockerfile:1.7

FROM ubuntu:24.04 AS llama-build

ARG LLAMA_CPP_VERSION=v1.0.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${LLAMA_CPP_VERSION}" \
        https://github.com/ggml-org/llama.cpp.git /src

RUN cmake -S /src -B /src/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DGGML_NATIVE=OFF \
        -DGGML_OPENMP=ON \
        -DLLAMA_OPENSSL=OFF \
        -DLLAMA_BUILD_TESTS=OFF \
        -DLLAMA_BUILD_EXAMPLES=OFF \
        -DLLAMA_BUILD_APP=OFF \
        -DLLAMA_BUILD_SERVER=ON \
        -DLLAMA_TOOLS_INSTALL=ON \
    && cmake --build /src/build --target llama-server -j"$(nproc)" \
    && test -x /src/build/bin/llama-server

FROM ubuntu:24.04 AS model

ARG MODEL_REPO=Qwen/Qwen2.5-3B-Instruct-GGUF
ARG MODEL_FILE=qwen2.5-3b-instruct-q4_k_m.gguf
ARG MODEL_SHA256=626b4a6678b86442240e33df819e00132d3ba7dddfe1cdc4fbb18e0a9615c62d

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /models \
    && curl -fL --retry 5 --retry-delay 5 \
        -o /models/model.gguf \
        "https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_FILE}" \
    && echo "${MODEL_SHA256}  /models/model.gguf" | sha256sum -c -

FROM ubuntu:24.04

LABEL org.opencontainers.image.title="lais-server" \
      org.opencontainers.image.description="Self-contained llama.cpp OpenAI-compatible server with Qwen2.5-3B-Instruct Q4_K_M" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    MODEL_PATH=/models/model.gguf \
    MODEL_ALIAS=qwen2.5-3b-instruct

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libgomp1 \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --create-home --home-dir /home/llama llama \
    && mkdir -p /models

COPY --from=llama-build /src/build/bin/llama-server /usr/local/bin/llama-server
COPY --from=model --chown=root:root /models/model.gguf /models/model.gguf

USER llama

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
    CMD ["curl", "-fsS", "http://127.0.0.1:8080/health"]

ENTRYPOINT ["llama-server"]
CMD ["-m", "/models/model.gguf", \
     "--alias", "qwen2.5-3b-instruct", \
     "--host", "0.0.0.0", \
     "--port", "8080", \
     "-c", "4096", \
     "--jinja", \
     "--metrics"]
