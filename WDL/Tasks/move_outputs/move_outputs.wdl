version 1.0

task move_outputs {
  input {
    File ml_summary
    File sl_summary
    File sl_from_ml_summary
    File amino_acid_calls
    File collapsed_amino_acid_calls
    File loci_covered_by_target_samples_info
    File loci_of_interest_for_target_for_microhap
    String output_directory
    Boolean use_gcs_staging
    String fc_workspace_bucket
  }

  String use_gcs_flag = if use_gcs_staging then "true" else "false"

  command <<<
    set -euo pipefail

    timestamp=$(date +"%Y-%m-%d_%H%M%S")

    if [ "~{use_gcs_flag}" = "true" ]; then
      base="gs://~{fc_workspace_bucket}/~{output_directory}/$timestamp"
      copy_one() {
        local src=$1
        local marker=$2
        local dest="$base/$(basename "$src")"
        echo "Copying $src to $dest"
        gcloud alpha storage cp "$src" "$dest"
        echo "$dest" > "$marker.path"
      }
    else
      mkdir -p "~{output_directory}/$timestamp"
      base="$(pwd)/~{output_directory}/$timestamp"
      copy_one() {
        local src=$1
        local marker=$2
        local dest="$base/$(basename "$src")"
        echo "Copying $src to $dest"
        cp -f "$src" "$dest"
        echo "$dest" > "$marker.path"
      }
    fi

    copy_one "~{ml_summary}" "ml_summary"
    copy_one "~{sl_summary}" "sl_summary"
    copy_one "~{sl_from_ml_summary}" "sl_from_ml_summary"
    copy_one "~{amino_acid_calls}" "amino_acid_calls"
    copy_one "~{collapsed_amino_acid_calls}" "collapsed_amino_acid_calls"
    copy_one "~{loci_covered_by_target_samples_info}" "loci_covered"
    copy_one "~{loci_of_interest_for_target_for_microhap}" "microhap"
  >>>

  output {
    String ml_summary_uri = read_string("ml_summary.path")
    String sl_summary_uri = read_string("sl_summary.path")
    String sl_from_ml_summary_uri = read_string("sl_from_ml_summary.path")
    String amino_acid_calls_uri = read_string("amino_acid_calls.path")
    String collapsed_amino_acid_calls_uri = read_string("collapsed_amino_acid_calls.path")
    String loci_covered_by_target_samples_info_uri = read_string("loci_covered.path")
    String loci_of_interest_for_target_for_microhap_uri = read_string("microhap.path")
  }

  runtime {
    docker: "gcr.io/google.com/cloudsdktool/cloud-sdk:540.0.0"
    cpu: 1
    memory: "2 GiB"
    disks: "local-disk 10 HDD"
    preemptible: 3
    maxRetries: 1
  }
}
