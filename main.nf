nextflow.enable.dsl=2

include { openms } from "./modules/openms.nf"
include { gnpsexport } from "./modules/gnps.nf"
include { sirius } from "./modules/sirius.nf"

workflow {
    Channel.fromPath(params.mzML_files) | openms

    if (params.Sirius)
    {
      sirius(openms.out[0], openms.out[1], openms.out[2])
    }

    if (params.GNPSExport)
    {
      gnpsexport(openms.out[0], openms.out[2])
    }
}


