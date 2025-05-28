process VOLUME_MATH {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:latest'}"

    input:
        tuple val(meta), path(image1), path(image2)

    output:
        tuple val(meta), path("*.nii.gz"), emit: image

    when:
    task.ext.when == null || task.ext.when

    script:
    assert task.ext.operation in ['substraction', 'division',
    'difference', 'union', 'intersection'] : "Operation ${task.ext.operation} not \
    supported. Supported operations are: \
    'substraction', 'division', 'difference', 'union', 'intersection'"

    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ?: "output"
    def data_type = task.ext.data_type ?: "float32"
    def exclude_background = task.ext.exclude_background ? "--exclude_background" : ""
    """
    scil_volume_math.py ${task.ext.operation} $image1 $image2 \
        ${prefix}__${suffix}.nii.gz --data_type $data_type $exclude_background
    """
}
