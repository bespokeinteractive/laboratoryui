package org.openmrs.module.laboratoryapp.fragment.controller;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.openmrs.Concept;
import org.openmrs.api.context.Context;
import org.openmrs.module.hospitalcore.model.LabTest;
import org.openmrs.module.laboratory.LaboratoryService;
import org.openmrs.module.laboratoryapp.util.LaboratoryTestUtil;
import org.openmrs.module.laboratoryapp.util.LaboratoryUtil;
import org.openmrs.module.laboratoryapp.util.TestModel;
import org.openmrs.ui.framework.SimpleObject;
import org.openmrs.ui.framework.UiUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestParam;

public class WorksheetFragmentController {
	private static Logger logger = LoggerFactory.getLogger(WorksheetFragmentController.class);

	public List<SimpleObject> getWorksheet(
			@RequestParam(value = "date", required = false) String dateStr,
			@RequestParam(value = "phrase", required = false) String phrase,
			@RequestParam(value = "investigation", required = false) Integer investigationId,
			@RequestParam(value = "showResults", required = false) String showResults,
			UiUtils ui) {
		LaboratoryService ls = Context.getService(LaboratoryService.class);
		Concept investigation = Context.getConceptService().getConcept(investigationId);
		SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
		Date date = null;
		List<SimpleObject> simpleObjects = new ArrayList<SimpleObject>();
		try {
			date = sdf.parse(dateStr);
			Map<Concept, Set<Concept>> testTreeMap = LaboratoryTestUtil.getAllowableTests();
			Set<Concept> allowableTests = new HashSet<Concept>();
			if (investigation != null) {
				allowableTests = testTreeMap.get(investigation);
			} else {
				for (Concept c : testTreeMap.keySet()) {
					allowableTests.addAll(testTreeMap.get(c));
				}
			}
			List<LabTest> laboratoryTests = ls.getAllLaboratoryTestsByDate(
					date, phrase, allowableTests);
			List<TestModel> tests = LaboratoryUtil.generateModelsForWorksheet(laboratoryTests, testTreeMap,showResults);
			Collections.sort(tests);
			simpleObjects = SimpleObject.fromCollection(tests, ui, "startDate", "patientIdentifier", "patientName", "gender", "age", "test.name", "testName.name", "investigation", "testId", "orderId", "sampleId", "status", "value");
		} catch (ParseException e) {
			logger.error("Error when parsing order date!", e.getMessage());
			simpleObjects.add(SimpleObject.create("status", "error", "message", "Invalid date!"));
		}
		
		return simpleObjects;
	}

}
