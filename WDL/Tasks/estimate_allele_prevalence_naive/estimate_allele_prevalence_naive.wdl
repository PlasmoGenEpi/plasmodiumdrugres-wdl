version 1.0

task estimate_allele_prevalence_naive {
  input {
    String group_name
    File aa_calls
    String docker_image
    String out = "~{group_name}.allele_prev.tsv"
  }

  command <<<
    set -euxo pipefail

    Rscript /opt/plasmodiumdrugres/bin/PGEcore/scripts/estimate_allele_prevalence_naive/estimate_allele_prevalence_naive.R \
      --aa_calls ~{aa_calls} \
      --output ~{out}
  >>>

  output {
    File allele_prevalence = "~{out}"
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
