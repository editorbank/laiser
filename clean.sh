docker rm -f lais >/dev/null 2>&1 || true
docker rmi -f lais:1.0 >/dev/null 2>&1 || true
[ -f lais.tar.gz ] && rm -rf lais.tar.gz