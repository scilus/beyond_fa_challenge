include { KMEANS } from "./modules/local/kmeans"
include { IMAGE_RESAMPLE as UPSAMPLE } from "./modules/nf-neuro/image/resample"
include { RECONST_DTIMETRICS as DTI } from './modules/nf-neuro/reconst/dtimetrics'  
include { REGISTRATION } from "./subworkflows/nf-neuro/registration"
include { RECONST_FRF as FRF } from './modules/nf-neuro/reconst/frf'
include { VOLUME_MATH as FA_THRESHOLD } from './modules/local/volume_math/single.nf'
include { RECONST_FODF as FODF } from './modules/nf-neuro/reconst/fodf' 

params.input = null

workflow {
    jhu = Channel.fromFilePairs("../JHU/JHU-ICBM-T1-1mm.nii.gz")
        { "JHU" }
    jhu_fa = Channel.fromFilePairs("../JHU/JHU-ICBM-FA-1mm.nii.gz")
        { "JHU" }
    dwi = Channel.fromFilePairs("$params.input/dwi-4d-mri/*.mha")
        { file(it).simpleName }

    // 1. Convert mha to Nifti/bval/bvec
    //  - OUTPUTS :
    //      - out.dwi
    //      - out.bval
    //      - out.bvec
    ch_nii_bval_bvec = Channel.empty()
    ch_nii_bval_bvec = Channel.fromFilePairs("$params.input/*.{nii.gz,bval,bvec}", size: 3, flat: true)
        { file(it).simpleName.tokenize("_")[0..1].join("_") }
        .map{ id, bval, bvec, dwi -> [[id: id], dwi, bval, bvec] }
        .multiMap{ meta, dwi, bval, bvec ->
            dwi: [meta, dwi]
            bval: [meta, bval]
            bvec: [meta, bvec]
        }

    // 2. Upsample DWI
    // ch_dwi_to_upsample = ch_nii_bval_bvec.out.dwi
    ch_dwi_to_upsample = ch_nii_bval_bvec.dwi.view()
        .map{ meta, dwi -> [meta, dwi, []] }

    UPSAMPLE( ch_dwi_to_upsample )
    ch_dwi_upsampled = UPSAMPLE.out.image

    // 3. Extract b0 for template registration
    ch_fa = ch_dwi_upsampled
        .join( ch_nii_bval_bvec.bval )
        .join( ch_nii_bval_bvec.bvec )
        .map{ meta, dwi, bval, bvec -> [meta, dwi, bval, bvec, []] }

    DTI( ch_fa )

    // 3. Register to MNI
    ch_moving = ch_dwi_upsampled
        .map{ meta, dwi -> [meta] }
        .combine( jhu_fa.map{ meta, template -> [template] } )
    ch_fixed = DTI.out.fa

    REGISTRATION(
        ch_moving,
        ch_fixed,
        Channel.empty(),
        Channel.empty(),
        Channel.empty(),
        Channel.empty()
    )

    ch_jhu_to_subject_ref = ch_fixed
    ch_jhu_to_subject_transform = REGISTRATION.out.transfo_image

    // 4. Threshold FA to get mask
    ch_fa_to_threshold = DTI.out.fa
    FA_THRESHOLD( ch_fa_to_threshold )
    ch_fa_mask = FA_THRESHOLD.out.image

    // 5. Compute FRF
    ch_input_frf = ch_dwi_upsampled
        .join( ch_nii_bval_bvec.bval )
        .join( ch_nii_bval_bvec.bvec )
        .join( ch_fa_mask )
        .map{ meta, dwi, bval, bvec, frf -> [meta, dwi, bval, bvec, frf, [], [], []] }

    FRF( ch_input_frf )
    ch_frf = FRF.out.frf

    // 6. Compute FODF
    ch_input_fodf = ch_dwi_upsampled
        .join( ch_nii_bval_bvec.bval )
        .join( ch_nii_bval_bvec.bvec )
        .join( ch_fa_mask )
        .join( DTI.out.fa )
        .join( DTI.out.md )
        .join( ch_frf )
        .map{ it + [[], []] }

    FODF ( ch_input_fodf )

}