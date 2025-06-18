process EXTRACT_METRICS_JHU {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:latest' }"

    input:
        tuple val(meta), path(labels), path(metric)

    output:
        tuple val(meta), path("*.json"), emit: features

    when:
    task.ext.when == null || task.ext.when

    script:

    def out_filename = task.ext.out_filename ?: "features-128.json"
    """
    python3 - << ENDSCRIPT
    import nibabel as nib
    import numpy as np
    import json

    labels = nib.load("${labels}").get_fdata()
    metric = nib.load("${metric}").get_fdata()
    features = np.zeros((128,))

    unique_labels = np.unique(labels)[1:]  # Exclude background label (0)
    if len(unique_labels) == 0:
        raise ValueError("No unique labels found in the input labels image.")

    if len(unique_labels) > 128:
        raise ValueError("More than 128 unique labels found. Please reduce the number of labels.")

    for i, label in enumerate(unique_labels):
        mask = (labels == label)
        if np.any(mask):
            features[i] = np.mean(metric[mask])

    # Save the features to a JSON file (list of 128 floats)
    with open("${out_filename}", 'w') as f:
        json.dump(features.tolist(), f)
    ENDSCRIPT
    """
}
