# scripts

Python scripts for the data steps. These run many times, so they stay scripted rather than done by hand.

Planned:

- Download the sample dataset into `data/` (ignored by git)
- Upload raw files to the raw log bucket
- Put the `ingest` annotation on each file (source, parser, record count, SHA-256)
- Load events into the S3 Tables events table
