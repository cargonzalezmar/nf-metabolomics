nextflow.enable.dsl=2

include { MZMLDATAFRAME; FEATUREXMLDATAFRAME; CONSENSUSXMLDATAFRAME } from "./dataframes.nf"

process FEATUREDETECTION {

  tag "$mzML"

  input:
    path mzML

  output:
    path "${mzML.toString()[0..-6]}.featureXML"
    path "${mzML.toString()[0..-6]}_chrom.mzML"
  
  script:
  """
  FeatureFinderMetabo -in $mzML \\
                      -out ${mzML.toString()[0..-6]}.featureXML \\
                      -out_chrom ${mzML.toString()[0..-6]}_chrom.mzML \\
                      -algorithm:common:noise_threshold_int $params.FeatureDetection_noise_threshold_int \\
                      -algorithm:mtd:mass_error_ppm $params.FeatureDetection_mass_error_ppm \\
                      -algorithm:ffm:remove_single_traces $params.FeatureDetection_remove_single_traces \\
                      -algorithm:ffm:report_convex_hulls $params.FeatureDetection_report_EICs
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

process ANNOTATEMS2 {
  tag "$mzML $featureXML $trafoXML"

  input:
    path mzML
    path featureXML
    path trafoXML
  
  output:
    path featureXML
    path "${mzML.toString()[0..-6]}_aligned.mzML"

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

process FEATURELINKING {

  tag "$featureXML_list"

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

def split_path(path) {
    return path.toString().split("/")[-1]
}

workflow openms {
  take: 
    ch_mzMLs
  
  main:
    FEATUREDETECTION(ch_mzMLs)

    FEATUREMAPALIGNMENT(FEATUREDETECTION.out[0].collect(), FEATUREDETECTION.out[0].collect({"${it.toString()[0..-11]}trafoXML"}))
    
    ANNOTATEMS2(ch_mzMLs.collect().sort({p -> split_path(p)}).flatten(),
                FEATUREMAPALIGNMENT.out[0].sort({p -> split_path(p)}).flatten(),
                FEATUREMAPALIGNMENT.out[1].sort({p -> split_path(p)}).flatten())

    MZMLDATAFRAME(ANNOTATEMS2.out[1])

    if (params.AdductDetection)
    {
      ch_features = ADDUCTDETECTION(ANNOTATEMS2.out[0])
    }
    else
    {
      ch_features = ANNOTATEMS2.out[0]
    }

    FEATUREXMLDATAFRAME(ch_features.collect().sort(p -> split_path(p)).flatten(), 
                        FEATUREDETECTION.out[1].collect().sort(p -> split_path(p)).flatten())

    FEATURELINKING(ch_features.collect())
    CONSENSUSXMLDATAFRAME(FEATURELINKING.out)

  emit:
    ANNOTATEMS2.out[1]
    ch_features
    FEATURELINKING.out
    CONSENSUSXMLDATAFRAME.out
}