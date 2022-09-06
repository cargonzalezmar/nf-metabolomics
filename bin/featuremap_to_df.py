#!/usr/bin/env python

import sys
from pyopenms import *

fm = FeatureMap()
FeatureXMLFile().load(sys.argv[1], fm)

df = fm.get_df(meta_values=["MS2_spectra".encode()], export_peptide_identifications = False)

# annotate fm with MS2 scan numbers
scan_list = []
for f in fm:
    # get MS2 scan numbers from PeptideIdentifications
    peps = f.getPeptideIdentifications()
    scans = []
    if peps:
        for pep in peps:
            scans.append(pep.getMetaValue("spectrum_index"))
    scan_list.append(scans)
df["MS2_spectra"] = scan_list

# annotate chromatogram data
df["chroms"] = [[] for _ in range(len(df))]
exp = MSExperiment()
MzMLFile().load(sys.argv[2], exp)
chroms = exp.getChromatograms()
for chrom in chroms:
    feature_id = chrom.getNativeID().split("_")[0]
    df.loc[feature_id, ["chroms"]][0] = df.loc[feature_id, ["chroms"]][0].append(
        {
        "rt": [peak.getRT() for peak in chrom],
        "intensity": [peak.getIntensity() for peak in chrom]
        })

df.to_pickle(sys.argv[3])