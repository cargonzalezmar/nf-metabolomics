nextflow.enable.dsl=2

process MZMLDATAFRAME {

  tag "$mzML"
  label "publish_ms_df"

  input:
    path mzML

  output:
    path "${mzML.toString()[0..-14]}.pkl"

  script:
  """
    mzML_to_dataframe.py $mzML ${mzML.toString()[0..-14]}.pkl
  """

}

process FEATUREXMLDATAFRAME {

  tag "$featureXML $chrom_mzML"
  label "publish_featuremap_df"

  input:
    path featureXML
    path chrom_mzML

  output:
    path "${featureXML.toString()[0..-12]}fm.pkl"

  script:
  """
    featuremap_to_df.py $featureXML $chrom_mzML ${featureXML.toString()[0..-12]}fm.pkl
  """
}

process CONSENSUSXMLDATAFRAME {

  input:
    path consensus_file

  output:
    path "FeatureMatrix.pkl"

  script:
  """
  consensus_map_to_dataframe.py $consensus_file "FeatureMatrix.pkl"
  """
}

process PUBLISHFEATUREMATRIX {

  label "publish_main"

  input:
    path feature_matrix

  output:
    path feature_matrix
    path "FeatureMatrix.tsv"

  script:
  """
  publish_feature_matrix.py $feature_matrix FeatureMatrix.tsv
  """
}


process PUBLISHCOMPOUNDSVG {

  label "publish_main"

  input:
    path feature_matrix

  output:
    path feature_matrix
    path "PredCompoundsSVG.pkl"

  script:
  """
  smile_to_svg.py $feature_matrix PredCompoundsSVG.pkl
  """
}