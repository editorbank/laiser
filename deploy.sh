#deploy.sh
docker load < aais.tar.gz
curl --compressed http://localhost:8080/v1/models
