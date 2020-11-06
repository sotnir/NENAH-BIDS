import os


def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes


def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where

    allowed template fields - follow python string module:

    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """

    t1w = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_run-{item:03d}_T1w')
    flair = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_run-{item:03d}_FLAIR')
    t2w = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_run-{item:03d}_T2w')
    info = {t1w: [], flair: [], t2w: []}
    last_run = len(seqinfo)

    for idx, s in enumerate(seqinfo):
        """
        The namedtuple `s` contains the following fields:

        * total_files_till_now
        * example_dcm_file
        * series_id
        * dcm_dir_name
        * unspecified2
        * unspecified3
        * dim1
        * dim2
        * dim3
        * dim4
        * TR
        * TE
        * protocol_name
        * is_motion_corrected
        * is_derived
        * patient_id
        * study_description
        * referring_physician_name
        * series_description
        * image_type
        """
    # ANATOMY
    # T1W
        if ('t1_mprage_ax_p2_iso_1.0' in s.series_description):
            info[t1w].append(s.series_id)
    # FLAIR
        if ('t2_spc_da-fl_ax_p2' in s.series_description):
            info[flair].append(s.series_id)
    # T2
        if ('pd+t2_tse_ax' in s.series_description):
            info[t2w].append(s.series_id)
    return info
