# docker-mirakc-alpine

## How to use

Create `.env` file in this folder, which defines the following environment variables:

```console
$cat .env
UPSTREAM_IPADDR=192.168.1.23
TZ=Asia/Tokyo
```

The `UPSTREAM_IPADDR` environment variables defines an IP address of an upstream
Mirakurun-compatible server which provides TS streams for performance measurements.

Create containers, and start them in the background:

```shell
docker-compose up -d
```

Show logs:

```shell
docker-compose logs
```

Stop containers, and remove them together with a data volume for the `mirakc-alpine` container:

```shell
docker-compose down -v
```
