# LAISER

LAISER (Local Artificial Intelligence SERvice) — локальный ИИ‑сервис для интеграции в пайплайны данных и аналитические процессы.
Это самодостаточный Docker-образ с локальным LLM-сервером на базе [llama.cpp](https://github.com/ggml-org/llama.cpp) и моделью **Qwen3-4B-Instruct-2507 (Q4_K_M)**.
Образ поднимает OpenAI‑совместимый API-сервер (`llama-server`): модель и сервер уже включены в образ, поэтому в среде выполнения интернет не нужен.
Готовый образ можно скачать с Docker Hub: [editorbank/laiser](https://hub.docker.com/r/editorbank/laiser).
История изменений приведена в [CHANGELOG.md](CHANGELOG.md).

## Что внутри

- **Базовый образ:** `ubuntu:24.04` (настраивается в `config.properties`)
- **Сервер:** `llama.cpp` `v1.0.0` (статическая сборка, CPU, OpenMP), настраивается через переменные `LLAMA_ARG_*` (Jinja, метрики, контекст, кэш и др.)
- **Модель:** `Qwen/Qwen3-4B-Instruct-2507` (GGUF-квантование `Q4_K_M` из `unsloth/Qwen3-4B-Instruct-2507-GGUF`), файл `Qwen3-4B-Instruct-2507-Q4_K_M.gguf` (~2,5 ГБ); SHA-256 проверяется при сборке
- **Алиас модели в API:** `default` (задаётся в `config.properties`)
- **Версия образа:** `1.1`
- **Контекст:** 32768 токенов по умолчанию (`MAX_TOKENS` в `config.properties`, передаётся в `LLAMA_ARG_CTX_SIZE`)
- **API:** `GET /health`, `GET /v1/models`, `POST /v1/chat/completions`
- **Права:** в образе создаётся пользователь сервиса (UID 10001); скрипты запускают контейнер от `TEST_USER_ID` (по умолчанию `11111`)

## Требования

- Docker
- `curl` и `jq` — для скриптов `load.sh`, `ask.sh`, `test.sh`
- Доступ в интернет — **только на этапе сборки** (скачивание исходников llama.cpp и модели)
- Учётные данные Docker-реестра — только для `push.sh` / `pull.sh`

## Конфигурация

Параметры задаются в `config.properties` и используются всеми скриптами:

- `SERVICE_OWNER`, `SERVICE_NAME`, `SERVICE_VERSION`, `SERVICE_PORT` — владелец/имя/версия образа (`<SERVICE_OWNER>/<SERVICE_NAME>:<SERVICE_VERSION>`) и порт
- `IMAGE_HUB` — реестр для `docker login` при публикации (`push.sh`)
- `FROM_IMAGE` — базовый образ
- `LLAMA_CPP_VERSION`, `MODEL_REPO`, `MODEL_FILE`, `MODEL_SHA256` — параметры сборки
- `MODEL_ALIAS`, `MAX_TOKENS` — алиас модели в API, размер контекста сервера (`LLAMA_ARG_CTX_SIZE`) и лимит токенов для `ask.sh`
- `TEST_USER_ID` — UID пользователя, от которого запускается контейнер, не совпадает с SERVICE_USER_ID для эмитации случайного пользователя пром реде под которым может запуститься контейнер
- `SERVICE_USER_ID` — UID пользователя настройки сервиса

`SERVICE_NAME`, `SERVICE_VERSION`, `MODEL_ALIAS`, `MAX_TOKENS` и другие параметры передаются в сборку как build-аргументы (`build.sh`), поэтому конфигурация образа настраивается без правки `Dockerfile`. Параметры `llama-server` задаются через переменные `LLAMA_ARG_*` и могут быть переопределены при запуске контейнера (`docker run -e ...`).

Переменные окружения `BASE_URL` и `MODEL` имеют приоритет над значениями из `config.properties`. Для `test.sh` также доступны `CONTAINER`, `WAIT_SECONDS` и `MAX_TIME`.

> `build.sh` не пересобирает образ, если он уже существует с текущим тегом, а `save.sh` не перезаписывает существующий архив. После изменения `MODEL_*`, `LLAMA_CPP_VERSION` или других параметров сборки удалите старые артефакты (`./clean.sh`) и выполните сборку заново.

## Быстрый старт

### 1. Сборка и упаковка (на машине с интернетом)

```bash
./build.sh
./save.sh
```

- `build.sh` — собирает образ, запускает контейнер, ждёт готовности и запускает `test.sh`.
- `save.sh` — сохраняет образ в архив `<SERVICE_NAME>.tar.gz` (по умолчанию `laiser.tar.gz`).

Перенесите на целевой хост архив и скрипты: `config.properties`, `load.sh`, `ask.sh`, при необходимости `test.sh`.

Альтернативно образ можно опубликовать в реестр и забрать на целевом хосте:

```bash
./push.sh     # docker login $IMAGE_HUB и docker push
./pull.sh     # docker pull на целевой машине
```

### 2. Развёртывание (на изолированном хосте)

```bash
./load.sh
./ask.sh "Число Пи c точностью 6 знаков после десятичной точки"
```

- `load.sh` — загружает архив (если образ ещё не загружен), запускает контейнер и выводит список моделей.
- `ask.sh` — отправляет запрос в `/v1/chat/completions` и печатает ответ (лимит токенов ответа берётся из `MAX_TOKENS`).

Если образ получен через `pull.sh`, вместо `load.sh` достаточно запустить контейнер вручную или повторно выполнить `load.sh` — он определит, что образ уже загружен.

Для полностью изолированного запуска контейнер можно поднять с `--network none`; в этом случае проверки выполняются внутри контейнера:

```bash
./test.sh -c laiser -w 30
```

## Скрипты

| Скрипт | Назначение |
|---|---|
| `build.sh` | Сборка образа, запуск контейнера, ожидание готовности, тесты |
| `save.sh` | Сохранение образа в `<SERVICE_NAME>.tar.gz` |
| `load.sh` | Загрузка архива, запуск контейнера, вывод списка моделей |
| `pull.sh` | Загрузка образа из реестра (`docker pull`) |
| `push.sh` | Публикация образа в реестр (`docker login` + `docker push`) |
| `ask.sh` | Отправка запроса к чат-API (`ask.sh "ваш вопрос"`, при необходимости `MAX_TOKENS=...`) |
| `test.sh` | Проверки `/health`, `/v1/models` и chat completion |
| `clean.sh` | Удаление контейнера, образа и архива |

## Использование API

Пример запроса (порт и алиас берутся из `config.properties`, по умолчанию `8080` и `default`):

```bash
curl -s "http://localhost:${SERVICE_PORT}/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "'"${MODEL_ALIAS}"'",
    "messages": [{"role": "user", "content": "Привет!"}],
    "max_tokens": 4096,
    "temperature": 0
  }' | jq -r '.choices[0].message.content'
```

(подставьте значения из `config.properties` или используйте `ask.sh`)

## Тестирование

```bash
./test.sh [-u BASE_URL] [-m MODEL] [-c CONTAINER] [-w WAIT_SECONDS]
```

Проверяет `/health`, наличие модели в `/v1/models` и ответ `/v1/chat/completions`. С `-c <container>` проверки выполняются внутри контейнера (необходимо при `--network none`).
