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

    # ANATOMY
    t1w = create_key('sub-{subject}/anat/sub-{subject}_run-{item:01d}_T1w')
    
    # DWI
    dwi_ap = create_key('sub-{subject}/dwi/sub-{subject}_dir-AP_run-{item:01d}_dwi')
    dwi_pa = create_key('sub-{subject}/dwi/sub-{subject}_dir-PA_run-{item:01d}_dwi')
    
    # fMRI
    rest_ap = create_key('sub-{subject}/func/sub-{subject}_task-rest_dir-AP_run-{item:01d}_bold')
    
    # FIELDMAP/s
    fmap_se_ap = create_key('sub-{subject}/fmap/sub-{subject}_acq-se_dir-AP_run-{item:01d}_epi')
    fmap_se_pa = create_key('sub-{subject}/fmap/sub-{subject}_acq-se_dir-PA_run-{item:01d}_epi')
    fmap_gre_mag = create_key('sub-{subject}/fmap/sub-{subject}_acq-gre_run-{item:01d}_magnitude')
    fmap_gre_phase = create_key('sub-{subject}/fmap/sub-{subject}_acq-gre_run-{item:01d}_phasediff')
    
    info = {t1w: [], dwi_ap: [], dwi_pa: [], rest_ap: [], fmap_se_ap: [], fmap_se_pa: [], fmap_gre_mag: [], fmap_gre_phase: []}
    
    for idx, s in enumerate(seqinfo):
        
        
        # ANATOMY
        # T1w
        if ('t1_mprage_sag_p2_iso_1.0' in s.series_description):
            info[t1w].append(s.series_id) # assign if a single series meets criteria
            
            
        # FIELDMAP/s
        # gre-fieldmap
        if ('gre_field_mapping_3mm' in s.series_description) and (s.image_type[2] == 'M') and ('NORM' in s.image_type):
            # magnitude image
            info[fmap_gre_mag].append(s.series_id) #     
        if ('gre_field_mapping_3mm' in s.series_description) and (s.image_type[2] == 'P'):
            # phase image
            info[fmap_gre_phase].append(s.series_id) #
            
        # se-fieldmap
        if ('ep2d_se_phase_PA_2meas' in s.series_description):
            info[fmap_se_pa].append(s.series_id) # assign if a single series meets criteria
        if ('ep2d_se_phase_AP_2meas' in s.series_description):
            info[fmap_se_ap].append(s.series_id) # assign if a single series meets criteria
        
        
        # Resting-state fMRI
        # include is_derived = FALSE as additional criteria
        if ('ep2d_bold_moco_p4_3mm_AP_2170' in s.series_description) and not (s.is_derived):
            info[rest_ap].append(s.series_id) # assign if a single series meets criteria
        
        
        # DIFFUSION
        # dir AP
        # include is_derived = FALSE as additional criteria
        if ('ep2d_diff_b2600_iso2p3_phase_AP_43dir' in s.series_description) and not (s.is_derived):
            info[dwi_ap].append(s.series_id) # append if multiple series meet criteria
        # dir PA
        # include is_derived = FALSE as additional criteria
        if ('ep2d_diff_b2600_iso2p3_phase_PA_42dir' in s.series_description) and not (s.is_derived):
            info[dwi_pa].append(s.series_id) # append if multiple series meet criteria 
            
            
    return info
