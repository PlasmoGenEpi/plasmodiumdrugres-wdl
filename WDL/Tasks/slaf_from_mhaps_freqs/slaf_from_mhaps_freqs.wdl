version 1.0

task slaf_from_mhaps_freqs {
  input {
    String group_name
    File mhaps_slaf_fnp
    File loci_of_interest_per_microhaps_fnp
    String docker_image
    String out = "~{group_name}.slaf.tsv"
  }

  command <<<
    set -euxo pipefail

    Rscript /opt/plasmodiumdrugres/bin/PGEcore/scripts/calc_slaf_based_on_mhap_freqs/slaf_from_mhaps_freqs.R \
      --mhaps_slaf_fnp ~{mhaps_slaf_fnp} \
      --loci_of_interest_per_microhaps_fnp ~{loci_of_interest_per_microhaps_fnp} \
      --slaf_output ~{out}
  >>>

  output {
    File slaf = "~{out}"
  }

  runtime {
    cpu: 1
    memory: "10 GiB"
    disks: "local-disk 10 HDD"
    preemptible: 3
    maxRetries: 1
    docker: docker_image
  }
}

