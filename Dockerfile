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

ARG SERVICE_NAME=laiser \
    SERVICE_VERSION=0.0.0 \
    SERVICE_PORT=8080 \
    SERVICE_USER_ID=10001 \
    MODEL_FILE=model.gguf \
    MODEL_ALIAS=default \
    MAX_TOKENS=32768

ENV DEBIAN_FRONTEND=noninteractive \
    LLAMA_ARG_ALIAS=${MODEL_ALIAS} \
    LLAMA_ARG_MODEL=/models/${MODEL_FILE} \
    LLAMA_ARG_THREADS=4 \
    LLAMA_ARG_N_GPU_LAYERS=0 \
    LLAMA_ARG_CTX_SIZE=${MAX_TOKENS} \
    LLAMA_ARG_FLASH_ATTN=1 \
    LLAMA_ARG_CACHE_TYPE_K=q8_0 \
    LLAMA_ARG_CACHE_TYPE_V=q8_0 \
    LLAMA_ARG_JINJA=1 \
    LLAMA_ARG_METRICS=1 \
    LLAMA_ARG_HOST=0.0.0.0 \
    LLAMA_ARG_PORT=${SERVICE_PORT}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libgomp1 \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid ${SERVICE_USER_ID} --create-home --home-dir /home/${SERVICE_NAME} ${SERVICE_NAME} \
    && mkdir -p /models

COPY --from=llama-build /src/build/bin/llama-server /usr/local/bin/llama-server
COPY --from=model --chown=root:root /models/${MODEL_FILE} /models/${MODEL_FILE}

USER ${SERVICE_NAME}

EXPOSE ${LLAMA_ARG_PORT}

HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${LLAMA_ARG_PORT}/health"

ENTRYPOINT ["llama-server"]
# CMD ["sh", "-c", "exec llama-server"]
