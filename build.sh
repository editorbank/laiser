#build.sh
set -e -x

echo Make image ...
docker build -t aais:1.0 .

echo Run image ...
docker run -d --network none -p 8080:8080 --name aais aais:1.0

curl http://localhost:8080/health
curl --compressed http://localhost:8080/v1/models
#docker save aais:1.0 | gzip > aais.tar.gz
