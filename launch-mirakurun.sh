PROGNAME="$(basename $0)"

CLEAN=
UPSTREAM_IPADDR=
TZ=Asia/Tokyo

help() {
    cat <<EOF >&2
USAGE:
  $PROGNAME [-c | --clean] <upstream> [<tz>]
  $PROGNAME -h | --help

OPTIONS:
  -h, --help
    Show help.

  -c, --clean
    Remove docker images.

ARGUMENTS:
  <upstream>
    IP address of upstream server.

  <tz>  [default: $TZ]
    Timezone.
EOF
    exit 0
}

while [ $# -gt 0 ]
do
  case "$1" in
    '-h' | '--help')
      help
      ;;
    '-c' | '--clean')
      CLEAN=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [ -z "$1" ]
then
  echo 'ERROR: <upstream> is required'
  exit 1
fi
UPSTREAM_IPADDR="$1"

if [ -n "$2" ]
then
  TZ="$2"
fi

BASEURL=https://raw.githubusercontent.com/mirakc/performance-measurements/main
WORKDIR=

if [ "$(uname)" != Linux ] || id -nG | grep -q docker; then
  DOCKER='docker'
else
  DOCKER='sudo docker'
fi

if [ "$(uname)" != Linux ] || id -nG | grep -q docker; then
  DOCKER_COMPOSE='docker-compose'
else
  DOCKER_COMPOSE='sudo docker-compose'
fi

clean() {
  if [ -f $WORKDIR/docker-compose.yml ]
  then
    $DOCKER_COMPOSE -f $WORKDIR/docker-compose.yml down -v
  fi
  if [ -d $WORKDIR ]
  then
    rm -rf $WORKDIR
  fi
  if [ -n "$CLEAN" ]
  then
    $DOCKER image rm -f chinachu/mirakurun:latest >/dev/null >/dev/null
    $DOCKER image rm -f prom/node-exporter:latest >/dev/null >/dev/null
  fi
}

WORKDIR=$(mktemp -d)
trap 'clean' EXIT INT TERM

mkdir -p $WORKDIR/config
curl -fsSL $BASEURL/docker/mirakurun/config/channels.yml >$WORKDIR/config/channels.yml
curl -fsSL $BASEURL/docker/mirakurun/config/server.yml >$WORKDIR/config/server.yml
curl -fsSL $BASEURL/docker/mirakurun/config/tuners.yml >$WORKDIR/config/tuners.yml
curl -fsSL $BASEURL/docker/mirakurun/run.sh >$WORKDIR/run.sh
curl -fsSL $BASEURL/docker/mirakurun/docker-compose.yml >$WORKDIR/docker-compose.yml

cat <<EOF >$WORKDIR/.env
UPSTREAM_IPADDR='$UPSTREAM_IPADDR'
TZ='$TZ'
EOF

$DOCKER_COMPOSE -f $WORKDIR/docker-compose.yml up
