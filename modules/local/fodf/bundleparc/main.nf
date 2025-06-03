process BUNDLEPARC {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_latest.sif':
        'scilus/bundleparc:1.0.0' }"

    input:
    tuple val(meta), path(fodf)

    output:
    tuple val(meta), path("bundleparc/*.nii.gz") , emit: labels_maps

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def nb_points = task.ext.nb_points ? "--nb_pts " + task.ext.nb_points : ""

    """
    bundleparc_predict.py ${fodf} ${checkpoint} --out_prefix ${prefix}__ ${nb_points} --out_folder bundleparc --half
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    bundleparc_predict.py -h
    mkdir bundleparc

    touch bundleparc/${prefix}__AF_left.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list --disable-pip-version-check --no-python-version-warning | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        mrtrix: \$(mrinfo -version 2>&1 | sed -n 's/== mrinfo \\([0-9.]\\+\\).*/\\1/p')
    END_VERSIONS
    """
}