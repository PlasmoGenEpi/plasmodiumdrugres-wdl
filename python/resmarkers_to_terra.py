#!/usr/bin/env python3
"""Pivot the collapsed amino acid calls from translate_loci_of_interest into a
sample-centric table and upsert it into a Terra data table.

Input  (tab-separated, optionally gzipped): one row per specimen_name/gene/aa_position,
    with at least the columns specimen_name, gene, aa_position, aa
    (e.g. collapsed_amino_acid_calls.tsv.gz).
Output (tab-separated): one row per specimen_name with the columns
    <sample_table>_id, resmarker_<gene>_<aa_position>, ...
    where each resmarker column holds the "aa" value for that specimen. If a specimen
    has several different aa values at the same gene/position (a mixed call), the distinct
    values are sorted and joined with "/" (e.g. "F/Y").

The rows are then upserted into the Terra table named by --sample_table (default
"sample"). The existing table is NOT deleted: rows with a matching row id are updated,
other rows are left alone.

specimen_name is matched against the row ids already in that table before upserting,
because Terra row ids often carry a sequencer suffix (SRR26819135_S1_L001) that
specimen_name lacks (SRR26819135). Upserting the unmatched name would silently create a
second, half-empty row beside the real one instead of updating it.

Requires `pyops-service-toolkit` (module name `ops_utils`) for the Terra upload, e.g.:
    pip install git+https://github.com/broadinstitute/pyops-service-toolkit.git
"""

import argparse
import csv
import gzip
import logging
import re
import sys

logging.basicConfig(format="%(levelname)s: %(asctime)s : %(message)s", level=logging.INFO)

REQUIRED_COLUMNS = ["specimen_name", "gene", "aa_position", "aa"]

DEFAULT_SAMPLE_TABLE = "sample"
MIXED_CALL_SEPARATOR = "/"


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Pivot collapsed amino acid calls into a sample table and upload it to Terra."
    )
    parser.add_argument("--input", "-i", required=True,
                        help="Collapsed amino acid calls TSV (may be .gz)")
    parser.add_argument("--output", "-o", default="sample_resmarkers.tsv",
                        help="Output TSV path (default: %(default)s)")
    parser.add_argument("--billing_project", "-b",
                        help="Terra billing project (required unless --dry_run)")
    parser.add_argument("--workspace_name", "-w",
                        help="Terra workspace name (required unless --dry_run)")
    parser.add_argument("--sample_table", "-t", default=DEFAULT_SAMPLE_TABLE,
                        help="Terra data table to upsert into (default: %(default)s)")
    parser.add_argument("--dry_run", action="store_true",
                        help="Write the output TSV but do not upload to Terra")
    args = parser.parse_args(argv)

    if not args.dry_run and not (args.billing_project and args.workspace_name):
        parser.error("--billing_project and --workspace_name are required unless --dry_run is set")
    return args


def open_text(path):
    # Detect gzip by magic bytes rather than file extension (Cromwell may rename files)
    with open(path, "rb") as f:
        is_gzip = f.read(2) == b"\x1f\x8b"
    return gzip.open(path, "rt", newline="") if is_gzip else open(path, "r", newline="")


def column_name(gene, aa_position):
    # Terra attribute names allow only letters, numbers, underscores and dashes
    return re.sub(r"[^A-Za-z0-9_-]", "_", f"resmarker_{gene}_{aa_position}")


def id_column_for(sample_table):
    """Terra requires a table's row id column to be named <table>_id, and ops_utils
    rejects the upsert outright when it is not (terra_util.upload_metadata_with_batch_upsert)."""
    return f"{sample_table}_id"


SEQUENCER_SUFFIX = re.compile(r"_S\d+(_L\d+)?$")
LANE_SUFFIX = re.compile(r"_L\d+$")


def _suffix_variants(name):
    """The name as given, then with progressively less of its sequencer suffix.

    How much of the sequencer suffix a name carries depends on where it came from.
    For one sample these are all in play at once:

        UG_TEST_G001            Mad4HatterQcReport output (standardise_sample_name)
        UG_TEST_G001_S68        the Terra row id
        UG_TEST_G001_S68_L001   Mad4Hatter's own allele table, used when QC is skipped

    So try the name unchanged, then without the lane, then without the whole suffix.
    """
    variants = []
    for candidate in (name, LANE_SUFFIX.sub("", name), SEQUENCER_SUFFIX.sub("", name)):
        if candidate and candidate not in variants:
            variants.append(candidate)
    return variants


