nextflow.enable.dsl=2

process CONSENSUSFILEFILTER {

  input:
    path consensusXML

  output:
    path "${consensusXML.toString()[0..14]}_filtered.consensusXML"
  
  script:
  """
  FileFilter -in $consensusXML \\
              -out ${consensusXML.toString()[0..14]}_filtered.consensusXML \\
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
  FileFilter -in $consensusXML \\
              -out ${consensusXML.toString()[0..14]}_filtered.consensusXML \\
              -id:remove_unannotated_features
  GNPSExport.py ${consensusXML.toString()[0..14]}_filtered.consensusXML $aligned_mzMLs MS2.mgf FeatureQuantification.txt SupplementaryPairs.csv MetaValues.tsv
  """
}

workflow gnps {
  take:
    ch_mzMLs
    ch_consensus

  main:
    GNPSEXPORT(ch_mzMLs.collect(), ch_consensus)
}