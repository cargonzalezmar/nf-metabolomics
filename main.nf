nextflow.enable.dsl=2

include { preprocessing } from "./modules/preprocessing.nf"
include { gnps } from "./modules/gnps.nf"
include { sirius } from "./modules/sirius.nf"

workflow {
    Channel.fromPath(params.mzML_files) | preprocessing

    if (params.GNPSExport)
    {
      gnps(preprocessing.out[0], preprocessing.out[2])
    }

    if (params.Sirius_enabled)
    {
      sirius(preprocessing.out[0], preprocessing.out[1], preprocessing.out[2])
    }
}


