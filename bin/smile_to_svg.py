#!/usr/bin/env python

import sys
import pandas as pd

from rdkit import Chem
# from rdkit.Chem.Draw import IPythonConsole
from rdkit.Chem import rdDepictor
from rdkit.Chem.Draw import rdMolDraw2D
import pickle
# from IPython.display import SVG

def obtain_svg(smiles, molSize = (500,500), kekulize = True):
    mol = Chem.MolFromSmiles(smiles)
    mc = Chem.Mol(mol.ToBinary())
    if kekulize:
        try:
            Chem.Kekulize(mc)
        except:
            mc = Chem.Mol(mol.ToBinary())
    if not mc.GetNumConformers():
        rdDepictor.Compute2DCoords(mc)
    drawer = rdMolDraw2D.MolDraw2DSVG(molSize[0],molSize[1])
    drawer.DrawMolecule(mc)
    drawer.FinishDrawing()
    svg = drawer.GetDrawingText()
    return svg.replace('svg:','')

matrix = pd.read_pickle(sys.argv[1])

pred_compounds = list(matrix[matrix["pred_compounds"].str.len() != 0]["pred_compounds"])

smiles = set()

for i in range(len(pred_compounds)):
    for j in pred_compounds[i]:
        smiles.add(j['SMILE'])

smile_to_svg_dict = {}
for smile in smiles:
    smile_to_svg_dict[smile] = obtain_svg(smile)

pickle.dump(smile_to_svg_dict, open(sys.argv[2], 'wb'))


