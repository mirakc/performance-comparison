# Performance measurements of tuner servers

The performance metrics described in
[this page](https://github.com/mirakc/mirakc#8-ts-streams-at-the-same-time) were collected by
using the following command executed on a local PC:

```console
$ sh measure.sh http://target:40772 10m >/dev/null
Reading TS packets from ex...
Reading TS packets from ntv...
Reading TS packets from etv...
Reading TS packets from nhk...
Reading TS packets from bs1...
Reading TS packets from bsp...
Reading TS packets from bs-ntv...
Reading TS packets from bs-ex...
CHANNEL  #BYTES      #PACKETS  #DROPS
-------  ----------  --------  ------
ex       1140965376  6068964   0
ntv      1195360256  6358299   0
etv      1131560960  6018941   0
nhk      1103233024  5868260   0
bs1      1174650880  6248142   0
bsp      1115684864  5934493   0
bs-ntv   887750656   4722077   0
bs-ex    1125695488  5987741   0

NAME    BASE  MIN   MAX   MIN+  MAX+
------  ----  ----  ----  ----  ----
cpu     1     45    48    44    47
memory  301   311   313   10    12
load1   0     0.93  2.45  0.93  2.45
tx      0     118   134   118   134
rx      0     154   154   154   154

http://localhost:9090/graph?<query parameters for showing metrics>
```

## Results

mirakc/1.0.0 (Debian):

```
NAME    BASE  MIN   MAX   MIN+  MAX+
------  ----  ----  ----  ----  ----
cpu     1     46    47    45    46
memory  288   309   310   21    22
load1   0     1.65  2.43  1.65  2.43
tx      0     131   136   131   136
rx      0     153   154   153   154
```

mirakc/1.0.0 (Apline):

```
NAME    BASE  MIN   MAX   MIN+  MAX+
------  ----  ----  ----  ----  ----
cpu     1     45    48    44    47
memory  301   311   313   10    12
load1   0     0.93  2.45  0.93  2.45
tx      0     118   134   118   134
rx      0     154   154   154   154
```

Mirakurun/3.6.0:

```
NAME    BASE  MIN   MAX   MIN+  MAX+
------  ----  ----  ----  ----  ----
cpu     1     52    55    51    54
memory  400   1027  3186  627   2786
load1   0     1.76  2.61  1.76  2.61
tx      0     88    107   88    107
rx      0     152   153   152   153
```

## Environment

Target Server:

* ROCK64 (DRAM: 4GB)
  * [Armbian] 21.05.6 Buster
  * Linux 5.10.43-rockchip64
  * Mirakurun requires memory larger than 1GB for performance measurements
* Receive TS packets from the upstream server by using `curl`
* `cat` is used as a decoder
* Default `server.workers` (4 = the number of CPU cores)
* `MALLOC_ARENA_MAX=2`

Upstream Server:

* ROCK64 (DRAM: 1GB)
  * [Armbian] 21.05.6 Buster
  * Linux 5.10.43-rockchip64
* mirakc/mirakc:main-alpine
* PLEX PX-Q3U4

Docker Engine:

* 20.10.7

## How to collect performance metrics

Create `docker/prometheus/.env`:

```shell
# Replace with the IP address of your target machine.
TARGET_IPADDR=192.168.1.23

cat <<EOF >docker/prometheus/.env
TARGET_IPADDR=$TARGET_IPADDR
TZ=Asia/Tokyo
EOF
```

Launch a Prometheus server on the local PC:

```shell
docker-compose -f docker/prometheus/docker-compose.yml up -d
```

Launch a target server on the target machine:

```shell
BASEURL=https://raw.githubusercontent.com/mirakc/performance-measurements/main

# Replace with the IP address of your Mirakurun-compatible upstream server.
UPSTREAM=192.168.2.34

# mirakc-alpine
curl -fsSL $BASEURL/launch-mirakc-alpine.sh | sh -s -- -c --alpine $UPSTREAM

# mirakc-debian
curl -fsSL $BASEURL/launch-mirakc-debian.sh | sh -s -- -c $UPSTREAM

# mirakurun
curl -fsSL $BASEURL/launch-mirakurun.sh | sh -s -- -c $UPSTREAM
```

Wait several minutes for the target server to go steady, then execute:

```shell
# mirakc-alpine
sh measure.sh http://target:40772 10m >/dev/null

# mirakc-debian
sh measure.sh http://target:40773 10m >/dev/null

# mirakurun
sh measure.sh http://target:40774 10m >/dev/null
```

The command above performs:

* Receiving TS streams from 4 GR and 4 BS services for 10 minutes
* Collecting system metrics by using [Prometheus] and [node_exporter]
* Counting the number of dropped TS packets by using [node-aribts]

Several hundreds or thousands of dropped packets were sometimes detected during the performance
measurement.  The same situation also occurred in Mirakurun.

[Armbian]: https://www.armbian.com/rock64/
[Prometheus]: https://prometheus.io/
[node_exporter]: https://github.com/prometheus/node_exporter
[node-aribts]: https://www.npmjs.com/package/aribts
