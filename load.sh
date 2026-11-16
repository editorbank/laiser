#load.sh
set -e

if docker image inspect aais:1.0 >/dev/null 2>&1; then
    echo "Image aais:1.0 already loaded"
elif [ -f aais.tar.gz ]; then
    docker load < aais.tar.gz
else
    echo "aais.tar.gz not found and image aais:1.0 is not loaded"
    exit 1
fi

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

echo Loaded models:
curl --compressed -fs http://localhost:8080/v1/models | jq .models[].name
