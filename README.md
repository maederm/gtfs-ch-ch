# GTFS ClickHouse ConfoederatioHelvetica

This project imports [GTFS](https://opendata.swiss/en/dataset/fahrplan-2026-gtfs2020) and [GTFS-RT](https://data.opentransportdata.swiss/dataset/gtfsrt) from Swiss public transport into a ClickHouse database.

This is not (yet) production ready.

## More information about the data


## Prerequisites

### GTFS-RT API key

For GTFS-RT you need an API key. You can get it from opentransportdata.swiss [API Manager](https://api-manager.opentransportdata.swiss/). They also have a more detailed [manual](https://opentransportdata.swiss/en/cookbook/development-miscellaneous-cookbook/howto-access-apis/).

### .env

The `load_rt.sh` script expects the credentials to be in `.env`, see [`.env.example`](.env.example).

### ClickHouse

For local development I recommend installing [clickhousectl](https://clickhouse.com/docs/interfaces/cli).
Currently this projects uses `clickhouse-client` as well as `clickhouse-local`. You may need to create symlinks in a folder from your `$PATH` to `$HOME/.clickhouse/versions/26.6.1.117/clickhouse` with these names. The ClickHouse binary will automatically use the correct mode.

## Start hacking

```bash
# Install ClickHouse (I used 26.6.1.117 for development)
chctl local install latest

# Run ClickHouse
chctl local server start -F

# Copy GTFS-RT protobuf into ClickHouse
curl -o ./.clickhouse/servers/default/data/format_schemas/gtfs-realtime.proto https://gtfs.org/documentation/realtime/gtfs-realtime.proto

# Initialize GTFS database
./gtfs_loader.py --init

# Load first timetable
./gtfs_loader.py

# Install auto-updating GTFS-RT materialized view
./clickhouse/seed/load_rt.sh
```

## Example UI

In [`viewer/index.html`](viewer/index.html) is a demo webpage that shows Departurs from Swiss public transport stations. It uses the ClickHouse http API to do the necessary queries.

##  License

Unless otherwise noted, the contents of this repository are licensed under the GNU Affero General Public License, version 3 or any later version. See [`LICENSE`](LICENSE).
