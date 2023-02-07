PROGNAME="$(basename $0)"
BASEDIR=$(cd $(dirname $0); pwd)

BASEURL=https://raw.githubusercontent.com/mirakc/performance-measurements/main

DOCKER='docker'

if which docker-compose >/dev/null 2>&1
then
  DOCKER_COMPOSE='docker-compose'
else
  DOCKER_COMPOSE='docker compose'
fi

if [ "$(uname)" != Linux ] || id -nG | grep -q docker
then
  DOCKER="$DOCKER"
  DOCKER_COMPOSE="$DOCKER_COMPOSE"
else
  DOCKER="sudo $DOCKER"
  DOCKER_COMPOSE="sudo $DOCKER_COMPOSE"
fi

UPSTREAM_IPADDR=
TZ=Asia/Tokyo

help() {
    cat <<EOF >&2
USAGE:
  $PROGNAME [options] setup <upstream-ipaddr> [<tz>]
  $PROGNAME [options] up [<containers>...]
  $PROGNAME [options] down [<containers>...]
  $PROGNAME [options] clean
  $PROGNAME [options] clean-all
  $PROGNAME -h | --help

OPTIONS:
  -h, --help
    Show help.

  -r, --remote
    SSH remote host.

COMMANDS:
  setup
    Setup a remote environment for performance measurements.

    Create the "\$HOME/mirakc-perf" holder in the remote machine and copy files
    from this repository.

  up
    Create and start containers.

    Start all containers if no <containers> are specified.

  down
    Stop and remove containers.

    Stop all containers if no <containers> are specified.

  clean
    Cleanup.

    No Docker image will be removed.

  clean-all
    Cleanup and remove unused Docker images.

ARGUMENTS:
  <upstream-ipaddr>
    IP address of an upstream Mirakurun-compatible server listening on 40772 TCP
    port.

  <tz>  [default: $TZ]
    Timezone.

  <containers>
    The following containers are defiend in the docker-compose.yml:

      * mirakc-alpine
      * mirakc-debian
      * mirakurun
EOF
    exit 0
}

setup() {
  UPSTREAM_IPADDR=$1
  if [ -n "$2" ]
  then
    TZ="$2"
  fi

  echo 'INFO: Copying files...'
  scp -r $BASEDIR/docker $REMOTE:/tmp/mirakc-perf
  cat <<EOF | ssh $REMOTE sh -c 'cat >/tmp/mirakc-perf/.env'
UPSTREAM_IPADDR=$UPSTREAM_IPADDR
TZ=$TZ
EOF

  echo 'Pulling images...'
  ssh $REMOTE 'cd /tmp/mirakc-perf && docker compose pull -q'
  exit 0
}

up() {
  ssh $REMOTE "cd /tmp/mirakc-perf && docker compose up -d $@"
  exit 0
}

down() {
  ssh $REMOTE "cd /tmp/mirakc-perf && docker compose down -v $@"
  exit 0
}

clean() {
  ssh $REMOTE "cd /tmp/mirakc-perf && docker compose down -v"
  ssh $REMOTE "rm -rf /tmp/mirakc-perf"
  exit 0
}

clean_all() {
  ssh $REMOTE "cd /tmp/mirakc-perf && docker compose down -v"
  ssh $REMOTE "docker image prune -af"
  ssh $REMOTE "rm -rf /tmp/mirakc-perf"
  exit 0
}

while [ $# -gt 0 ]
do
  case "$1" in
    '-h' | '--help')
      help
      ;;
    '-r' | '--remote')
      REMOTE=$2
      shift 2
      ;;
    'setup')
      shift
      setup "$@"
      ;;
    'up')
      shift
      up "$@"
      ;;
    'down')
      shift
      down "$@"
      ;;
    'clean')
      shift
      clean
      ;;
    'clean-all')
      shift
      clean_all
      ;;
    *)
      help
      ;;
  esac
done
