# Usage: measure.sh <target> [<duration>]

PROGNAME=$(basename $0)
BASEDIR=$(cd $(dirname $0); pwd)

# Use Node.js v12.
#
# aribts doesn't work properly with Node.js v13 or newer due to an incompatible behavior
# regarding `stream.Transform._flush()`.
#
# See https://github.com/nodejs/node/issues/31630 for details.
NODE_IMAGE='node:12-buster-slim'

if [ "$(uname)" != Linux ] || id -nG | grep -q docker; then
  DOCKER='docker'
else
  DOCKER='sudo docker'
fi

TARGET="$1"
DURATION="$2"

CPU_EXPR='round(100 * (1 - avg(irate(node_cpu_seconds_total{mode="idle"}[1m]))))'
MEMORY_EXPR='round((node_memory_MemTotal_bytes - (node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes)) / 1000000)'
LOAD1_EXPR='round(node_load1 * 100) / 100'
TX_EXPR='round((irate(node_network_transmit_bytes_total{device=~"^eth.*|^en.*"}[1m]) * 8) / 1000000)'
RX_EXPR='round((irate(node_network_receive_bytes_total{device=~"^eth.*|^en.*"}[1m]) * 8) / 1000000)'

NODE="$DOCKER run --rm -i -v $BASEDIR/perf-metrics:$BASEDIR/perf-metrics --network host $NODE_IMAGE node"

stream() {
  $NODE $BASEDIR/perf-metrics stream "$TARGET" "$DURATION"
}

system() {
  $NODE $BASEDIR/perf-metrics system "$1" "$2"
}

cpu() {
  system cpu "$CPU_EXPR"
}

memory() {
  system memory "$MEMORY_EXPR"
}

load1() {
  system load1 "$LOAD1_EXPR"
}

tx() {
  system tx "$TX_EXPR"
}

rx() {
  system rx "$RX_EXPR"
}

summary() {
  $NODE $BASEDIR/perf-metrics summary
}

graph_url() {
  $NODE $BASEDIR/perf-metrics prom-graph-url
}

# install modules
$DOCKER run --rm -i -v $BASEDIR/perf-metrics:$BASEDIR/perf-metrics --network host -w $BASEDIR/perf-metrics $NODE_IMAGE npm i

stream | cpu | memory | load1 | tx | rx | summary | graph_url
