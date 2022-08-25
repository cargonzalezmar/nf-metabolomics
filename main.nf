nextflow.enable.dsl=2

include { MZMLDATAFRAME; FEATUREXMLDATAFRAME; CONSENSUSXMLDATAFRAME } from "./modules/dataframes.nf"
include { GNPSPREPARATION; CONSENSUSFILEFILTER; GNPSEXPORT } from "./modules/gnps.nf"
include { FEATUREDETECTION; FEATUREMAPALIGNMENT; ADDUCTDETECTION; FEATURELINKING } from "./modules/preprocessing.nf"
include { SIRIUS } from "./modules/sirius.nf"

workflow {
    ch_mzMLs = Channel.fromPath(params.mzML_files)

    ch_featureXMLs = FEATUREDETECTION(ch_mzMLs)

    (ch_featureXMLs, ch_trafoXMLs) = FEATUREMAPALIGNMENT(ch_featureXMLs.collect(), ch_featureXMLs.collect({"${it.toString()[0..-11]}trafoXML"}))
    
    if (params.GNPSExport)
    {   
        (ch_featureXMLs, ch_mzMLs) = GNPSPREPARATION(ch_mzMLs.collect().sort().flatten(), ch_featureXMLs.sort().flatten(), ch_trafoXMLs.sort().flatten())
    }
    
    MZMLDATAFRAME(ch_mzMLs)

    if (params.AdductDetection_enabled)
    {
        ch_featureXMLs = ADDUCTDETECTION(ch_featureXMLs)
    }
    
    FEATUREXMLDATAFRAME(ch_featureXMLs)

    ch_consensus = FEATURELINKING(ch_featureXMLs.collect()) 
    CONSENSUSXMLDATAFRAME(ch_consensus)

    if (params.Sirius_enabled)
    {
        (ch_formulas, ch_structures) = SIRIUS(ch_mzMLs, ch_featureXMLs)
    }

    if (params.GNPSExport)
    {
      ch_consensus = CONSENSUSFILEFILTER(ch_consensus)
      GNPSEXPORT(ch_mzMLs.collect(), ch_consensus)
    }
}
