#!/usr/bin/env python3
"""Build a panel insert-locations BED file from an amplicon info table and a
reference FASTA of insert sequences.

Inputs
  amplicon info TSV : tab-separated with columns target_name, chrom,
                      insert_start, insert_end (other columns are ignored)
  reference FASTA   : one record per target, header = target_name,
                      sequence = insert sequence in reference (+) orientation

Output (tab-separated, sorted by chrom then start):
  #chrom  start  end  target_name  length  strand  ref_seq

Coordinates are 0-based half-open so that ref_seq == genome[start:end] and
length == end - start == len(ref_seq).

MAD4HatTeR amplicon info files give insert_start/insert_end one base wider on
each side than the insert sequence in the reference FASTA. When a target's
FASTA sequence is exactly 2 bases shorter than insert_end - insert_start, the
coordinates are tightened by one base on each side to match the sequence.
Any other length mismatch is an error.

Only the Python standard library is used.
"""

import argparse
import csv
import sys

REQUIRED_COLUMNS = ("target_name", "chrom", "insert_start", "insert_end")
HEADER = ("#chrom", "start", "end", "target_name", "length", "strand", "ref_seq")


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Build a panel insert-locations BED from amplicon info and a reference FASTA."
    )
    parser.add_argument("--amplicon-info", required=True,
                        help="Amplicon info TSV (target_name, chrom, insert_start, insert_end, ...)")
    parser.add_argument("--reference", required=True,
                        help="Reference FASTA of insert sequences, one record per target_name")
    parser.add_argument("--output", required=True, help="Output BED path")
    parser.add_argument("--chrom-prefix", action="append", default=[], metavar="PREFIX",
                        help="Only keep targets whose chrom starts with PREFIX "
                             "(repeatable, e.g. --chrom-prefix Pf3D7). Default: keep all targets.")
    return parser.parse_args(argv)


def read_fasta(path):
    seqs = {}
    name = None
    chunks = []
    with open(path) as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            if line.startswith(">"):
                if name is not None:
                    seqs[name] = "".join(chunks).upper()
                name = line[1:].split()[0]
                if name in seqs:
                    sys.exit(f"ERROR: duplicate FASTA record '{name}' in {path}")
                chunks = []
            else:
                chunks.append(line)
    if name is not None:
        seqs[name] = "".join(chunks).upper()
    return seqs


def read_amplicon_info(path):
    with open(path, newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        missing = [c for c in REQUIRED_COLUMNS if c not in (reader.fieldnames or [])]
        if missing:
            sys.exit(f"ERROR: {path} is missing required column(s): {', '.join(missing)}")
        return list(reader)


def build_records(amplicons, seqs, chrom_prefixes):
    records = []
    errors = []
    seen = set()
    for row in amplicons:
        target = row["target_name"]
        chrom = row["chrom"]
        if chrom_prefixes and not chrom.startswith(tuple(chrom_prefixes)):
            continue
        if target in seen:
            errors.append(f"{target}: duplicate target_name in amplicon info")
            continue
        seen.add(target)
        if target not in seqs:
            errors.append(f"{target}: not found in reference FASTA")
            continue
        try:
            start = int(row["insert_start"])
            end = int(row["insert_end"])
        except ValueError:
            errors.append(f"{target}: non-integer insert_start/insert_end")
            continue

        seq = seqs[target]
        diff = (end - start) - len(seq)
        if diff == 2:
            start, end = start + 1, end - 1
        elif diff != 0:
            errors.append(
                f"{target}: insert_end - insert_start = {end - start} but FASTA sequence "
                f"is {len(seq)} bases (expected equal, or 2 longer)"
            )
            continue
        records.append((chrom, start, end, target, len(seq), "+", seq))

    if errors:
        sys.exit("ERROR: could not build BED:\n  " + "\n  ".join(errors))
    records.sort(key=lambda r: (r[0], r[1], r[2], r[3]))
    return records


def main(argv=None):
    args = parse_args(argv)
    seqs = read_fasta(args.reference)
    amplicons = read_amplicon_info(args.amplicon_info)
    records = build_records(amplicons, seqs, args.chrom_prefix)
    if not records:
        sys.exit("ERROR: no targets left to write (check --chrom-prefix)")

    with open(args.output, "w", newline="") as out:
        writer = csv.writer(out, delimiter="\t", lineterminator="\n")
        writer.writerow(HEADER)
        writer.writerows(records)
    print(f"Wrote {len(records)} targets to {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
