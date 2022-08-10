nextflow.enable.dsl=2

params.mzML_files = "/home/cargonzalezmar/Documents/example_data/*.mzML"

ch_mzML_files = Channel.fromPath(params.mzML_files)

process FEATUREDETECTION {
   tag "$sample"

   input:
   path mzML

   output:
   path "${mzML.toString()[0..-6]}.featureXML"
   
   script:
   """     
   FeatureFinderMetabo -in $mzML -out "${mzML.toString()[0..-6]}.featureXML" -algorithm:common:noise_threshold_int $params.noise_threshold_int -algorithm:mtd:mass_error_ppm $params.mass_error_ppm -algorithm:ffm:remove_single_traces $params.remove_single_traces
   """
}

process FEATURELINKING {
    input:
    path featureXML_list

    output:
    path "linked.consensusXML"

    script:
    """
    FeatureLinkerUnlabeledKD -in ${featureXML_list} -out linked.consensusXML -algorithm:link:rt_tol 30.0 -algorithm:link:mz_tol 10.0
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
    ch_feature_files = FEATUREDETECTION(ch_mzML_files)
    ch_consensus = FEATURELINKING(ch_feature_files.toList())
    TEXTEXPORTPY(ch_consensus).view()
}