def _match(candidate, terra_ids, may_extend):
    """(row_id, ambiguous) for one candidate form of a specimen name.

    may_extend allows matching a row id that is the candidate PLUS a sequencer suffix,
    which is how a QC-normalised bare name finds its suffixed row. It is only safe for
    the name as given: extending an already-trimmed name would let 'X_S2_L001' trim to
    'X' and then match row 'X_S1', i.e. the wrong sample.
    """
    if candidate in terra_ids:
        return candidate, []
    if not may_extend:
        return None, []
    pattern = re.compile(rf"^{re.escape(candidate)}_S\d+(_L\d+)?$")
    matches = sorted(terra_id for terra_id in terra_ids if pattern.match(terra_id))
    if len(matches) == 1:
        return matches[0], []
    return None, matches


def resolve_terra_ids(specimen_names, terra_ids):
    """specimen_name -> the row id that already exists in the Terra table.

    Names with no match, or with more than one, are skipped and reported rather than
    guessed at, so we never upsert a stray row next to the real one.

    Ported from mad4hatter-wdl bin/write_metrics_to_sample_table.py, which solved this
    same mismatch for the QC metrics.
    """
    resolved = {}
    for name in sorted(specimen_names):
        row_id, ambiguous = None, []
        for index, candidate in enumerate(_suffix_variants(name)):
            row_id, ambiguous = _match(candidate, terra_ids, may_extend=(index == 0))
            if row_id or ambiguous:
                break
        if row_id:
            resolved[name] = row_id
        elif ambiguous:
            logging.warning(f"'{name}' matches multiple Terra ids ({', '.join(ambiguous)}); skipping.")
        else:
            logging.warning(f"no Terra id found for '{name}'; skipping.")
    return resolved


def pivot(path, id_column):
    """Return (rows, columns): one dict per specimen_name, and the sorted resmarker columns."""
    calls = {}  # sample_id -> column -> set of aa values
    columns = set()
    with open_text(path) as f:
        reader = csv.DictReader(f, delimiter="\t")
        missing = [c for c in REQUIRED_COLUMNS if c not in (reader.fieldnames or [])]
        if missing:
            sys.exit(f"ERROR: {path} is missing required column(s): {', '.join(missing)}")
        for record in reader:
            sample_id = record["specimen_name"]
            column = column_name(record["gene"], record["aa_position"])
            columns.add(column)
            calls.setdefault(sample_id, {}).setdefault(column, set()).add(record["aa"])
    rows = [
        {id_column: sample_id, **{c: MIXED_CALL_SEPARATOR.join(sorted(v)) for c, v in cols.items()}}
        for sample_id, cols in calls.items()
    ]
    return rows, sorted(columns)


def write_tsv(path, rows, columns, id_column):
    header = [id_column] + columns
    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=header, delimiter="\t", restval="")
        writer.writeheader()
        writer.writerows(rows)


def upload_to_terra(rows, billing_project, workspace_name, sample_table, id_column):
    from ops_utils.request_util import RunRequest
    from ops_utils.terra_util import TerraWorkspace
    from ops_utils.token_util import Token

    terra_workspace = TerraWorkspace(
        billing_project=billing_project,
        workspace_name=workspace_name,
        request_util=RunRequest(token=Token()),
    )

    # Map specimen_name onto the row ids that already exist, so we update the real rows
    # rather than creating suffix-less duplicates beside them.
    terra_ids = {
        entity["name"]
        for entity in terra_workspace.get_gcp_workspace_metrics(entity_type=sample_table, verbose=False)
    }
    id_by_name = resolve_terra_ids({row[id_column] for row in rows}, terra_ids)
    skipped = len(rows) - len(id_by_name)
    rows = [{**row, id_column: id_by_name[row[id_column]]} for row in rows if row[id_column] in id_by_name]
    if not rows:
        sys.exit(f"ERROR: none of the specimen names matched a row id in the "
                 f"'{sample_table}' table of {billing_project}/{workspace_name}; nothing uploaded.")
    if skipped:
        logging.warning(f"{skipped} specimen(s) had no matching row in '{sample_table}' and were skipped")

    # Upsert only: the existing table is intentionally left in place. Samples with no
    # call for a column simply don't have that attribute set.
    logging.info(f"Upserting {len(rows)} rows into Terra table '{sample_table}'")
    terra_workspace.upload_metadata_with_batch_upsert(
        table_data={
            sample_table: {
                "table_id_column": id_column,
                "row_data": rows,
            }
        }
    )


def main(argv=None):
    args = parse_args(argv)

    id_column = id_column_for(args.sample_table)
    rows, columns = pivot(args.input, id_column)
    logging.info(f"Pivoted into {len(rows)} rows for table '{args.sample_table}' "
                 f"across {len(columns)} resmarker columns")

    write_tsv(args.output, rows, columns, id_column)
    logging.info(f"Wrote {args.output}")

    if args.dry_run:
        logging.info("Dry run: skipping Terra upload")
        return
    upload_to_terra(rows, args.billing_project, args.workspace_name,
                    args.sample_table, id_column)
    logging.info("Upload complete.")


if __name__ == "__main__":
    main()
