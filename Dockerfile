# syntax=docker/dockerfile:1.7

ARG FROM_IMAGE=ubuntu:24.04

########################
FROM ${FROM_IMAGE} AS llama-build

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
        -DLLAMA_BUILD_UI=OFF \
        -DLLAMA_USE_PREBUILT_UI=OFF \
    && cmake --build /src/build --target llama-server -j"$(nproc)" \
    && test -x /src/build/bin/llama-server

########################
FROM ${FROM_IMAGE} AS model

ARG SERVICE_NAME=laiser
ARG SERVICE_VERSION=0.0.0
ARG MODEL_REPO=Qwen/model
ARG MODEL_FILE=model.gguf
ARG MODEL_SHA256=0000000000000000000000000000000000000000000000000000000000000000
ARG MODEL_ALIAS=default

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /models \
    && curl -fL --retry 5 --retry-delay 5 \
        -o /models/${MODEL_FILE} \
        "https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_FILE}" \
    && echo "${MODEL_SHA256}  /models/${MODEL_FILE}" | sha256sum -c -

########################
FROM ${FROM_IMAGE}

ARG SERVICE_NAME=laiser
ARG SERVICE_VERSION=0.0.0
ARG SERVICE_PORT=8080
ARG MODEL_FILE=model.gguf
ARG MODEL_ALIAS=default
ARG MAX_TOKENS=4096


LABEL org.opencontainers.image.title="${SERVICE_NAME}" \
      org.opencontainers.image.description="Self-contained llama.cpp OpenAI-compatible server" \
      org.opencontainers.image.version="${SERVICE_VERSION}" \
      org.opencontainers.image.licenses="MIT + Apache 2.0"

ENV DEBIAN_FRONTEND=noninteractive \
    MODEL_PATH=/models/${MODEL_FILE} \
    MODEL_ALIAS=${MODEL_ALIAS} \
    SERVICE_PORT=${SERVICE_PORT} \
    MAX_TOKENS=${MAX_TOKENS}

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
COPY --from=model --chown=root:root /models/${MODEL_FILE} /models/${MODEL_FILE}

USER ${SERVICE_NAME}

EXPOSE ${SERVICE_PORT}

HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${SERVICE_PORT}/health"

# ENTRYPOINT ["llama-server"]
CMD ["sh", "-c", "exec llama-server -m \"$MODEL_PATH\" --alias \"$MODEL_ALIAS\" --host 0.0.0.0 --port \"$SERVICE_PORT\" -c \"$MAX_TOKENS\" --jinja --metrics"]
