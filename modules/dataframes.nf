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

  tag "$featureXML"
  label "publish_featuremap_df"

  input:
    path featureXML

  output:
    path "${featureXML.toString()[0..-12]}fm.pkl"

  script:
  """
    featuremap_to_df.py $featureXML ${featureXML.toString()[0..-12]}fm.pkl
  """
}

process CONSENSUSXMLDATAFRAME {
  
  tag "dataframe export"

  label "publish_main"

  input:
    path consensus_file

  output:
    path "FeatureMatrix.tsv"

  script:
  """
  consensus_map_to_dataframe.py $consensus_file "FeatureMatrix.tsv"
  """
}