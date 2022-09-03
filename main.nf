nextflow.enable.dsl=2

include { openms } from "./modules/openms.nf"
include { gnpsexport } from "./modules/gnps.nf"
include { sirius } from "./modules/sirius.nf"
include { PUBLISHFEATUREMATRIX } from "./modules/dataframes.nf"

workflow {
    Channel.fromPath(params.mzML_files) | openms

    if (params.Sirius)
    {
      sirius(openms.out[0], openms.out[1], openms.out[3])
      PUBLISHFEATUREMATRIX(sirius.out[2])
    }
    else
    {
      PUBLISHFEATUREMATRIX(openms.out[3])
    }

    if (params.GNPSExport)
    {
      gnpsexport(openms.out[0], openms.out[2])
    }
}


