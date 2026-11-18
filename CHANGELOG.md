# Changelog

История изменений проекта LAISER. Формат основан на Keep a Changelog, версии следуют Semantic Versioning.

## [1.1] - 2026-11-18

### Added

- `CHANGELOG.md` — файл истории изменений.
- Build-аргументы `SERVICE_NAME`, `SERVICE_VERSION` и `MODEL_ALIAS` в `build.sh`: значения передаются в сборку из `config.properties`.

### Changed

- Запуск сервера переведён на `ENTRYPOINT ["llama-server"]` с конфигурацией через переменные окружения `LLAMA_ARG_*` вместо shell-обёртки в `CMD`.
- В образе создаётся пользователь `${SERVICE_NAME}` (UID 10001), используемый по умолчанию; скрипты продолжают запускать контейнер от `TEST_USER_ID`.
- Значение `MAX_TOKENS` по умолчанию в `Dockerfile` изменено на `32768` (при сборке переопределяется из `config.properties`); удалены OCI-метки образа.
- `README.md` и `CHANGELOG.md` актуализированы под текущую конфигурацию образа и скриптов.
- Модель заменена с `Qwen2.5-3B-Instruct Q4_K_M` на `Qwen3-4B-Instruct-2507 Q4_K_M` (`unsloth/Qwen3-4B-Instruct-2507-GGUF`).
- Обновлены `MODEL_SHA256` и алиас модели в API: `qwen2.5-3b-instruct` → `default`.
- Версия сервиса увеличена до `1.1` (тег `editorbank/laiser:1.1`).
- Значения по умолчанию в `Dockerfile` заменены на параметры сборки; описание и лицензии образа обновлены.
- `README.md` актуализирован: версия llama.cpp, характеристики модели, контекст, UID запуска, build-аргументы и порядок пересборки.
- `.gitignore` дополнен игнорированием скрытых файлов и каталогов (кроме `.git*`).

## [1.0] - 2026-11-16

### Added

- Самодостаточный Docker-образ с `llama.cpp` (`llama-server`, v1.0.0) и GGUF-моделью `Qwen2.5-3B-Instruct Q4_K_M` с проверкой SHA-256 при сборке.
- OpenAI-совместимые эндпоинты `/v1/models` и `/v1/chat/completions`, healthcheck `/health`.
- Конфигурация через `config.properties` и скрипты `build.sh`, `save.sh`, `load.sh`, `ask.sh`, `test.sh`, `clean.sh`, `push.sh`, `pull.sh`.
- Документация по сборке, развёртыванию, публикации образа и использованию API.
