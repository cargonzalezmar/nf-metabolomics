nextflow.enable.dsl=2

process GNPSPREPARATION {
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