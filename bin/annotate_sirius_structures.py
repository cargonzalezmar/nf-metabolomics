#!/usr/bin/env python

import sys
import pandas as pd

matrix = pd.read_pickle(sys.argv[1])

# generating a dict with feature Ids as keys and formulas as values
id_to_structure = {}
for structure_file in sys.argv[3:]:
    df = pd.read_pickle(structure_file)
    for description, formula, smile, inchi, featureId in zip(df["description"], df["chemical_formula"], df["smiles"], df["inchi_key"], df["featureId"]):
        compound = {"name": description, "formula": formula, "SMILE": smile, "InChI": inchi}
        if featureId in id_to_structure.keys():
            id_to_structure[featureId].append(compound)
        else:
            id_to_structure[featureId] = [compound]

# create a new list with all formulas matching to a consensus feature
all_structures = []
for id_list in matrix["feature_ids"]:
    structures = []
    for id in id_list:
        if id in id_to_structure.keys():
            structures += id_to_structure[id]
    all_structures.append(structures)

# insert formulas as new column in the matrix df
matrix.insert(loc=len(matrix.columns), column="pred_compounds", value=all_structures)

matrix.to_pickle(sys.argv[2])
