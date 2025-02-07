version 1.0

task estimate_coi_naive {
    input {
        File allele_table
        String output_path = "coi_table.tsv"
        String method = "integer_method" # Default method, "quantile_method" is the second option 
        Int integer_threshold = 5
        Float quantile_threshold = 0.05
    }

    command <<<
	export TMPDIR=tmp
	set -euxo pipefail
	
	if [ "~{method}" == "integer_method" ]; then
		Rscript /opt/pmotools-python/PGEcore/scripts/estimate_coi_naive/estimate_coi_naive.R \
			--input_path ~{allele_table} \
			--output_path ~{output_path} \
			--method ~{method} \
			--integer_threshold ~{integer_threshold}
	elif [ "~{method}" == "quantile_method" ]; then
		Rscript /opt/pmotools-python/PGEcore/scripts/estimate_coi_naive/estimate_coi_naive.R \
			--input_path ~{allele_table} \
			--output_path ~{output_path} \
			--method ~{method} \
			--quantile_threshold ~{quantile_threshold}
	else
		echo "Invalid method. Please choose either 'integer_method' or 'quantile_method'"
		exit 1
	fi
    >>>

    output {
        File coi_naive_o = "~{output_path}"
    }

    runtime {
        cpu: 1
        memory: "10 GiB"
        disks: "local-disk 10 HDD"
        bootDiskSizeGb: 10
        preemptible: 3
        maxRetries: 1
        docker: 'jorgeamaya/pgecore:v_0_0_1'
    }
}

