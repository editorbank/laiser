set -e

echo Save image ...
[ -f aais.tar.gz ] || docker save aais:1.0 | gzip > aais.tar.gz

echo Done.