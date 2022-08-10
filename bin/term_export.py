#!/usr/bin/env python

import sys
from pyopenms import *

cm = ConsensusMap()
ConsensusXMLFile().load(sys.argv[1], cm)

df = cm.get_df()

df.to_csv("featureMatrix.tsv", sep="\t")
print(cm.get_df().head())