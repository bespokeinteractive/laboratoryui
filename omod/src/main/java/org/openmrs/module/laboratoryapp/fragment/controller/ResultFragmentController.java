package org.openmrs.module.laboratoryapp.fragment.controller;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.UUID;

import org.apache.commons.lang.StringUtils;
import org.openmrs.*;
import org.openmrs.api.context.Context;
import org.openmrs.module.hospitalcore.BillingConstants;
import org.openmrs.module.hospitalcore.PatientQueueService;
import org.openmrs.module.hospitalcore.model.LabTest;
import org.openmrs.module.hospitalcore.model.OpdPatientQueue;
import org.openmrs.module.hospitalcore.model.OpdPatientQueueLog;
import org.openmrs.module.hospitalcore.util.GlobalPropertyUtil;
import org.openmrs.module.laboratory.LaboratoryService;
import org.openmrs.module.laboratoryapp.util.LaboratoryUtil;
import org.openmrs.module.laboratoryapp.util.ParameterModel;
import org.openmrs.module.laboratoryapp.util.ParameterOption;
import org.openmrs.module.laboratoryapp.util.ResultModel;
import org.openmrs.module.laboratoryapp.util.ResultModelWrapper;
import org.openmrs.ui.framework.SimpleObject;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.annotation.BindParams;
import org.springframework.web.bind.annotation.RequestParam;

public class ResultFragmentController {
		private static final Integer LAB_CONCEPT_ID = 2548;

	public List<SimpleObject> getResultTemplate(@RequestParam("testId") Integer testId, UiUtils ui) {
		LaboratoryService ls = Context.getService(LaboratoryService.class);
		LabTest test = ls.getLaboratoryTest(testId);		
		List<ParameterModel> parameters = new ArrayList<ParameterModel>();
		LaboratoryUtil.generateParameterModels(parameters, test.getConcept(), null, test.getEncounter());
		Collections.sort(parameters);
		List<SimpleObject> resultsTemplate = new ArrayList<SimpleObject>();
		for (ParameterModel parameter : parameters) {
			SimpleObject resultTemplate = new SimpleObject();
			resultTemplate.put("type", parameter.getType());
			resultTemplate.put("id", parameter.getId());
			resultTemplate.put("container", parameter.getContainer());
			resultTemplate.put("containerId", parameter.getContainerId());
			resultTemplate.put("title", parameter.getTitle());
			resultTemplate.put("unit", parameter.getUnit());
			resultTemplate.put("validator", parameter.getValidator());
			resultTemplate.put("defaultValue", parameter.getDefaultValue());
			List<SimpleObject> options = new ArrayList<SimpleObject>();
			for (ParameterOption option : parameter.getOptions()) {
				SimpleObject parameterOption = new SimpleObject();
				parameterOption.put("label", option.getLabel());
				parameterOption.put("value", option.getValue());
				options.add(parameterOption);
			}
			resultTemplate.put("options", options);
			resultsTemplate.add(resultTemplate);
		}
		
		return resultsTemplate;
	}
	
	public SimpleObject saveResult(
			@BindParams("wrap") ResultModelWrapper resultWrapper){
		LaboratoryService ls = (LaboratoryService) Context.getService(LaboratoryService.class);
		LabTest test = ls.getLaboratoryTest(resultWrapper.getTestId());
		//TODO: define constant in this module and use that
		String encounterTypeStr = GlobalPropertyUtil.getString(BillingConstants.GLOBAL_PROPRETY_LAB_ENCOUNTER_TYPE, "LABENCOUNTER");
		EncounterType encounterType = Context.getEncounterService().getEncounterType(encounterTypeStr);
		Encounter encounter = new Encounter();
		encounter.setCreator(Context.getAuthenticatedUser());
		encounter.setDateCreated(new Date());

		//TODO: Use location from session
		Location loc = Context.getLocationService().getLocation(1);
		encounter.setLocation(loc);
		encounter.setPatient(test.getPatient());
		encounter.setEncounterType(encounterType);
		encounter.setVoided(false);
		encounter.setCreator(Context.getAuthenticatedUser());
		encounter.setUuid(UUID.randomUUID().toString());
		encounter.setEncounterDatetime(new Date());
		
		//TODO get date from user
		Order order = test.getOrder();
		order.setDiscontinued(true);
		order.setDiscontinuedDate(new Date());
		
		for (ResultModel resultModel : resultWrapper.getResults()) {
			String result = resultModel.getSelectedOption() == null ? resultModel.getValue() : resultModel.getSelectedOption();
			if (StringUtils.contains(resultModel.getConceptName(), ".")) {
				String[] parentChildConceptIds = resultModel.getConceptName().split(".");
				Concept testGroupConcept = Context.getConceptService().getConcept(parentChildConceptIds[0]);
				Concept testConcept = Context.getConceptService().getConcept(parentChildConceptIds[1]);
				addLaboratoryTestObservation(encounter, testConcept, testGroupConcept, result, test);
			} else {
				Concept concept = Context.getConceptService().getConcept(resultModel.getConceptName());
				addLaboratoryTestObservation(encounter, concept, null, result, test);
			}
		}
		
		encounter = Context.getEncounterService().saveEncounter(encounter);
		
		test.setEncounter(encounter);
		test = ls.saveLaboratoryTest(test);
		ls.completeTest(test);

		this.sendPatientToOpdQueue(encounter);

		return SimpleObject.create("status", "success", "message", "Saved!");
	}

