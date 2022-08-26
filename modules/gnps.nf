nextflow.enable.dsl=2

process CONSENSUSFILEFILTER {

  input:
    path consensusXML

  output:
    path consensusXML
  
  script:
  """
  FileFilter -in $consensusXML \\
              -out $consensusXML \\
              -id:remove_unannotated_features 
  """
}

process GNPSEXPORT {

  label "publish_gnps"

  input:
    path aligned_mzMLs
    path consensusXML
  
  output:
    path "MS2.mgf"
    path "FeatureQuantification.txt"
    path "SupplementaryPairs.csv"
    path "MetaValues.tsv"

  script:
  """
  GNPSExport.py $consensusXML $aligned_mzMLs MS2.mgf FeatureQuantification.txt SupplementaryPairs.csv MetaValues.tsv
  """
}

workflow gnps {
  take:
    ch_mzMLs
    ch_consensus

  main:
    CONSENSUSFILEFILTER(ch_consensus)
    GNPSEXPORT(ch_mzMLs.collect(), CONSENSUSFILEFILTER.out)
}