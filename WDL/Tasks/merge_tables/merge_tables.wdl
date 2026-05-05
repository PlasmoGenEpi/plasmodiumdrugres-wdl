version 1.0

task merge_tables {
  input {
    String population
    File allele_prev
    File slaf
    File mlaf
    File sl_from_ml
    String docker_image
  }

  command <<<
    set -euxo pipefail

    Rscript /opt/plasmodiumdrugres/bin/merge_tables.R \
      --freq_table ~{slaf} \
      --population ~{population} \
      --prev_table ~{allele_prev} \
      --output "~{population}.sl_summary.tsv"

    Rscript /opt/plasmodiumdrugres/bin/add_population_column.R \
      --table ~{mlaf} \
      --population ~{population} \
      --output "~{population}.ml_summary.tsv"

    Rscript /opt/plasmodiumdrugres/bin/add_population_column.R \
      --table ~{sl_from_ml} \
      --population ~{population} \
      --output "~{population}.sl_from_ml_summary.tsv"
  >>>

  output {
    File sl_summary = "~{population}.sl_summary.tsv"
    File ml_summary = "~{population}.ml_summary.tsv"
    File sl_from_ml_summary = "~{population}.sl_from_ml_summary.tsv"
  }

  runtime {
    cpu: 1
    memory: "4 GiB"
    disks: "local-disk 10 HDD"
    preemptible: 3
    maxRetries: 1
    docker: docker_image
  }
}

