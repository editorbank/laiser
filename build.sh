#build.sh
set -e


if docker image inspect lais:1.0 >/dev/null 2>&1; then
    echo "Image lais:1.0 already exists."
else
    echo Build image lais:1.0 ...
    docker build -t lais:1.0 .
fi


if [ "$(docker inspect -f '{{.State.Running}}' lais 2>/dev/null)" = "true" ]; then
    echo "Container lais already running"
else
    echo Run container lais ...
    docker rm -f lais >/dev/null 2>&1 || true
    docker run -d -p 8080:8080 --user 11111 --name lais lais:1.0
fi

echo Waiting for server ready ...
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

echo Testing ...
. ./test.sh

echo Done.