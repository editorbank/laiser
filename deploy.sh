#deploy.sh
set -e -x

docker load < aais.tar.gz

if [ "$(docker inspect -f '{{.State.Running}}' aais 2>/dev/null)" = "true" ]; then
    echo "Container aais already running"
else
    docker rm -f aais >/dev/null 2>&1 || true
    docker run -d -p 8080:8080 --user 11111 --name aais aais:1.0
fi

echo Waiting for server ...
ready=0
for i in $(seq 1 30); do
    if curl -sf http://localhost:8080/health >/dev/null; then
        ready=1
        break
    fi
    sleep 1
done
if [ "$ready" -ne 1 ]; then
    echo "Server did not become ready within 30 seconds"
    exit 1
fi

curl --compressed http://localhost:8080/v1/models
