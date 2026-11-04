#!/usr/bin/env python3
"""Reformat a MAD4HatTeR allele table (e.g. allele_data_filtered.txt)
into the specimen/target/reads/seq TSV layout.

Input  (tab-separated): sample_name, target_name, reads, <seq column>, ...
Output (tab-separated): specimen_name, target_name, reads, seq

sample_name is normalised by stripping the sequencer suffix ("_S12", "_S12_L001"), the
same transformation Mad4HatterQcReport applies via standardise_sample_name. Everything
downstream of this script joins on specimen_name -- the population map, the Terra
row-id resolution in resmarkers_to_terra.py -- and those references use the bare name.
Without this, the pipeline only works on the QC report's output and breaks on
Mad4Hatter's own allele table, which keeps the full suffix. Pass
--keep-sequencer-suffix to leave the name exactly as given.

Columns are renamed as below, reordered, and all other columns are dropped.
Values are copied through unchanged.

The seq column defaults to the unmasked "asv" column. Masked sequences
(asv_masked, with lowercase 'n') break translate_loci_of_interest.R, whose
alignment only scores A/C/G/T.

Alleles whose sequence is not pure ACGT are dropped, with a count on stderr.
translate_loci_of_interest.R aligns with a baseOnly=TRUE substitution matrix, so any
other character aborts the whole task -- 'N' as "key 15 not in lookup table", '-' as
key 16. Note Mad4Hatter emits a single 'N' at the R1/R2 junction by design (DADA2
concatenates non-overlapping mates with 10 Ns and collapse_concatenated_reads.py
rewrites that to one N), so this is normal pipeline output rather than bad data, and it
only reaches the aligner when such an allele sits on a target that also carries a locus
of interest. Dropping the allele loses its genuine variants elsewhere in the sequence
too; scoring N neutrally in that matrix would be the better fix, but it lives upstream.
Pass --strict-sequences to fail instead of dropping.

Only the Python standard library is used.
"""

import argparse
import csv
import re
import sys


# Matches Mad4HatterQcReport's standardise_sample_name: "_S12" or "_S12_L001".
SEQUENCER_SUFFIX = re.compile(r"_S\d+(_L\d+)?$")

# What translate_loci_of_interest.R's substitution matrix can score
# (pwalign::nucleotideSubstitutionMatrix(baseOnly = TRUE)).
ALIGNABLE_BASES = frozenset("ACGT")


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Reformat an allele table into specimen_name/target_name/reads/seq TSV."
    )
    parser.add_argument("--input", required=True,
                        help="Tab-separated allele table (sample_name, target_name, reads, asv, ...)")
    parser.add_argument("--output", required=True, help="Output TSV path")
    parser.add_argument("--strict-sequences", action="store_true",
                        help="Exit with an error on the first sequence containing a base the "
                             "aligner cannot score, instead of dropping those alleles")
    parser.add_argument("--keep-sequencer-suffix", action="store_true",
                        help="Leave sample_name untouched instead of stripping a trailing "
                             "_S<digits> or _S<digits>_L<digits>")
    parser.add_argument("--seq-column", default="asv",
                        help="Input column to write as seq (default: asv, the unmasked sequence)")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    # output column -> input column, in output order
    column_map = (
        ("specimen_name", "sample_name"),
        ("target_name", "target_name"),
        ("reads", "reads"),
        ("seq", args.seq_column),
    )
    with open(args.input, newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        missing = [src for _, src in column_map if src not in (reader.fieldnames or [])]
        if missing:
            sys.exit(f"ERROR: {args.input} is missing required column(s): {', '.join(missing)}")

        with open(args.output, "w", newline="") as out:
            writer = csv.writer(out, delimiter="\t", lineterminator="\n")
            writer.writerow([dst for dst, _ in column_map])
            n = 0
            dropped = 0
            dropped_bases = set()
            for row in reader:
                values = [row[src] for _, src in column_map]
                if not args.keep_sequencer_suffix:
                    values[0] = SEQUENCER_SUFFIX.sub("", values[0])
                unscorable = set(values[3].upper()) - ALIGNABLE_BASES
                if unscorable:
                    if args.strict_sequences:
                        sys.exit(
                            f"ERROR: {args.input}: {values[0]} / {values[1]} has a sequence the "
                            f"aligner cannot score (found {','.join(sorted(unscorable))}; only "
                            f"{''.join(sorted(ALIGNABLE_BASES))} are scorable). Drop these alleles "
                            f"by running without --strict-sequences."
                        )
                    dropped += 1
                    dropped_bases |= unscorable
                    continue
                writer.writerow(values)
                n += 1
    if dropped:
        print(
            f"WARNING: dropped {dropped} of {n + dropped} alleles whose sequence contains "
            f"{','.join(sorted(dropped_bases))}, which {args.seq_column} may carry at the R1/R2 "
            f"junction and the aligner cannot score. Those alleles are absent from the amino acid "
            f"calls. Use --strict-sequences to fail instead.",
            file=sys.stderr,
        )
    print(f"Wrote {n} rows to {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
