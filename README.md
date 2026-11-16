# LAIS — Local Artificial Intelligence Service

LAIS — это самодостаточный Docker-образ с локальным LLM-сервером на базе [llama.cpp](https://github.com/ggml-org/llama.cpp) и моделью **Qwen2.5-3B-Instruct (Q4_K_M)**.

Образ поднимает OpenAI-совместимый API-сервер (`llama-server`) на порту `8080`. Модель и сервер уже включены в образ — в среде выполнения интернет не нужен.

## Что внутри

- **Базовый образ:** `ubuntu:24.04`
- **Сервер:** `llama.cpp` v1.0.0 (статическая сборка, CPU, OpenMP)
- **Модель:** `qwen2.5-3b-instruct-q4_k_m.gguf` (проверяется по SHA-256 при сборке)
- **API:** `http://localhost:8080/v1/...` (совместим с OpenAI Chat Completions)
- **Healthcheck:** `GET /health`
- **Пользователь в контейнере:** non-root

## Требования

- Docker
- `curl` и `jq` — для скриптов `load.sh`, `ask.sh`, `test.sh`
- Доступ в интернет — **только на этапе сборки** (скачивание исходников llama.cpp и модели)

## Быстрый старт (сборка → перенос → запуск)

### 1. Сборка и упаковка (на машине с интернетом)

```bash
./build.sh
./save.sh
```

- `build.sh` — собирает образ `lais:1.0`, запускает контейнер `lais`, ждёт готовности и прогоняет `test.sh`.
- `save.sh` — сохраняет образ в файл `lais.tar.gz` для переноса.

Перенесите `lais.tar.gz` и скрипты (`load.sh`, `ask.sh`, при необходимости `test.sh`) на целевой хост.

### 2. Развёртывание (на изолированном хосте)

```bash
./load.sh
./ask.sh "Число Пи c точностью 6 знаков после десятичной точки"
```

- `load.sh` — загружает `lais.tar.gz` (если образ ещё не загружен), запускает контейнер `lais` и выводит список моделей.
- `ask.sh` — отправляет запрос в `/v1/chat/completions` и печатает ответ.

## Скрипты

| Скрипт | Назначение |
|---|---|
| `build.sh` | Сборка образа, запуск контейнера, ожидание готовности, тесты |
| `save.sh` | Сохранение образа `lais:1.0` в `lais.tar.gz` |
| `load.sh` | Загрузка образа из `lais.tar.gz`, запуск контейнера, вывод списка моделей |
| `ask.sh` | Отправка запроса к чат-API (`ask.sh "ваш вопрос"`) |
| `test.sh` | Проверки `/health`, `/v1/models` и chat completion |
| `clean.sh` | Удаление контейнера `lais`, образа `lais:1.0` и  файла `lais.tar.gz` |

## Использование API

Пример запроса к OpenAI-совместимому endpoint:

```bash
curl -s http://localhost:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen2.5-3b-instruct",
    "messages": [{"role": "user", "content": "Привет!"}],
    "max_tokens": 512,
    "temperature": 0
  }' | jq -r '.choices[0].message.content'
```

Переменные окружения для `ask.sh`: `BASE_URL` (по умолчанию `http://localhost:8080`), `MODEL` (`qwen2.5-3b-instruct`), `MAX_TOKENS` (`512`).

## Тестирование

```bash
./test.sh [-u BASE_URL] [-m MODEL] [-c CONTAINER] [-w WAIT_SECONDS]
```

Проверяет доступность `/health`, наличие модели в `/v1/models` и корректность ответа `/v1/chat/completions`. При запуске с `-c <container>` проверки выполняются внутри контейнера (полезно для режима `--network none`).
