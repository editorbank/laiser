set -e

echo Save image ...
[ -f lais.tar.gz ] || docker save lais:1.0 | gzip > lais.tar.gz

echo Done.