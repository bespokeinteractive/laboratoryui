package org.openmrs.module.laboratoryui.fragment.controller;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.openmrs.Concept;
import org.openmrs.api.context.Context;
import org.openmrs.module.hospitalcore.model.Lab;
import org.openmrs.module.hospitalcore.model.LabTest;
import org.openmrs.module.laboratory.LaboratoryService;
import org.openmrs.module.laboratoryui.util.LaboratoryTestUtil;
import org.openmrs.module.laboratoryui.util.LaboratoryUtil;
import org.openmrs.module.laboratoryui.util.TestModel;
import org.openmrs.ui.framework.SimpleObject;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.fragment.FragmentModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestParam;

public class LaboratoryWorkListFragmentController {
	private static Logger logger = LoggerFactory.getLogger(QueueFragmentController.class);

	public void controller(FragmentModel model) {
		SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
		String dateStr = sdf.format(new Date());
		model.addAttribute("currentDate", dateStr);
		
		LaboratoryService ls = (LaboratoryService) Context.getService(LaboratoryService.class);
		Lab department = ls.getCurrentDepartment();
		if(department!=null){
			Set<Concept> investigations = department.getInvestigationsToDisplay();
			model.addAttribute("investigations", investigations);
		}
	}

	public List<SimpleObject> searchWorkList(
			@RequestParam(value = "date", required = false) String dateStr,
			@RequestParam(value = "phrase", required = false) String phrase,
			@RequestParam(value = "investigation", required = false) Integer investigationId,
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
			List<LabTest> laboratoryTests = ls.getAcceptedLaboratoryTests(date, phrase, allowableTests);			
			List<TestModel> tests = LaboratoryUtil.generateModelsFromTests(laboratoryTests, testTreeMap);
			simpleObjects = SimpleObject.fromCollection(tests, ui, "startDate", "patientIdentifier", "patientName", "gender", "age", "test.name", "testId", "orderId", "sampleId", "status");
		} catch (ParseException e) {
			e.printStackTrace();
			logger.error("Error when parsing order date!", e.getMessage());
		}
		return simpleObjects;
	}
}
