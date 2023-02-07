export SERVER_CONFIG_PATH=/app-config/server.yml
export TUNERS_CONFIG_PATH=/app-config/tuners.yml
export CHANNELS_CONFIG_PATH=/app-config/channels.yml
export SERVICES_DB_PATH=/app-data/services.json
export PROGRAMS_DB_PATH=/app-data/programs.json
export DOCKER=YES
export NODE_ENV=production

apt-get update -qq
apt-get install -y -qq --no-install-recommends ca-certificates curl

npm run start
