package org.openmrs.module.laboratoryapp.fragment.controller;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.UUID;

import org.openmrs.*;
import org.openmrs.api.context.Context;
import org.openmrs.module.hospitalcore.BillingConstants;
import org.openmrs.module.hospitalcore.PatientQueueService;
import org.openmrs.module.hospitalcore.matcher.RegistrationUtils;
import org.openmrs.module.hospitalcore.model.LabTest;
import org.openmrs.module.hospitalcore.model.OpdPatientQueue;
import org.openmrs.module.hospitalcore.model.OpdPatientQueueLog;
import org.openmrs.module.hospitalcore.util.GlobalPropertyUtil;
import org.openmrs.module.laboratory.LaboratoryService;
import org.openmrs.module.laboratoryapp.util.LaboratoryUtil;
import org.openmrs.module.laboratoryapp.util.ParameterModel;
import org.openmrs.module.laboratoryapp.util.ResultModel;
import org.openmrs.module.laboratoryapp.util.ResultModelWrapper;
import org.openmrs.ui.framework.SimpleObject;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.annotation.BindParams;
import org.springframework.web.bind.annotation.RequestParam;

public class ResultFragmentController {
	public List<SimpleObject> getResultTemplate(@RequestParam("testId") Integer testId, UiUtils ui) {
		LaboratoryService ls = Context.getService(LaboratoryService.class);
		LabTest test = ls.getLaboratoryTest(testId);		
		List<ParameterModel> parameters = new ArrayList<ParameterModel>();
		LaboratoryUtil.generateParameterModels(parameters, test.getConcept(), test.getEncounter());
		
		return SimpleObject.fromCollection(parameters, ui, "type", "title", "options.label", "options.value", "unit", "defaultValue", "validator");
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
		
		Order order = test.getOrder();
		order.setDiscontinued(true);
		order.setDiscontinuedDate(new Date());
		
		for (ResultModel resultModel : resultWrapper.getResults()) {
			Concept concept = LaboratoryUtil.searchConcept(resultModel.getConceptName());
			String result = resultModel.getSelectedOption() == null ? resultModel.getValue() : resultModel.getSelectedOption();
			Obs obs = insertValue(encounter, concept, result, test);
			if (obs.getId() == null)
				encounter.addObs(obs);
		}
		
		encounter = Context.getEncounterService().saveEncounter(encounter);
		
		test.setEncounter(encounter);
		test = ls.saveLaboratoryTest(test);
		ls.completeTest(test);

		this.sendPatientToQueue(encounter);

		return SimpleObject.create("status", "success", "message", "Saved!");
	}

	private void sendPatientToQueue(Encounter encounter)
	{
		//send patient back to the OPD Queue
		Patient patient = encounter.getPatient();
		PatientQueueService queueService = Context.getService(PatientQueueService.class);
		Concept referralConcept = Context.getConceptService().getConcept(2548);
		Encounter queueEncounter = queueService.getLastOPDEncounter(encounter.getPatient());
		OpdPatientQueueLog patientQueueLog =queueService.getOpdPatientQueueLogByEncounter(queueEncounter);
		Concept selectedOPDConcept = patientQueueLog.getOpdConcept();
		String selectedCategory = patientQueueLog.getCategory();
		String visitStatus = patientQueueLog.getVisitStatus();

		OpdPatientQueue queue = queueService.getOpdPatientQueue(
				patient.getPatientIdentifier().getIdentifier(), selectedOPDConcept.getConceptId());

		if (queue == null) {
			queue = new OpdPatientQueue();
			queue.setUser(Context.getAuthenticatedUser());
			queue.setPatient(patient);
			queue.setCreatedOn(new Date());
			queue.setBirthDate(patient.getBirthdate());
			queue.setPatientIdentifier(patient.getPatientIdentifier().getIdentifier());
			queue.setOpdConcept(selectedOPDConcept);
			queue.setOpdConceptName(selectedOPDConcept.getName().getName());
			if(null!=patient.getMiddleName())
			{
				queue.setPatientName( patient.getGivenName() + " " + patient.getFamilyName() + " " + patient.getMiddleName());
			}
			else
			{
				queue.setPatientName( patient.getGivenName() + " " + patient.getFamilyName());
			}

			queue.setReferralConcept(referralConcept);
			queue.setSex(patient.getGender());
			queue.setCategory(selectedCategory);
			queue.setVisitStatus(visitStatus);
			queueService.saveOpdPatientQueue(queue);

		}
	}
	
	private Obs insertValue(Encounter encounter, Concept concept, String value,
			LabTest test) {

		Obs obs = getObs(encounter, concept);
		obs.setConcept(concept);
		obs.setOrder(test.getOrder());
		if (concept.getDatatype().getName().equalsIgnoreCase("Text")) {
			obs.setValueText(value);
		}
		else if( concept.getDatatype().getName().equalsIgnoreCase("Numeric")){
			obs.setValueNumeric(Double.parseDouble(value));
		}else if (concept.getDatatype().getName().equalsIgnoreCase("Coded")) {
			Concept answerConcept = LaboratoryUtil.searchConcept(value);
			obs.setValueCoded(answerConcept);
		}
		return obs;
	}

	private Obs getObs(Encounter encounter, Concept concept) {
		for (Obs obs : encounter.getAllObs()) {
			if (obs.getConcept().equals(concept))
				return obs;
		}
		return new Obs();
	}
}
