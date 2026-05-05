version 1.0

task dcifer_slaf_wrapper {
  input {
    String group_name
    File allele_table
    String docker_image
    String out = "~{group_name}.mhaps_slaf.tsv"

    Int? coi_lrank
    Float? qstart
    Float? tol
  }

  command <<<
    set -euxo pipefail

    extra=""
    if [ "~{coi_lrank}" != "null" ]; then extra="$extra --coi_lrank ~{coi_lrank}"; fi
    if [ "~{qstart}" != "null" ]; then extra="$extra --qstart ~{qstart}"; fi
    if [ "~{tol}" != "null" ]; then extra="$extra --tol ~{tol}"; fi

    Rscript /opt/plasmodiumdrugres/bin/PGEcore/scripts/dcifer_slaf_wrapper/dcifer_slaf_wrapper.R \
      --allele_table ~{allele_table} \
      --slaf_output ~{out} \
      $extra
  >>>

  output {
    File mhaps_slaf = "~{out}"
  }

  runtime {
    cpu: 2
    memory: "20 GiB"
    disks: "local-disk 20 HDD"
    preemptible: 3
    maxRetries: 1
    docker: docker_image
  }
}

