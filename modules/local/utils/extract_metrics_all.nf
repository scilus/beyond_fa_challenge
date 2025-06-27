process EXTRACT_METRICS_JHU {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.1.0.sif':
        'scilus/scilus:2.1.0' }"

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

process EXTRACT_METRICS_BUNDLEPARC {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:latest' }"

    input:
        tuple val(meta), path(bundles_list), path(metric)

    output:
        tuple val(meta), path("*.json"), emit: features

    when:
    task.ext.when == null || task.ext.when

    script:

    def out_filename = task.ext.out_filename ?: "features-128.json"
    def binarize_labels = task.ext.binarize_labels ?: false
    def all_labels = task.ext.all_labels ?: false
    def nb_pts = task.ext.nb_pts
    """
    python3 - << ENDSCRIPT
    import nibabel as nib
    import numpy as np
    import json
    import re
    import os

    # Convert bundles_list to a list of paths
    bundles_list = "${bundles_list}".split(' ')

    features = np.zeros((128,))
    if "${all_labels}" != "true":
        custom_bundles_list = ["CC_2", "CG_left", "CG_right", "UF_left", "UF_right",
            "FX_left", "FX_right", "CST_left", "CST_right", "AF_left", "AF_right",
            "OR_left", "OR_right", "ILF_left", "ILF_right", "IFO_left",
            "IFO_right", "ATR_left", "ATR_right", "T_OCC_left", "T_OCC_right",
            "T_PAR_left", "T_PAR_right", "T_POSTC_left", "T_POSTC_right",
            "T_PREC_left", "T_PREC_right", "T_PREF_left", "T_PREF_right",
            "T_PREM_left", "T_PREM_right"]

        new_bundles_list = []
        for bundle in custom_bundles_list:
            for bundle_filename in bundles_list:
                if re.search(f".*_{bundle}.*", bundle_filename):
                    new_bundles_list.append(bundle_filename)
                    break
        bundles_list = new_bundles_list
        

    i = 0
    metric = nib.load("${metric}").get_fdata()
    for bundle_filename in bundles_list:
        labels = nib.load(bundle_filename).get_fdata().astype(int)

        if "${binarize_labels}" == "true":
            labels = (labels > 0).astype(np.float32)  # Binarize the labels

        for label in range(1, int("$nb_pts")+1):  # Exclude background label (0)
            mask = (labels == label)

            if np.any(mask):
                features[i] = np.mean(metric[mask])
            else:
                features[i] = 0.0  # If no voxels in the label, set feature to 0
            i += 1

            if i >= 128:
                break  # Stop if we have filled all 128 features

    # Save the features to a JSON file (list of 128 floats)
    with open("${out_filename}", 'w') as f:
        json.dump(features.tolist(), f)
    ENDSCRIPT
    """
}
