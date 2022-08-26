nextflow.enable.dsl=2

process SIRIUS {
  
	tag "$mzML $featureXML"

	label "publish_sirius"

  input:
		path mzML
		path featureXML
		path consensus
	
	output:
		path "${featureXML.toString()[0..-12]}_sirius.ms"
		path "${featureXML.toString()[0..-12]}_formulas.mzTab"
		path "${featureXML.toString()[0..-12]}_structures.mzTab"

	script:
	"""
	FileFilter -in $featureXML -out ${featureXML.toString()[0..-12]}_filtered.featureXML -mz 180:185
	SiriusAdapter -sirius_executable sirius -in $mzML -in_featureinfo ${featureXML.toString()[0..-12]}_filtered.featureXML -out_ms ${featureXML.toString()[0..-12]}_sirius.ms -out_sirius ${featureXML.toString()[0..-12]}_formulas.mzTab -out_fingerid ${featureXML.toString()[0..-12]}_structures.mzTab -preprocessing:filter_by_num_masstraces 2 -preprocessing:feature_only -sirius:profile orbitrap -sirius:db none -sirius:ions_considered "[M+H]+, [M-H2O+H]+, [M+Na]+, [M+NH4]+" -sirius:elements_enforced CHN[15]OS[4]Cl[2]P[2] -debug 5 -fingerid:candidates 5
	"""
}

workflow sirius {
	take:
		ch_mzMLs
		ch_featureXMLs
		ch_consensus
	
	main:
		(ch_formulas, ch_structures) = SIRIUS(ch_mzMLs, ch_featureXMLs, ch_consensus)
	
	emit:
		ch_formulas
		ch_structures
}