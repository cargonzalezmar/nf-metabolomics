nextflow.enable.dsl=2

process FEATUREDETECTION {

  tag "$mzML"

  input:
    path mzML

  output:
    path "${mzML.toString()[0..-6]}.featureXML"
  
  script:
  """
  FeatureFinderMetabo -in $mzML \\
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
  MapAlignerPoseClustering -in $featureXMLs \\
                            -out $featureXMLs \\
                            -trafo_out $trafoXMLs \\
                            -algorithm:pairfinder:distance_MZ:max_difference $params.FeatureMapAlignment_distance_MZ_max_difference \\
                            -algorithm:pairfinder:distance_MZ:unit $params.FeatureMapAlignment_distance_MZ_unit
  """
}

process GNPSPREPROCESSING {
  tag "$mzML $featureXML $trafoXML"

  input:
    path mzML
    path featureXML
    path trafoXML
  
  output:
    path featureXML

  script:
  """
  MapRTTransformer -in $mzML \\
                    -out ${mzML.toString()[0..-6]}_aligned.mzML \\
                    -trafo_in $trafoXML
  IDMapper -id $projectDir/resources/empty.idXML \\
            -in $featureXML \\
            -spectra:in ${mzML.toString()[0..-6]}_aligned.mzML \\
            -out $featureXML
  """ 
}

process ADDUCTDETECTION {

  tag "$featureXML"

  input:
    path featureXML

  output:
    path featureXML

  script:
  """
  MetaboliteAdductDecharger -in $featureXML \\
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
  FeatureLinkerUnlabeledKD -in $featureXML_list \\
                            -out FeatureMatrix.consensusXML \\
                            -algorithm:link:rt_tol $params.FeatureLinking_link_rt_tol \\
                            -algorithm:link:mz_tol $params.FeatureLinking_link_mz_tol
  """
} 

process TEXTEXPORTPY {
  
  tag "dataframe export"

  cpus 2

  memory "4 GB"

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

    (ch_featureXMLs, ch_trafoXMLs) = FEATUREMAPALIGNMENT(ch_featureXMLs.collect(), ch_featureXMLs.collect({"${it.toString()[0..-11]}trafoXML"}))
    
    if (params.GNPSExport)
    {   
        ch_featureXMLs = GNPSPREPROCESSING(ch_mzMLs.collect().sort().flatten(), ch_featureXMLs.sort().flatten(), ch_trafoXMLs.sort().flatten())
    }
    
    if (params.AdductDetection_enabled)
    {
        ch_featureXMLs = ADDUCTDETECTION(ch_featureXMLs)
    }
    
    FEATURELINKING(ch_featureXMLs.collect()) | TEXTEXPORTPY
}
