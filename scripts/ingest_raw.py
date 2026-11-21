"""
Rebuild raw log files from the sample CSV, upload them to the raw bucket,
and attach an `ingest` annotation to each uploaded object version.

Writes a manifest (raw_object_key -> raw_version_id) for the events load step.
"""
import argparse
import csv
import gzip
import hashlib
import json
import sys
from collections import defaultdict
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

ANNOTATION_NAME = "ingest"
PARSER = "sample-csv-rebuild-v1"

def read_rows(csv_path):
    """Group CSV rows by their original file, oldest event first."""
    csv.field_size_limit(sys.maxsize)  
    files = defaultdict(list)
    with open(csv_path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            files[row["source_file"]].append(row)
    for rows in files.values():
        rows.sort(key=lambda r: r["event_time"])
    return files

def build_file(key, rows):
    """One raw line per event. Gzip with mtime=0 so the bytes are the same every run."""
    body = ("\n".join(r["raw"] for r in rows) + "\n").encode("utf-8")
    if key.endswith(".gz"):
        body = gzip.compress(body, mtime=0)
    return body

def existing_version(s3, bucket, key, sha256):
    """Return the current version ID if this exact file is already uploaded and annotated."""
    try:
        resp = s3.get_object_annotation(Bucket=bucket, Key=key, AnnotationName=ANNOTATION_NAME)
    except ClientError as e:
        if e.response["Error"]["Code"] in ("NoSuchKey", "NoSuchAnnotation", "404"):
            return None
        raise
    payload = json.loads(resp["AnnotationPayload"].read())
    return resp["ObjectVersionId"] if payload.get("sha256") == sha256 else None

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv", required=True, help="Path to security_events_sample.csv")
    parser.add_argument("--bucket", help="Raw bucket name (terraform output raw_bucket_name)")
    parser.add_argument("--manifest", default="data/manifest.csv", help="Output manifest path")
    parser.add_argument("--dry-run", action="store_true", help="Build files and print a summary, no AWS calls")
    args = parser.parse_args()

    if not args.dry_run and not args.bucket:
        parser.error("--bucket is required unless --dry-run is set")

    files = read_rows(args.csv)
    print(f"{sum(len(r) for r in files.values())} events in {len(files)} files")

    s3 = None if args.dry_run else boto3.client("s3")
    manifest = []
    uploaded = skipped = 0

    for i, (key, rows) in enumerate(sorted(files.items()), start=1):
        body = build_file(key, rows)
        sha256 = hashlib.sha256(body).hexdigest()
        version_id = "dry-run"

        if not args.dry_run:
            version_id = existing_version(s3, args.bucket, key, sha256)
            if version_id:
                skipped += 1
            else:
                version_id = s3.put_object(Bucket=args.bucket, Key=key, Body=body)["VersionId"]
                annotation = {
                    "source": rows[0]["source"],
                    "parser": PARSER,
                    "record_count": len(rows),
                    "sha256": sha256,
                    "first_event_time": rows[0]["event_time"],
                    "last_event_time": rows[-1]["event_time"],
                    "ingested_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                }
                s3.put_object_annotation(
                    Bucket=args.bucket,
                    Key=key,
                    VersionId=version_id,  # pin to the version just uploaded
                    AnnotationName=ANNOTATION_NAME,
                    AnnotationPayload=json.dumps(annotation).encode("utf-8"),
                )
                uploaded += 1

        manifest.append({
            "raw_object_key": key,
            "raw_version_id": version_id,
            "source": rows[0]["source"],
            "record_count": len(rows),
            "sha256": sha256,
        })
        if i % 100 == 0:
            print(f"  {i}/{len(files)} files")

    with open(args.manifest, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(manifest[0].keys()))
        writer.writeheader()
        writer.writerows(manifest)

    print(f"uploaded {uploaded}, already present {skipped}, manifest: {args.manifest}")

if __name__ == "__main__":
    main()