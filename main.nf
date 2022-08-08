nextflow.enable.dsl=2

params.mzML_files = "/home/axel/Nextcloud/workspace/MetabolomicsWorkflowMayer/mzML/*.mzML"

ch_mzML_files = Channel.fromPath(params.mzML_files)

process FEATUREDETECTION {
   input:
   path sample

   output:
   path 'features'
   
   script:
   """     
   FeatureFinderMetabo -in ${sample} -out features -algorithm:common:noise_threshold_int 10000 -algorithm:mtd:mass_error_ppm 10 -algorithm:ffm:remove_single_traces true
   """
}

workflow {
    ch_feature_files = FEATUREDETECTION(ch_mzML_files)   
    ch_feature_files.view()
}