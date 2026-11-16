#deploy.sh
docker load < offline-llama.tar.gz
curl http://localhost:8080/v1/models
