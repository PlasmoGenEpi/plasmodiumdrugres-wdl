#!/usr/bin/env python3
"""Self-check for the sample-table plumbing in resmarkers_to_terra.py.

Run with: python3 python/test_resmarkers_to_terra.py
No pytest, no fixtures, no ops_utils needed (the Terra import is deferred).
"""

import csv
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import resmarkers_to_terra as r

CALLS = (
    "specimen_name\tgene\taa_position\taa\n"
    "SPEC-1\tdhfr-ts\t164\tL\n"
    "SPEC-1\tdhfr-ts\t164\tI\n"   # mixed call for the same gene/position
    "SPEC-2\tmdr1\t86\tY\n"
)


# The real row ids from the mad4hatter_sample table of
# broad-firecloud-dsde-methods/JTS_COPY_20261024_..._Mad4Hatter_CLONE, where upserting
# the bare specimen_name created five half-empty duplicate rows.
REAL_TERRA_IDS = {
    "SRR26819135_S1_L001", "SRR26819139_S2_L001", "SRR26819141_S3_L001",
    "SRR26819151_S4_L001", "SRR26819200_S5_L001",
}


# The three name shapes one sample takes, from the JTS_TEST_COPY_Nairobi workspace:
#   row id                  UG_TEST_G001_S68
#   02 output (normalised)  UG_TEST_G001
#   01 output (raw)         UG_TEST_G001_S68_L001   <- fails without the suffix variants
NAIROBI_IDS = {"UG_TEST_G001_S68", "UG_TEST_G002_S90", "UG_TEST_G003_S125"}


def test_resolve_across_name_shapes():
    # 01's raw allele table keeps the lane: the regression that broke submission edb7fd30
    assert r.resolve_terra_ids({"UG_TEST_G001_S68_L001"}, NAIROBI_IDS) == {
        "UG_TEST_G001_S68_L001": "UG_TEST_G001_S68"}

    # 02's normalised bare name still works (the path that already worked)
    assert r.resolve_terra_ids({"UG_TEST_G001"}, NAIROBI_IDS) == {
        "UG_TEST_G001": "UG_TEST_G001_S68"}

    # an id equal to the row id passes straight through
    assert r.resolve_terra_ids({"UG_TEST_G001_S68"}, NAIROBI_IDS) == {
        "UG_TEST_G001_S68": "UG_TEST_G001_S68"}

    # all three shapes at once, as an aggregated cohort might present them
    mixed = {"UG_TEST_G001_S68_L001", "UG_TEST_G002", "UG_TEST_G003_S125"}
    assert r.resolve_terra_ids(mixed, NAIROBI_IDS) == {
        "UG_TEST_G001_S68_L001": "UG_TEST_G001_S68",
        "UG_TEST_G002": "UG_TEST_G002_S90",
        "UG_TEST_G003_S125": "UG_TEST_G003_S125"}

    # a suffixed name against a bare row id: trim all the way down
    assert r.resolve_terra_ids({"X_S1_L001"}, {"X"}) == {"X_S1_L001": "X"}

    # SAFETY: a trimmed name must NOT be re-extended onto a different sequencer index.
    # X_S2_L001 trims to X, and extending X would wrongly match row X_S1.
    assert r.resolve_terra_ids({"X_S2_L001"}, {"X_S1"}) == {}

    # and the same guard with several indices present
    assert r.resolve_terra_ids({"X_S9_L001"}, {"X_S1", "X_S2"}) == {}


def test_resolve_terra_ids():
    # the regression: a bare specimen_name must resolve onto the suffixed row id
    resolved = r.resolve_terra_ids(
        {"SRR26819135", "SRR26819139", "SRR26819141", "SRR26819151", "SRR26819200"},
        REAL_TERRA_IDS)
    assert resolved == {
        "SRR26819135": "SRR26819135_S1_L001",
        "SRR26819139": "SRR26819139_S2_L001",
        "SRR26819141": "SRR26819141_S3_L001",
        "SRR26819151": "SRR26819151_S4_L001",
        "SRR26819200": "SRR26819200_S5_L001",
    }, resolved

    # an id that already matches exactly is used as-is
    assert r.resolve_terra_ids({"SRR26819135_S1_L001"}, REAL_TERRA_IDS) == {
        "SRR26819135_S1_L001": "SRR26819135_S1_L001"}

    # lane-less suffix also matches
    assert r.resolve_terra_ids({"S"}, {"S_S7"}) == {"S": "S_S7"}

    # ambiguous and unmatched names are skipped, never guessed
    assert r.resolve_terra_ids({"X"}, {"X_S1", "X_S2"}) == {}
    assert r.resolve_terra_ids({"NOPE"}, REAL_TERRA_IDS) == {}

    # a near-miss must NOT match: suffix has to be _S<digits>
    assert r.resolve_terra_ids({"SRR26819135"}, {"SRR26819135_extra"}) == {}


