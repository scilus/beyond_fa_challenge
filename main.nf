#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { CONVERT_CHALLENGE_INPUTS       } from "./modules/local/utils/convert"
include { IMAGE_RESAMPLE as RESAMPLE     } from "./modules/nf-neuro/image/resample"
include { BETCROP_FSLBETCROP as BET      } from "./modules/nf-neuro/betcrop/fslbetcrop"
include { RECONST_DTIMETRICS as DTI_POST_FW      } from './modules/nf-neuro/reconst/dtimetrics'
include { REGISTRATION                   } from "./subworkflows/nf-neuro/registration"
include { REGISTRATION_ANTSAPPLYTRANSFORMS as TRANSFORM_LABELS_TO_SUBJECT } from './modules/nf-neuro/registration/antsapplytransforms/main'
include { RECONST_FRF as FRF             } from './modules/nf-neuro/reconst/frf'
include { VOLUME_MATH as FA_LTHRESHOLD;
          VOLUME_MATH as FA_UTHRESHOLD;
          VOLUME_MATH as FA_HOLEFILL     } from './modules/local/volume_math/single.nf'
include { VOLUME_MATH as FA_INTERSECTION } from './modules/local/volume_math/double.nf'
include { RECONST_FODF as FODF           } from './modules/nf-neuro/reconst/fodf'
include { RECONST_FREEWATER as FW        } from './modules/nf-neuro/reconst/freewater'
include { BUNDLEPARC as BUNDLEPARC       } from './modules/local/fodf/bundleparc' 


workflow {
    ch_in_jhu_labels = Channel.fromFilePairs("$projectDir/data/JHU/JHU-ICBM-labels-1mm.nii.gz", size: 1, flat: true)
    ch_in_jhu_fa = Channel.fromFilePairs("$projectDir/data/JHU/JHU-ICBM-FA-1mm.nii.gz", size: 1, flat: true)

    ch_in_mha_json = Channel.fromFilePairs("$params.input/**/*.{mha,json}", size: 2, flat: true)
        { file(it).simpleName.tokenize("_")[0..1].join("_") }
        .map{ id, json, mha -> [[id: id], mha, json] }

    ch_in_nifti_bvalbvec = CONVERT_CHALLENGE_INPUTS( ch_in_mha_json )

    // 2. Upsample DWI
    ch_dwi_to_upsample = ch_in_nifti_bvalbvec.dwi
        .map{ meta, dwi -> [meta, dwi, []] }

    RESAMPLE( ch_dwi_to_upsample )
    ch_dwi_resampled = RESAMPLE.out.image

    // 3. Compute BET mask
    ch_dwi_to_bet = ch_dwi_resampled
        .join( ch_in_nifti_bvalbvec.bval )
        .join( ch_in_nifti_bvalbvec.bvec )
    BET ( ch_dwi_to_bet )
    ch_bet_mask = BET.out.mask

    // 4. Compute Freewater
    ch_in_fw = ch_dwi_resampled
        .join( ch_in_nifti_bvalbvec.bval )
        .join( ch_in_nifti_bvalbvec.bvec )
        .join( ch_bet_mask )
        .map{ meta, dwi, bval, bvec, mask -> [meta, dwi, bval, bvec, mask, []] }

    FW ( ch_in_fw )

    // 4. Extract FA for template registration + frf masking
    ch_fa = FW.out.dwi_fw_corrected
        .join( ch_in_nifti_bvalbvec.bval )
        .join( ch_in_nifti_bvalbvec.bvec )
        .join( ch_bet_mask )

    DTI_POST_FW( ch_fa )

    // 5. Register to MNI
    ch_moving = ch_dwi_resampled
        .map{ meta, _dwi -> [meta] }
        .combine( ch_in_jhu_fa.map{ _meta, template -> [template] } )
    ch_fixed = DTI_POST_FW.out.fa

    // I had to flip fixed and moving to fix the results (error to fix)
    REGISTRATION(
        ch_fixed,
        ch_moving,
        Channel.empty(),
        Channel.empty(),
        Channel.empty(),
        Channel.empty()
    )

    // 5.1 Apply registration to JHU labels
    ch_jhu_labels = REGISTRATION.out.image_warped
        .join( REGISTRATION.out.transfo_image )
        .combine( ch_in_jhu_labels )
        .map{ meta, warped, nonlinear, linear, _jhu_id, jhu_labels ->
            [meta, jhu_labels, warped, nonlinear, linear] }
    TRANSFORM_LABELS_TO_SUBJECT( ch_jhu_labels )

    // 6. Threshold FA to get FRF mask
    ch_fa_to_threshold = DTI_POST_FW.out.fa
    FA_LTHRESHOLD( ch_fa_to_threshold )
    ch_frf_mask = FA_LTHRESHOLD.out.image

    // 7. Compute FRF
    ch_input_frf = ch_dwi_resampled
        .join( ch_in_nifti_bvalbvec.bval )
        .join( ch_in_nifti_bvalbvec.bvec )
        .join( ch_frf_mask )
        .map{ meta, dwi, bval, bvec, mask -> [meta, dwi, bval, bvec, mask, [], [], []] }

    FRF( ch_input_frf )
    ch_frf = FRF.out.frf

    // 8. Compute FODF
    ch_input_fodf = ch_dwi_resampled
        .join( ch_in_nifti_bvalbvec.bval )
        .join( ch_in_nifti_bvalbvec.bvec )
        .join( ch_bet_mask )
        .join( DTI_POST_FW.out.fa )
        .join( DTI_POST_FW.out.md )
        .join( ch_frf )
        .map{ it + [[], []] }

    FODF ( ch_input_fodf )

    // 11. BundleParc
    ch_fodf = FODF.out.fodf
    BUNDLEPARC ( ch_fodf )
}
