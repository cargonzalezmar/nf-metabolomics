nextflow.enable.dsl=2

include { preprocessing } from "./modules/preprocessing.nf"
include { gnps } from "./modules/gnps.nf"
include { sirius } from "./modules/sirius.nf"

workflow {
    ch_mzMLs = Channel.fromPath(params.mzML_files)

    (ch_mzMLs, ch_featureXMLs, ch_consensus) = preprocessing(ch_mzMLs)

    if (params.GNPSExport)
    {
      gnps(ch_mzMLs, ch_consensus)
    }

    if (params.Sirius_enabled)
    {
        (ch_formulas, ch_structures) = sirius(ch_mzMLs, ch_featureXMLs)
    }
}


