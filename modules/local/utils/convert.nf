process CONVERT_CHALLENGE_INPUTS {
    tag "$meta.id"
    label 'process_single'

    input:
        tuple val(meta), path(image), path(json)

    output:
        tuple val(meta), path("${meta.id}__dwi.nii.gz"), emit: dwi
        tuple val(meta), path("${meta.id}__dwi.bval"), emit: bval
        tuple val(meta), path("${meta.id}__dwi.bvec"), emit: bvec

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    convert_mha_to_nifti.py ${image} ${meta.id}__dwi.nii.gz
    convert_json_to_bvalbvec_fix.py ${json} ${meta.id}__dwi.bval ${meta.id}__dwi.bvec
    """
}
