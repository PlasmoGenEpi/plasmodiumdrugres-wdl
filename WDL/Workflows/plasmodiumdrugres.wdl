version 1.0

import "../Tasks/count_samples_by_coi.wdl" as count_samples_by_coi_t

workflow plasmodiumdrugres {
    input {
        File coi_calls = coi_calls
    }

    call count_samples_by_coi_t.count_samples_by_coi as t_001_count_samples_by_coi {
        input:
            coi_calls = coi_calls
    }

    output {
        File sample_count_per_coi = t_001_count_samples_by_coi.sample_count_per_coi
    }
}
