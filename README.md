# Performance measurements of tuner servers

The performance metrics described in
[this page](https://github.com/mirakc/mirakc#8-ts-streams-at-the-same-time) were
collected by using the following command executed on a local PC:

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
ex       1150992384  6122299   0
ntv      1153122304  6133629   0
etv      1179140096  6272021   0
nhk      1140899840  6068616   0
bs1      1436811264  7642613   0
bsp      1294368768  6884940   0
bs-ntv   1149140992  6112452   0
bs-ex    1186283520  6310018   0

NAME    BASE  MIN   MAX   MIN+  MAX+
------  ----  ----  ----  ----  ----
cpu     2     28    30    26    28
memory  221   247   248   26    27
load1   0.33  0.92  2.14  0.59  1.81
tx      0     132   140   132   140
rx      0     155   155   155   155

http://localhost:9090/graph?<query parameters for showing metrics>
```

## Results

mirakc/2.0.0 (Apline):

```
NAME    BASE  MIN   MAX   MIN+  MAX+
------  ----  ----  ----  ----  ----
cpu     2     28    30    26    28
memory  221   247   248   26    27
load1   0.33  0.92  2.14  0.59  1.81
tx      0     132   140   132   140
rx      0     155   155   155   155
```

mirakc/2.0.0 (Debian):

```
NAME    BASE  MIN   MAX   MIN+  MAX+
------  ----  ----  ----  ----  ----
cpu     1     27    29    26    28
memory  226   252   253   26    27
load1   0.06  0.7   1.63  0.64  1.57
tx      0     125   135   125   135
rx      0     155   155   155   155
```

Mirakurun/3.9.0-rc.2:

```
NAME    BASE  MIN   MAX   MIN+  MAX+
------  ----  ----  ----  ----  ----
cpu     1     33    37    32    36
memory  299   411   420   112   121
load1   0.14  1.05  1.93  0.91  1.79
tx      0     122   136   122   136
rx      0     154   155   154   155
```

## Environment

Target Server:

* Raspberry Pi 4B (DRAM: 4GB)
  * [Raspberry Pi OS (64-bit)] Lite
  * Linux rpi 5.15.84-v8+
  * Make sure that `cgroup_memory=1 cgroup_enable=memory` is specified in
    `cmdline.txt`
    * See https://github.com/raspberrypi/Raspberry-Pi-OS-64bit/issues/124
* Receive TS packets from the upstream server by using `curl`
* `cat` is used as a decoder
* `MALLOC_ARENA_MAX=2`

Upstream Server:

* ROCK64 (DRAM: 1GB)
  * [Armbian] 22.11.4 Bullseye
  * Linux 5.15.89-rockchip64
* mirakc/mirakc:main-alpine
* PLEX PX-Q3U4

Docker Engine:

* 23.0.0

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
docker compose -f docker/prometheus/docker-compose.yml up -d
```

Setup a remote environment for performance measurements:

```shell
# Replace with the IP address of your Mirakurun-compatible upstream server.
UPSTREAM=192.168.2.34

sh remote.sh -r $TARGET_IPADDR setup $UPSTREAM
```

Perform measurement for each container:

```shell
# mirakc-alpine
sh remote.sh -r $TARGET_IPADDR up mirakc-alpine
# Wait several minutes for the target server to go steady, then:
sh measure.sh http://target:40772 10m >/dev/null
sh remote.sh -r $TARGET_IPADDR down

# mirakc-debian
sh remote.sh -r $TARGET_IPADDR up mirakc-debian
sh measure.sh http://target:40773 10m >/dev/null
sh remote.sh -r $TARGET_IPADDR down

# mirakurun
sh remote.sh -r $TARGET_IPADDR up mirakurun
sh measure.sh http://target:40774 10m >/dev/null
sh remote.sh -r $TARGET_IPADDR down
```

The command above performs:

* Receiving TS streams from 4 GR and 4 BS services for 10 minutes
* Collecting system metrics by using [Prometheus] and [node_exporter]
* Counting the number of dropped TS packets by using [node-aribts]

Several hundreds or thousands of dropped packets were sometimes detected during
the performance measurement.  The same situation also occurred in Mirakurun.

[Raspberry Pi OS (64-bit)]: https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit
[Armbian]: https://www.armbian.com/rock64/
[Prometheus]: https://prometheus.io/
[node_exporter]: https://github.com/prometheus/node_exporter
[node-aribts]: https://www.npmjs.com/package/aribts
