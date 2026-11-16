# LAISER — Local Artificial Intelligence SERvice

laiser — это самодостаточный Docker-образ с локальным LLM-сервером на базе [llama.cpp](https://github.com/ggml-org/llama.cpp) и моделью **Qwen2.5-3B-Instruct (Q4_K_M)**.

Образ поднимает OpenAI-совместимый API-сервер (`llama-server`). Модель и сервер уже включены в образ — в среде выполнения интернет не нужен.

## Что внутри

- **Базовый образ:** `ubuntu:24.04` (настраивается в `config.properties`)
- **Сервер:** `llama.cpp` (статическая сборка, CPU, OpenMP)
- **Модель:** GGUF-модель из `config.properties` (проверяется по SHA-256 при сборке)
- **API:** OpenAI-совместимый endpoint `/v1/chat/completions`
- **Healthcheck:** `GET /health`
- **Пользователь в контейнере:** non-root

## Требования

- Docker
- `curl` и `jq` — для скриптов `load.sh`, `ask.sh`, `test.sh`
- Доступ в интернет — **только на этапе сборки** (скачивание исходников llama.cpp и модели)

## Конфигурация

Параметры задаются в `config.properties` и используются всеми скриптами:

- `SERVICE_NAME`, `SERVICE_VERSION`, `SERVICE_PORT` — имя/версия образа и порт
- `LLAMA_CPP_VERSION`, `MODEL_REPO`, `MODEL_FILE`, `MODEL_SHA256` — параметры сборки
- `MODEL_ALIAS`, `MAX_TOKENS` — модель и лимит токенов для запросов
- `TEST_USERID` — UID пользователя при запуске контейнера

Переменные окружения `BASE_URL`, `MODEL`, `MAX_TOKENS` (где применимо) имеют приоритет над значениями из `config.properties`.

## Быстрый старт

### 1. Сборка и упаковка (на машине с интернетом)

```bash
./build.sh
./save.sh
```

- `build.sh` — собирает образ, запускает контейнер, ждёт готовности и запускает `test.sh`.
- `save.sh` — сохраняет образ в архив `<SERVICE_NAME>.tar.gz` (по умолчанию `lais.tar.gz`).

Перенесите на целевой хост архив и скрипты: `config.properties`, `load.sh`, `ask.sh`, при необходимости `test.sh`.

### 2. Развёртывание (на изолированном хосте)

```bash
./load.sh
./ask.sh "Число Пи c точностью 6 знаков после десятичной точки"
```

- `load.sh` — загружает архив (если образ ещё не загружен), запускает контейнер и выводит список моделей.
- `ask.sh` — отправляет запрос в `/v1/chat/completions` и печатает ответ.

## Скрипты

| Скрипт | Назначение |
|---|---|
| `build.sh` | Сборка образа, запуск контейнера, ожидание готовности, тесты |
| `save.sh` | Сохранение образа в `<SERVICE_NAME>.tar.gz` |
| `load.sh` | Загрузка архива, запуск контейнера, вывод списка моделей |
| `ask.sh` | Отправка запроса к чат-API (`ask.sh "ваш вопрос"`) |
| `test.sh` | Проверки `/health`, `/v1/models` и chat completion |
| `clean.sh` | Удаление контейнера, образа и архива |

## Использование API

Пример запроса:

```bash
curl -s "http://localhost:${SERVICE_PORT}/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "'"${MODEL_ALIAS}"'",
    "messages": [{"role": "user", "content": "Привет!"}],
    "max_tokens": 512,
    "temperature": 0
  }' | jq -r '.choices[0].message.content'
```

(подставьте значения из `config.properties` или используйте `ask.sh`)

## Тестирование

```bash
./test.sh [-u BASE_URL] [-m MODEL] [-c CONTAINER] [-w WAIT_SECONDS]
```

Проверяет `/health`, наличие модели в `/v1/models` и ответ `/v1/chat/completions`. С `-c <container>` проверки выполняются внутри контейнера.
