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
   -out "${mzML.toString()[0..-6]}.featureXML" \\
   -algorithm:common:noise_threshold_int $params.FeatureDetection_noise_threshold_int \\
   -algorithm:mtd:mass_error_ppm $params.FeatureDetection_mass_error_ppm \\
   -algorithm:ffm:remove_single_traces $params.FeatureDetection_remove_single_traces
   """
}

process FEATUREMAPALIGNMENT {

    input:
    path featureXMLs
    path featureXMLs_aligned
    path trafoXMLs

    output:
    path featureXMLs
    path featureXMLs_aligned
    path trafoXMLs

    script:
    """
    MapAlignerPoseClustering \\
    -in $featureXMLs \\
    -out $featureXMLs_aligned \\
    -trafo_out $trafoXMLs
    """
}

process FEATURELINKING {

    input:
    path featureXML_list

    output:
    path "linked.consensusXML"

    script:
    """
    FeatureLinkerUnlabeledKD \\
    -in $featureXML_list \\
    -out linked.consensusXML \\
    -algorithm:link:rt_tol $params.FeatureLinking_link_rt_tol
    -algorithm:link:mz_tol $params.FeatureLinking_link_mz_tol
    """
} 

process TEXTEXPORTPY {

    input:
    path consensus_file

    output:
    stdout

    script:
    """
    term_export.py $consensus_file
    """
}

workflow {
    ch_mzMLs = Channel.fromPath(params.mzML_files)
    ch_featureXMLs = FEATUREDETECTION(ch_mzMLs)
    (ch_featureXMLs, ch_featureXMLs_aligned, ch_trafo) = FEATUREMAPALIGNMENT(ch_featureXMLs.collect(), 
                                                        ch_featureXMLs.map( {it.toString().replaceAll(".featureXML", "_aligned.featureXML")} ).collect(),
                                                        ch_featureXMLs.map( {it.toString().replaceAll(".featureXML", ".trafoXML")} ).collect())
    TEXTEXPORTPY(ch_consensus).view()
}