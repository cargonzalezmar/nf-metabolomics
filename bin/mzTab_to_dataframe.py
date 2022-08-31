#!/usr/bin/env python

import sys
import pandas as pd
from pyteomics import mztab

def sirius_mztab_to_df(mztab_file):
    data = mztab.MzTab(mztab_file, encoding='UTF8', table_format='df')
    df = data.small_molecule_table
    df.drop(columns= ["identifier", "smiles", "inchi_key", "description", "calc_mass_to_charge", "charge", "taxid", "species","database", "database_version", "spectra_ref", "search_engine", "modifications"], inplace=True)
    df = df[df["opt_global_explainedIntensity"] >= 0.8]
    df = df.rename(columns= {"best_search_engine_score[1]":	"SiriusScore", "best_search_engine_score[2]":	"TreeScore", "best_search_engine_score[3]":	"IsotopeScore",
                            "opt_global_featureId": "featureId", "exp_mass_to_charge": "mz", "retention_time": "RT"})
    df.drop(columns= df.filter(regex=fr"opt").columns, inplace=True)
    df["featureId"]= df["featureId"].str.replace("id_", "")
    df = df[df["IsotopeScore"] >= 0.0]
    return df

def csi_mztab_to_df(mztab_file):
    data =  mztab.MzTab(mztab_file, encoding='UTF8', table_format='df')
    df = data.small_molecule_table
    df.drop(columns= ["calc_mass_to_charge", "charge", "taxid", "species","database", "database_version", "spectra_ref", "search_engine", "modifications"], inplace=True)
    df = df.rename(columns = {"opt_global_featureId": "featureId", "exp_mass_to_charge": "mz", "retention_time": "RT"})
    df["featureId"]= df["featureId"].str.replace("id_", "")
    return df

# formulas
sirius_mztab_to_df(sys.argv[1]).to_pickle(sys.argv[2])
# structures
csi_mztab_to_df(sys.argv[3]).to_pickle(sys.argv[4])
