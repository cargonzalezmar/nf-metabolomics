#!/usr/bin/env python

import sys
import pandas as pd

matrix = pd.read_pickle(sys.argv[1])

# generating a dict with feature Ids as keys and formulas as values
id_to_formulas = {}
for formula_file in sys.argv[3:]:
    df = pd.read_pickle(formula_file)
    for formula, featureId in zip(df["chemical_formula"], df["featureId"]):
        if featureId in id_to_formulas.keys():
            id_to_formulas[featureId].add(formula)
        else:
            id_to_formulas[featureId] = {formula}

# create a new list with all formulas matching to a consensus feature
all_formulas = []
for id_list in matrix["feature_ids"]:
    formulas = set()
    for id in id_list:
        if id in id_to_formulas.keys():
            formulas.update(id_to_formulas[id])
    all_formulas.append(list(formulas))

# insert formulas as new column in the matrix df
matrix.insert(loc=len(matrix.columns), column="pred_formulas", value=all_formulas)

matrix.to_pickle(sys.argv[2])