	private void sendPatientToOpdQueue(Encounter encounter) {
		Patient patient = encounter.getPatient();
		PatientQueueService queueService = Context.getService(PatientQueueService.class);
		Concept referralConcept = Context.getConceptService().getConcept(LAB_CONCEPT_ID);
		Encounter queueEncounter = queueService.getLastOPDEncounter(encounter.getPatient());
		OpdPatientQueueLog patientQueueLog =queueService.getOpdPatientQueueLogByEncounter(queueEncounter);
		Concept selectedOPDConcept = patientQueueLog.getOpdConcept();
		String selectedCategory = patientQueueLog.getCategory();
		String visitStatus = patientQueueLog.getVisitStatus();

		OpdPatientQueue patientInQueue = queueService.getOpdPatientQueue(
				patient.getPatientIdentifier().getIdentifier(), selectedOPDConcept.getConceptId());

		if (patientInQueue == null) {
			patientInQueue = new OpdPatientQueue();
			patientInQueue.setUser(Context.getAuthenticatedUser());
			patientInQueue.setPatient(patient);
			patientInQueue.setCreatedOn(new Date());
			patientInQueue.setBirthDate(patient.getBirthdate());
			patientInQueue.setPatientIdentifier(patient.getPatientIdentifier().getIdentifier());
			patientInQueue.setOpdConcept(selectedOPDConcept);
			patientInQueue.setTriageDataId(patientQueueLog.getTriageDataId());
			patientInQueue.setOpdConceptName(selectedOPDConcept.getName().getName());
			if(null!=patient.getMiddleName()) {
				patientInQueue.setPatientName(patient.getGivenName() + " " + patient.getFamilyName() + " " + patient.getMiddleName());
			} else {
				patientInQueue.setPatientName(patient.getGivenName() + " " + patient.getFamilyName());
			}

			patientInQueue.setReferralConcept(referralConcept);
			patientInQueue.setSex(patient.getGender());
			patientInQueue.setCategory(selectedCategory);
			patientInQueue.setVisitStatus(visitStatus);
			queueService.saveOpdPatientQueue(patientInQueue);
		} else {
			patientInQueue.setReferralConcept(referralConcept);
			queueService.saveOpdPatientQueue(patientInQueue);
		}
	}
	
	private void addLaboratoryTestObservation(Encounter encounter, Concept testConcept, Concept testGroupConcept,
			String result, LabTest test) {
		Obs obs = getObs(encounter, testConcept);
		obs.setConcept(testConcept);
		obs.setOrder(test.getOrder());
		if (testConcept.getDatatype().getName().equalsIgnoreCase("Text")) {
			obs.setValueText(result);
		} else if ( testConcept.getDatatype().getName().equalsIgnoreCase("Numeric")){
			obs.setValueNumeric(Double.parseDouble(result));
		} else if (testConcept.getDatatype().getName().equalsIgnoreCase("Coded")) {
			Concept answerConcept = LaboratoryUtil.searchConcept(result);
			obs.setValueCoded(answerConcept);
		}
		if (testGroupConcept != null) {
			Obs testGroupObs = getObs(encounter, testConcept);
			if (testGroupObs.getConcept() == null) {
				//TODO find out what valueGroupId is and set to testGroupObs if necessary
				testGroupObs.setConcept(testGroupConcept);
				encounter.addObs(testGroupObs);
			}
			testGroupObs.addGroupMember(obs);
		}
		encounter.addObs(obs);
	}

	private Obs getObs(Encounter encounter, Concept concept) {
		for (Obs obs : encounter.getAllObs()) {
			if (obs.getConcept().equals(concept))
				return obs;
		}
		return new Obs();
	}
}
