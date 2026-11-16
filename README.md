# Offline AI server

Dockerfile:1 — llama.cpp v1.0.0 + Qwen2.5-3B-Instruct Q4_K_M, статическая сборка, CPU, non-root, healthcheck.
Сборка и запуск с --network none проверены: чат-запрос вернул OK.
Generated OpenCode. 

1. на машине с интернетом выполнить
```bash
#build.sh
docker build -t offline-llama:1.0 .
docker run -d --network none -p 8080:8080 --name llama offline-llama:1.0
curl http://localhost:8080/v1/models
docker save offline-llama:1.0 | gzip > offline-llama.tar.gz
```
2. В рантайм среде на изолированном от сети хосте выполнить загрузку образа в offline doccker и протестировать работоспособность
```bash
#deploy.sh
docker load < offline-llama.tar.gz
curl http://localhost:8080/v1/models
```
Интернет нужен только на этапе сборки (код llama.cpp и модель скачиваются и проверяются по SHA-256); в рантайме сеть не требуется.