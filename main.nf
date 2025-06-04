include { IMAGE_RESAMPLE as UPSAMPLE     } from "./modules/nf-neuro/image/resample"
include { RECONST_DTIMETRICS as DTI      } from './modules/nf-neuro/reconst/dtimetrics'  
include { REGISTRATION                   } from "./subworkflows/nf-neuro/registration"
include { RECONST_FRF as FRF             } from './modules/nf-neuro/reconst/frf'
include { VOLUME_MATH as FA_LTHRESHOLD;
          VOLUME_MATH as FA_UTHRESHOLD;
          VOLUME_MATH as FA_HOLEFILL     } from './modules/local/volume_math/single.nf'
include { VOLUME_MATH as FA_INTERSECTION } from './modules/local/volume_math/double.nf'
include { RECONST_FODF as FODF           } from './modules/nf-neuro/reconst/fodf' 
include { CONVERT_CHALLENGE_INPUTS } from './modules/local/utils/convert.nf'


workflow {
    ch_in_jhu_t1 = Channel.fromFilePairs("$projectDir/data/JHU/JHU-ICBM-T1-1mm.nii.gz")
        { "JHU" }
    ch_in_jhu_fa = Channel.fromFilePairs("$projectDir/data/JHU/JHU-ICBM-FA-1mm.nii.gz")
        { "JHU" }

    ch_in_mha_json = Channel.fromFilePairs("$params.input/**/*.{mha,json}", size: 2, flat: true)
        { file(it).simpleName.tokenize("_")[0..1].join("_") }
        .map{ id, json, mha -> [[id: id], mha, json] }

    ch_in_nifti_bvalbvec = CONVERT_CHALLENGE_INPUTS( ch_in_mha_json )

    // 2. Upsample DWI
    ch_dwi_to_upsample = ch_in_nifti_bvalbvec.dwi
        .map{ meta, dwi -> [meta, dwi, []] }

    UPSAMPLE( ch_dwi_to_upsample )
    ch_dwi_upsampled = UPSAMPLE.out.image

    // 3. Extract b0 for template registration
    ch_fa = ch_dwi_upsampled
        .join( ch_in_nifti_bvalbvec.bval )
        .join( ch_in_nifti_bvalbvec.bvec )
        .map{ meta, dwi, bval, bvec -> [meta, dwi, bval, bvec, []] }

    DTI( ch_fa )

    // 3. Register to MNI
    ch_moving = ch_dwi_upsampled
        .map{ meta, _dwi -> [meta] }
        .combine( ch_in_jhu_fa.map{ _meta, template -> [template] } )
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
    FA_LTHRESHOLD( ch_fa_to_threshold )
    FA_UTHRESHOLD( ch_fa_to_threshold )

    ch_fa_to_intersect = FA_LTHRESHOLD.out.image
        .join( FA_UTHRESHOLD.out.image )        
    FA_INTERSECTION( ch_fa_to_intersect )
    FA_HOLEFILL( FA_INTERSECTION.out.image )
    ch_fa_mask = FA_HOLEFILL.out.image

    // 5. Compute FRF
    ch_input_frf = ch_dwi_upsampled
        .join( ch_in_nifti_bvalbvec.bval )
        .join( ch_in_nifti_bvalbvec.bvec )
        .join( ch_fa_mask )
        .map{ meta, dwi, bval, bvec, frf -> [meta, dwi, bval, bvec, frf, [], [], []] }

    FRF( ch_input_frf )
    ch_frf = FRF.out.frf

    // 6. Compute FODF
    ch_input_fodf = ch_dwi_upsampled
        .join( ch_in_nifti_bvalbvec.bval )
        .join( ch_in_nifti_bvalbvec.bvec )
        .join( ch_fa_mask )
        .join( DTI.out.fa )
        .join( DTI.out.md )
        .join( ch_frf )
        .map{ it + [[], []] }

    FODF ( ch_input_fodf )

}
