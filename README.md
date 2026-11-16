# AAIS - Autonomous Artificial Intelligence Service


Dockerfile: ubuntu:24.04 + llama.cpp v1.0.0 + Qwen2.5-3B-Instruct Q4_K_M, статическая сборка, CPU, non-root, healthcheck.

## 1.Сборка
 на машине с интернетом выполнить
```bash
#build.sh
docker build -t aais:1.0 .
docker run -d -p 8080:8080 --name aais aais:1.0
curl --compressed http://localhost:8080/v1/models
docker save aais:1.0 | gzip > aais.tar.gz
```
## 2.Развёртывание
В рантайм среде на изолированном от сети хосте выполнить загрузку образа в offline doccker и протестировать работоспособность
```bash
#deploy.sh
docker load < aais.tar.gz
curl --compressed http://localhost:8080/v1/models
```
Интернет нужен только на этапе сборки (код llama.cpp и модель скачиваются и проверяются по SHA-256); в рантайме сеть не требуется.