nextflow.enable.dsl=2

process FEATUREDETECTION {

   input:
   path mzML

   output:
   path "${mzML.toString()[0..-6]}.featureXML"
   
   script:
   """
   FeatureFinderMetabo \\
   -in $mzML \\
   -out ${mzML.toString()[0..-6]}.featureXML \\
   -algorithm:common:noise_threshold_int $params.FeatureDetection_noise_threshold_int \\
   -algorithm:mtd:mass_error_ppm $params.FeatureDetection_mass_error_ppm \\
   -algorithm:ffm:remove_single_traces $params.FeatureDetection_remove_single_traces
   """
}

process FEATUREMAPALIGNMENT {

    input:
    path featureXMLs
    path trafoXMLs

    output:
    path featureXMLs
    path trafoXMLs

    script:
    """
    MapAlignerPoseClustering \\
    -in $featureXMLs \\
    -out $featureXMLs \\
    -trafo_out $trafoXMLs \\
    -algorithm:pairfinder:distance_MZ:max_difference $params.FeatureMapAlignment_distance_MZ_max_difference \\
    -algorithm:pairfinder:distance_MZ:unit $params.FeatureMapAlignment_distance_MZ_unit
    """
}

process PEAKMAPTRANSFORMATION {

    input:
    path mzML
    path trafoXML

    output:
    path "${mzML.toString()[0..-6]}_aligned.mzML"

    script:
    """
    MapRTTransformer \\
    -in $mzML \\
    -out ${mzML.toString()[0..-6]}_aligned.mzML \\
    -trafo_in $trafoXML
    """
}

process IDMAPPING {

    input:
    path mzML
    path featureXML

    output:
    path featureXML

    script:
    """
    IDMapper \\
    -id $projectDir/resources/empty.idXML \\
    -in $featureXML \\
    -spectra:in $mzML \\
    -out $featureXML
    """
}

process ADDUCTDETECTION {

    input:
    path featureXML

    output:
    path featureXML

    script:
    """
    MetaboliteAdductDecharger \\
    -in $featureXML \\
    -out_fm $featureXML \\
    -algorithm:MetaboliteFeatureDeconvolution:potential_adducts $params.AdductDetection_adducts \\
    -algorithm:MetaboliteFeatureDeconvolution:retention_max_diff $params.AdductDetection_RT_tolerance
    """
}


process FEATURELINKING {

    label "publish"

    input:
    path featureXML_list

    output:
    path "FeatureMatrix.consensusXML"

    script:
    """
    FeatureLinkerUnlabeledKD \\
    -in $featureXML_list \\
    -out FeatureMatrix.consensusXML \\
    -algorithm:link:rt_tol $params.FeatureLinking_link_rt_tol \\
    -algorithm:link:mz_tol $params.FeatureLinking_link_mz_tol
    """
} 

process TEXTEXPORTPY {
    
    label "publish"

    input:
    path consensus_file

    output:
    path "FeatureMatrix.tsv"

    script:
    """
    consensus_map_to_dataframe.py $consensus_file "FeatureMatrix.tsv"
    """
}

workflow {
    ch_mzMLs = Channel.fromPath(params.mzML_files)

    ch_featureXMLs = FEATUREDETECTION(ch_mzMLs)

    (ch_featureXMLs, ch_trafoXMLs) = FEATUREMAPALIGNMENT(ch_featureXMLs.collect(), ch_featureXMLs.map( {it.toString().replaceAll(".featureXML", ".trafoXML")} ).collect())
    
    if (params.GNPSExport)
    {   
        ch_featureXMLs_sorted = ch_featureXMLs.sort().flatten()
        ch_mzMLs_sorted = ch_mzMLs.collect().sort().flatten()
        ch_trafoXMLs_sorted = ch_trafoXMLs.sort().flatten()

        ch_mzMLs = PEAKMAPTRANSFORMATION(ch_mzMLs_sorted, ch_trafoXMLs_sorted)
        ch_featureXMLs = IDMAPPING(ch_mzMLs_sorted, ch_featureXMLs_sorted)
    }
    
    if (params.AdductDetection_enabled)
    {
        ch_featureXMLs = ADDUCTDETECTION(ch_featureXMLs)
    }
    
    ch_consensus = FEATURELINKING(ch_featureXMLs.collect())
    
    TEXTEXPORTPY(ch_consensus)
}
