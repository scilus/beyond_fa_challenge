include { KMEANS } from "./modules/local/kmeans"

workflow {
    input = Channel.fromFilePairs("data/JHU/JHU-ICBM-T1-1mm.nii.gz")
        { [id: "JHU"] }

    KMEANS(input)
}