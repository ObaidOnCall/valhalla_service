FROM ghcr.io/valhalla/valhalla:latest

# Install necessary packages
RUN apt-get update && \
    apt-get install -y curl jq unzip spatialite-bin git

# Clone Valhalla repository
RUN git clone https://github.com/valhalla/valhalla.git ~/valhalla/

# Create necessary directories
RUN mkdir -p ~/valhalla/scripts/valhalla_tiles && \
    mkdir -p ~/valhalla/scripts/conf

# Download OSM data
RUN curl -O https://download.geofabrik.de/africa/morocco-latest.osm.pbf

# Build Valhalla configuration
WORKDIR /root/valhalla/scripts
RUN valhalla_build_config --mjolnir-tile-dir ./valhalla_tiles \
    --mjolnir-tile-extract ./valhalla_tiles.tar \
    --mjolnir-timezone ./valhalla_tiles/timezones.sqlite \
    --mjolnir-admin ./valhalla_tiles/admins.sqlite > ./conf/valhalla.json

# Build timezones
RUN valhalla_build_timezones > ./valhalla_tiles/timezones.sqlite

# Build Valhalla tiles
RUN valhalla_build_tiles -c ./conf/valhalla.json /morocco-latest.osm.pbf

# Create startup script
RUN echo '#!/bin/bash\nvalhalla_service ~/valhalla/scripts/conf/valhalla.json 2' > /usr/local/bin/start-valhalla.sh && \
    chmod +x /usr/local/bin/start-valhalla.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/start-valhalla.sh"]
