docker rm -f aais >/dev/null 2>&1 || true
docker rmi -f aais:1.0 >/dev/null 2>&1 || true
[ -f aais.tar.gz ] rm -rf aais.tar.gz