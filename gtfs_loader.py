#!/usr/bin/env python3
"""Automatic GTFS base data loader.

Checks the CKAN Swiss Open Data portal for new timetable versions,
downloads the ZIP file, and loads it into ClickHouse using clickhouse-local.
"""

from argparse import ArgumentParser
from dataclasses import dataclass, field
from glob import glob
from os import environ
from pathlib import Path
from re import IGNORECASE, search
from shutil import copyfileobj
from subprocess import run
from tempfile import TemporaryDirectory

from requests import get as http_get

CKAN_URL = "https://ckan.opendata.swiss/api/3/action/package_show?id=fahrplan-2026-gtfs2020"

GTFS_TABLES = [
    ("agency", "agency.txt"),
    ("routes", "routes.txt"),
    ("stops", "stops.txt"),
    ("trips", "trips.txt"),
    ("calendar", "calendar.txt"),
    ("calendar_dates", "calendar_dates.txt"),
    ("frequencies", "frequencies.txt"),
    ("transfers", "transfers.txt"),
    ("stop_times", "stop_times.txt"),
    ("feed_info", "feed_info.txt"),
]

ALL_TABLES = [t for t, _ in GTFS_TABLES] + ["departures"]


def with_ch_params(cmd, params):
    return cmd + [f"--param_{key}={value}" for key, value in params.items()]


@dataclass
class Config:
    ch_client: str = field(default_factory=lambda: environ.get("CH_CLIENT", "clickhouse-client"))
    ch_local: str = field(default_factory=lambda: environ.get("CH_LOCAL", "clickhouse-local"))
    ch_host: str = field(default_factory=lambda: environ.get("CH_HOST", "localhost"))
    ch_port: str = field(default_factory=lambda: environ.get("CH_PORT", "9000"))
    ch_dir: Path = Path(__file__).resolve().parent / "clickhouse"


def get_latest_resource():
    data = http_get(CKAN_URL).json()
    zips = [r for r in data["result"]["resources"] if r.get("format") == "ZIP"]
    if not zips:
        raise RuntimeError("No ZIP resource found in CKAN API response")
    return max(zips, key=lambda r: r.get("issued", ""))


def extract_feed_version(filename):
    match = search(r"(\d{8})\.zip$", filename, IGNORECASE)
    if not match:
        raise ValueError(f"Cannot extract feed version from: {filename}")
    return match.group(1)


def is_version_loaded(cfg, feed_version):
    query = "SELECT count() FROM {db:Identifier}.{table:Identifier} WHERE feed_version = {feed_version:Date32}"
    params = {"db": "gtfs", "table": "feed_info", "feed_version": feed_version}
    result = run(
        with_ch_params([cfg.ch_client, "-q", query], params),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return False
    return int(result.stdout.strip()) > 0


def download(url, dest):
    print(f"  {url}")
    resp = http_get(url, stream=True)
    resp.raise_for_status()
    with open(dest, "wb") as f:
        copyfileobj(resp.raw, f)
    print(f"  Done ({dest.stat().st_size // 1024 // 1024} MB)")


def init_schema(cfg):
    print("=== Creating database ===")
    run([cfg.ch_client, "--queries-file", str(cfg.ch_dir / "gtfs_init.sql")], check=True)

    print("=== Creating tables ===")
    for sql in sorted(glob(str(cfg.ch_dir / "tables" / "gtfs_*.sql"))):
        print(f"  {Path(sql).name}")
        run([cfg.ch_client, "--queries-file", sql], check=True)

    print("=== Creating materialized views ===")
    for sql in sorted(glob(str(cfg.ch_dir / "materialized_views" / "gtfs_*.sql"))):
        print(f"  {Path(sql).name}")
        run([cfg.ch_client, "--queries-file", sql], check=True)

    print("=== Creating views ===")
    for sql in sorted(glob(str(cfg.ch_dir / "views" / "gtfs_*.sql"))):
        print(f"  {Path(sql).name}")
        run([cfg.ch_client, "--queries-file", sql], check=True)


def delete_feed_version(cfg, feed_version):
    print(f"\n=== Deleting existing feed_version {feed_version} ===")
    query = "DELETE FROM {db:Identifier}.{table:Identifier} WHERE feed_version = {feed_version:Date32}"
    for table in sorted(ALL_TABLES, key=lambda t: t == "feed_info"):  # delete feed_info last
        params = {"db": "gtfs", "table": table, "feed_version": feed_version}
        run(
            with_ch_params([cfg.ch_client, "-q", query], params),
            check=True,
        )
        print(f"  gtfs.{table}")


def load_table(cfg, zip_path, table, csv_file, feed_version):
    file_arg = f"{zip_path} :: {csv_file}"
    if csv_file == "feed_info.txt":
        select = (
            "SELECT toDate32(feed_version) AS feed_version, * EXCEPT (feed_version) "
            "FROM file({file_arg:String}, CSVWithNames)"
        )
        select_params = {"file_arg": file_arg}
    else:
        select = "SELECT toDate32({feed_version:Date32}) AS feed_version, * FROM file({file_arg:String}, CSVWithNames)"
        select_params = {"feed_version": feed_version, "file_arg": file_arg}

    query = (
        "INSERT INTO FUNCTION remote({remote:String}, {db:String}, {table:String}) "
        + select
        + " SETTINGS date_time_input_format='best_effort', input_format_csv_empty_as_default=1"
    )
    params = {
        "remote": f"{cfg.ch_host}:{cfg.ch_port}",
        "db": "gtfs",
        "table": table,
        **select_params,
    }
    run(with_ch_params([cfg.ch_local, "-q", query], params), check=True)


def print_row_counts(cfg):
    print("\n=== Row counts ===")
    query = "SELECT count() FROM {db:Identifier}.{table:Identifier}"
    for table in ALL_TABLES:
        params = {"db": "gtfs", "table": table}
        result = run(
            with_ch_params([cfg.ch_client, "-q", query], params),
            capture_output=True,
            text=True,
        )
        count = result.stdout.strip() if result.returncode == 0 else "error"
        print(f"  gtfs.{table:20s} {count}")


def main():
    parser = ArgumentParser(description="Auto-load GTFS base data into ClickHouse")
    parser.add_argument(
        "--init",
        action="store_true",
        help="Create database, tables, and materialized views, then exit",
    )
    parser.add_argument("--force", action="store_true", help="Load even if feed version already exists")
    args = parser.parse_args()

    cfg = Config()

    if args.init:
        init_schema(cfg)
        print("\nDone.")
        return

    print("=== Checking for new GTFS version ===")
    resource = get_latest_resource()
    filename = resource["display_name"]["en"]
    feed_version = extract_feed_version(filename)
    download_url = resource["download_url"]
    print(f"  Latest: {filename} (feed_version: {feed_version})")

    if not args.force and is_version_loaded(cfg, feed_version):
        print(f"  Feed version {feed_version} already loaded. Use --force to reload.")
        return

    if args.force and is_version_loaded(cfg, feed_version):
        delete_feed_version(cfg, feed_version)

    with TemporaryDirectory(prefix="gtfs_") as tmpdir:
        zip_path = Path(tmpdir) / filename

        print("\n=== Downloading ===")
        download(download_url, zip_path)

        print("\n=== Loading tables ===")
        for table, csv_file in GTFS_TABLES:
            print(f"  {table:20s} <- {csv_file}")
            load_table(cfg, zip_path, table, csv_file, feed_version)

        print_row_counts(cfg)

    print("\nDone.")


if __name__ == "__main__":
    main()
