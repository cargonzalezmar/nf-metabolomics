nextflow.enable.dsl=2

process SIRIUS {
  
	tag "$mzML $featureXML"

	label "publish_sirius"

  input:
		path mzML
		path featureXML
		path ch_feature_matrix
	
	output:
		path "${mzML.toString()[0..-14]}_sirius.ms"
		path "${mzML.toString()[0..-14]}_formulas.pkl"
		path "${mzML.toString()[0..-14]}_structures.pkl"

	script:
	"""
	FileFilter -in $featureXML -out ${featureXML.toString()[0..-12]}_filtered.featureXML -mz 180:185
	SiriusAdapter -sirius_executable sirius -in $mzML -in_featureinfo ${featureXML.toString()[0..-12]}_filtered.featureXML -out_ms ${mzML.toString()[0..-14]}_sirius.ms -out_sirius ${mzML.toString()[0..-14]}_formulas.mzTab -out_fingerid ${mzML.toString()[0..-14]}_structures.mzTab -preprocessing:filter_by_num_masstraces 2 -preprocessing:feature_only -sirius:profile orbitrap -sirius:db none -sirius:ions_considered "[M+H]+, [M-H2O+H]+, [M+Na]+, [M+NH4]+" -sirius:elements_enforced CHN[15]OS[4]Cl[2]P[2] -debug 5 -fingerid:candidates 5
	mzTab_to_dataframe.py ${mzML.toString()[0..-14]}_formulas.mzTab ${mzML.toString()[0..-14]}_formulas.pkl ${mzML.toString()[0..-14]}_structures.mzTab ${mzML.toString()[0..-14]}_structures.pkl
	"""
}

process ANNOTATEFORMULAS {

	tag "$formulas"

	debug true

	input:
		path feature_matrix
		path formulas

	output:
		path "${feature_matrix.toString()[0..-5]}_formulas.pkl"

	script:
	"""
	annotate_sirius_formulas.py $feature_matrix ${feature_matrix.toString()[0..-5]}_formulas.pkl $formulas
	"""
}

process ANNOTATESTRUCTURES {

	tag "$structures"

	input:
		path feature_matrix
		path structures

	output:
		path "${feature_matrix.toString()[0..-5]}_structures.pkl"

	script:
	"""
	annotate_sirius_structures.py $feature_matrix ${feature_matrix.toString()[0..-5]}_structures.pkl $structures
	"""
}

workflow sirius {
	take:
		ch_mzMLs
		ch_featureXMLs
		ch_feature_matrix
	
	main:
		(ch_sirius, ch_formulas, ch_structures) = SIRIUS(ch_mzMLs, ch_featureXMLs, ch_feature_matrix)
		ch_feature_matrix_formulas = ANNOTATEFORMULAS(ch_feature_matrix, ch_formulas.collect())
		ch_feature_matrix_formulas_structures = ANNOTATESTRUCTURES(ch_feature_matrix_formulas, ch_structures.collect())

	emit:
		ch_formulas
		ch_structures
		ch_feature_matrix_formulas_structures
}