# docker-prometheus

## How to use

Create `.env` file in this folder, which defines the following environment variables:

```console
$cat .env
TARGET_IPADDR=192.168.1.23
TZ=Asia/Tokyo
```

The `TARGET_IPADDR` environment variables defines an IP address of a target server for a
performance measurement using [measure.sh](../measure.sh).

Create a `prometheus` container, and start it in the background:

```shell
docker-compose up -d
```

Show logs:

```shell
docker-compose logs
```

Stop the container, and remove it together with a data volume for the `prometheus` container:

```shell
docker-compose down -v
```
