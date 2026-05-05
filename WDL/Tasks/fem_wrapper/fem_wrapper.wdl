version 1.0

task fem_wrapper {
  input {
    String group_name
    File aa_calls
    File loci_group_table
    String docker_image
    Int coi = 3
    String out = "~{group_name}.aa_mlaf.tsv"
  }

  command <<<
    set -euxo pipefail

    Rscript /opt/plasmodiumdrugres/bin/PGEcore/scripts/FreqEstimationModel_wrapper/FreqEstimationModel_wrapper.R \
      --aa_calls ~{aa_calls} \
      --groups ~{loci_group_table} \
      --coi ~{coi} \
      --mlaf_output ~{out}
  >>>

  output {
    File mlaf = "~{out}"
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

