
process KMEANS {

container "scilus/scilus:latest"

input:
    tuple val(meta), path(image)
output:
    tuple val(meta), path("labels/*.nii.gz"), emit: labels
    tuple val(meta), path("*_centroids.npy"), emit: centroids

script:
    def prefix = task.ext.prefix ?: "$meta.id"
    // K-means parameters
    def nb_regions = task.ext.nb_regions
    def algorithm = task.ext.algorithm ?: "lloyd"
    def init_method = task.ext.init_method ?: "k-means++"
    def nb_init = task.ext.nb_init ?: "auto"
    def max_iter = task.ext.max_iter ?: 300
    def norm_tolerance = task.ext.norm_tolerance ?: 1e-4
    def seed = task.ext.seed ?: 1234
    // Extract labels parameters
    def background_label = task.ext.background_label ? "--background $task.ext.background_label" : ""
    """
    python3 - << ENDSCRIPT

    import nibabel as nib
    import numpy as np
    from sklearn.cluster import KMeans

    bin_image = nib.load("$image")
    positions = np.nonzero(bin_image.get_fdata().astype(bool))
    positions = np.asarray(positions).reshape((3, -1)).T

    kmeans = KMeans(
        n_clusters=$nb_regions,
        init="$init_method",
        n_init=${nb_init instanceof java.lang.String ? "\"" + nb_init + "\"" : nb_init},
        max_iter=$max_iter,
        tol=$norm_tolerance,
        random_state=$seed,
        algorithm="$algorithm"
    ).fit(positions)

    output = np.zeros_like(bin_image.get_fdata(), dtype=np.int16)
    output[positions.T[0], positions.T[1], positions.T[2]] = kmeans.labels_ + 1

    nib.save(nib.Nifti1Image(output, bin_image.affine), "binary_as_labels.nii.gz")
    np.save(f"${prefix}_centroids.npy", kmeans.cluster_centers_)

    ENDSCRIPT

    scil_labels_split_volume_by_ids.py binary_as_labels.nii.gz \
        $background_label \
        --out_dir labels \
        --out_prefix $prefix
    """

}
