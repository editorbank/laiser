#build.sh
set -e -x

echo Make image ...
docker build -t offline-llama:1.0 .

echo Run image ...
docker run -d --network none -p 8080:8080 --name llama offline-llama:1.0

curl http://localhost:8080/health
curl --compressed http://localhost:8080/v1/models
#docker save offline-llama:1.0 | gzip > offline-llama.tar.gz