def test_converter_normalisation_feeds_the_resolver():
    """convert_allele_table strips the sequencer suffix; the resolver extends it back.

    These two have to agree or a no-QC run breaks: Mad4Hatter's allele table carries
    UG_TEST_G001_S68_L001, the Terra row is UG_TEST_G001_S68.
    """
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "cat", os.path.join(os.path.dirname(os.path.abspath(__file__)), "convert_allele_table.py"))
    cat = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(cat)

    for raw in ("UG_TEST_G001_S68_L001", "UG_TEST_G001_S68", "UG_TEST_G001"):
        bare = cat.SEQUENCER_SUFFIX.sub("", raw)
        assert bare == "UG_TEST_G001", (raw, bare)
        assert r.resolve_terra_ids({bare}, {"UG_TEST_G001_S68"}) == {
            "UG_TEST_G001": "UG_TEST_G001_S68"}, raw


def test_unscorable_bases_are_filtered():
    """convert_allele_table must not pass the aligner a base it cannot score.

    Mad4Hatter emits a single N at the R1/R2 junction by design, and asv_masked also
    carries 'n' and '-'. translate_loci_of_interest.R aligns with a baseOnly=TRUE
    matrix, which aborts on any of them ("key 15 not in lookup table" for N, 16 for -).
    """
    import importlib.util, subprocess
    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location(
        "cat", os.path.join(here, "convert_allele_table.py"))
    cat = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(cat)
    assert cat.ALIGNABLE_BASES == frozenset("ACGT")

    # Every IUPAC ambiguity code, in both cases, plus the characters asv_masked uses.
    # Each of these aborts pwalign with its own "key N not in lookup table": M=3, R=5,
    # S=6, V=7, W=9, Y=10, H=11, K=12, D=13, B=14, N=15, -=16, .=64. Verified against
    # the plasmogenepi image, so the whitelist matches the aligner exactly -- nothing is
    # dropped that would have aligned.
    unscorable = list("RYSWKMBDHVN") + ["-", "."]
    lines = ["sample_name\ttarget_name\treads\tasv"]
    for code in unscorable:
        lines.append(f"UP_{code}\tt1\t9\tACGT{code}ACGT")
        lines.append(f"LO_{code}\tt1\t9\tACGT{code.lower()}ACGT")
    lines.append("CLEAN_UPPER\tt1\t9\tACGTACGT")
    lines.append("CLEAN_LOWER\tt1\t9\tacgtacgt")   # case alone is fine: DNAString uppercases
    rows = "\n".join(lines) + "\n"
    n_dropped = 2 * len(unscorable)
    with tempfile.TemporaryDirectory() as d:
        src, out = os.path.join(d, "in.tsv"), os.path.join(d, "out.tsv")
        with open(src, "w") as fh:
            fh.write(rows)
        script = os.path.join(here, "convert_allele_table.py")

        r = subprocess.run([sys.executable, script, "--input", src, "--output", out],
                           capture_output=True, text=True)
        assert r.returncode == 0, r.stderr
        assert f"dropped {n_dropped} of {n_dropped + 2}" in r.stderr, r.stderr
        with open(out) as fh:
            kept = [l.split("\t")[0] for l in fh.read().splitlines()[1:]]
        assert sorted(kept) == ["CLEAN_LOWER", "CLEAN_UPPER"], kept

        r = subprocess.run([sys.executable, script, "--input", src, "--output", out,
                            "--strict-sequences"], capture_output=True, text=True)
        assert r.returncode != 0, "strict mode should fail"
        assert "cannot score" in r.stderr, r.stderr


def main():
    test_resolve_terra_ids()
    test_resolve_across_name_shapes()
    test_converter_normalisation_feeds_the_resolver()
    test_unscorable_bases_are_filtered()

    # Terra demands the row id column be named <table>_id; ops_utils raises otherwise.
    assert r.id_column_for("sample") == "sample_id"
    assert r.id_column_for("specimen") == "specimen_id"

    with tempfile.TemporaryDirectory() as d:
        calls_tsv = os.path.join(d, "collapsed_amino_acid_calls.tsv")
        with open(calls_tsv, "w") as fh:
            fh.write(CALLS)

        for table in ("sample", "specimen"):
            id_column = r.id_column_for(table)
            rows, columns = r.pivot(calls_tsv, id_column)

            # the row id lands under the detected column, not a hardcoded "sample_id"
            assert sorted(row[id_column] for row in rows) == ["SPEC-1", "SPEC-2"], rows
            assert columns == ["resmarker_dhfr-ts_164", "resmarker_mdr1_86"], columns
            spec1 = next(row for row in rows if row[id_column] == "SPEC-1")
            assert spec1["resmarker_dhfr-ts_164"] == "I/L", spec1

            out_tsv = os.path.join(d, f"{table}.tsv")
            r.write_tsv(out_tsv, rows, columns, id_column)
            with open(out_tsv) as fh:
                header = next(csv.reader(fh, delimiter="\t"))
            assert header[0] == id_column, header

    print("OK")


if __name__ == "__main__":
    main()
