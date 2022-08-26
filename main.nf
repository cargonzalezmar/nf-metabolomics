nextflow.enable.dsl=2

include { openms } from "./modules/openms.nf"
include { gnps } from "./modules/gnps.nf"
include { sirius } from "./modules/sirius.nf"

workflow {
    Channel.fromPath(params.mzML_files) | openms

    if (params.Sirius_enabled)
    {
      sirius(openms.out[0], openms.out[1], openms.out[2])
    }

    if (params.GNPSExport)
    {
      gnps(openms.out[0], openms.out[2])
    }
}


