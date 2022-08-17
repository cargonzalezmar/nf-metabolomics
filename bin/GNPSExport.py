#!/usr/bin/env python

import sys
from pyopenms import *

consensusXML_file = sys.argv[1]
mzML_files = sys.argv[2:]


consensus_map = ConsensusMap()
ConsensusXMLFile().load(consensusXML_file, consensus_map)

# for FBMN
GNPSMGFFile().store(String(consensusXML_file), [file.encode() for file in mzML_files], String(sys.argv[-4]))
GNPSQuantificationFile().store(consensus_map, sys.argv[-3])
GNPSMetaValueFile().store(consensus_map, String(sys.argv[-1]))

# for IIMN
IonIdentityMolecularNetworking.annotateConsensusMap(consensus_map)
IonIdentityMolecularNetworking.writeSupplementaryPairTable(consensus_map, sys.argv[-2])