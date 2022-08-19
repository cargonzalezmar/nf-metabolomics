#!/usr/bin/env python

import sys
from pyopenms import *

fm = FeatureMap()
FeatureXMLFile().load(sys.argv[1], fm)
fm_annotated = FeatureMap(fm)
fm_annotated.clear(False)
for f in fm:
    # get MS2 scan numbers from PeptideIdentifications
    peps = f.getPeptideIdentifications()
    if peps:
        scans = ""
        for pep in peps:
            scans = scans + str(pep.getMetaValue("spectrum_index")) + ","
        f.setMetaValue("MS2_spectra", scans)
    fm_annotated.push_back(f)

df = fm_annotated.get_df(meta_values=["MS2_spectra".encode()], export_peptide_identifications = False)
df.to_csv(sys.argv[2], sep="\t")