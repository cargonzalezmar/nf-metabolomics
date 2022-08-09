nextflow.enable.dsl=2
params.mzML_files = "/home/axel/Nextcloud/workspace/MetabolomicsWorkflowMayer/mzML/*.mzML"

ch_mzML_files = Channel.fromPath(params.mzML_files)

process FEATUREDETECTION {
   tag "$sample"

   input:
   path mzML

   output:
   path "${mzML.toString()[0..-6]}.featureXML"
   
   script:
   """     
   FeatureFinderMetabo -in ${mzML} -out "${mzML.toString()[0..-6]}.featureXML" -algorithm:common:noise_threshold_int 10000 -algorithm:mtd:mass_error_ppm 10 -algorithm:ffm:remove_single_traces true
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

process TEXTEXPORT {
    input:
    path consensus_file

    output:
    path "features.tsv" 

    script:
    """
    TextExporter -in ${consensus_file} -out features.tsv -consensus:add_metavalues
    """
}

workflow {
    ch_feature_files = FEATUREDETECTION(ch_mzML_files)
    ch_consensus = FEATURELINKING(ch_feature_files.toList())
    TEXTEXPORT(ch_consensus)
}