version 1.0

task concat_tables {
  input {
    Array[File] sl_files
    Array[File] ml_files
    Array[File] sl_from_ml_files
    String docker_image
  }

  command <<<
    set -euxo pipefail

    # Pass as comma-separated lists (matches Nextflow wrapper usage)
    sl_list="$(printf "%s," ~{sep=' ' sl_files} | sed 's/,$//')"
    ml_list="$(printf "%s," ~{sep=' ' ml_files} | sed 's/,$//')"
    sl_from_ml_list="$(printf "%s," ~{sep=' ' sl_from_ml_files} | sed 's/,$//')"

    Rscript /opt/plasmodiumdrugres/bin/concat_tables.R \
      --sl-files "$sl_list" \
      --ml-files "$ml_list" \
      --sl-from-ml-files "$sl_from_ml_list" \
      --sl-out "sl_summary.tsv" \
      --ml-out "ml_summary.tsv" \
      --sl-from-ml-out "sl_from_ml_summary.tsv"
  >>>

  output {
    File sl_summary = "sl_summary.tsv"
    File ml_summary = "ml_summary.tsv"
    File sl_from_ml_summary = "sl_from_ml_summary.tsv"
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

