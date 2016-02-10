package org.openmrs.module.laboratoryapp.page.controller;

import org.openmrs.*;
import org.openmrs.api.context.Context;
import org.openmrs.module.hospitalcore.model.LabTest;
import org.openmrs.module.laboratory.LaboratoryService;
import org.openmrs.module.laboratoryapp.util.LaboratoryTestUtil;
import org.openmrs.module.laboratoryapp.util.LaboratoryUtil;
import org.openmrs.module.laboratoryapp.util.TestResultModel;
import org.openmrs.ui.framework.SimpleObject;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.fragment.FragmentConfiguration;
import org.openmrs.ui.framework.fragment.FragmentModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.text.ParseException;
import java.util.*;

/**
 * Created by Francis on 2/10/2016.
 */
public class PatientReportPageController {
    private static Logger logger = LoggerFactory.getLogger(PatientReportPageController.class);
    public void controller(
            FragmentConfiguration config,
            FragmentModel model,
            UiUtils ui) {
        config.require("patientId");
        Integer patientId = Integer.valueOf(config.get("patientId").toString());
        Patient patient = Context.getPatientService().getPatient(patientId);
        model.addAttribute("patient", patient);
        LaboratoryService ls = Context.getService(LaboratoryService.class);
        if (patient != null) {

            List<LabTest> tests;
            try {
                tests = ls.getLaboratoryTestsByDateAndPatient(new Date(), patient);
                if ((tests != null) && (!tests.isEmpty())) {
                    Map<Concept, Set<Concept>> testTreeMap = LaboratoryTestUtil.getAllowableTests();
                    List<TestResultModel> trms = renderTests(tests, testTreeMap);
                    trms = formatTestResult(trms);
                    //model.addAttribute("tests", trms);
                    List<SimpleObject> results = SimpleObject.fromCollection(trms, ui,
                            "investigation", "set", "test", "value", "hiNormal",
                            "lowNormal", "lowAbsolute", "hiAbsolute", "hiCritical", "lowCritical",
                            "unit", "level", "concept", "encounterId", "testId");
                    model.addAttribute("currentResults", results);
                }
            } catch (ParseException e) {
                logger.error(e.getMessage());
            }
        }
    }
    private List<TestResultModel> renderTests(List<LabTest> tests, Map<Concept, Set<Concept>> testTreeMap) {
        List<TestResultModel> trms = new ArrayList<TestResultModel>();
        for (LabTest test : tests) {
            if (test.getEncounter() != null) {
                Encounter encounter = test.getEncounter();
                for (Obs obs : encounter.getAllObs()) {
                    TestResultModel trm = new TestResultModel();
                    Concept investigation = getInvestigationByTest(test, testTreeMap);
                    trm.setInvestigation(LaboratoryUtil.getConceptName(investigation));
                    trm.setSet(test.getConcept().getName().getName());
                    Concept concept = Context.getConceptService().getConcept(obs.getConcept().getConceptId());
                    trm.setTest(concept.getName().getName());
                    trm.setConcept(test.getConcept());
                    setTestResultModelValue(obs, trm);
                    trms.add(trm);
                }
            }
        }
        return trms;
    }

    private Concept getInvestigationByTest(LabTest test, Map<Concept, Set<Concept>> investigationTests) {
        for (Concept investigation : investigationTests.keySet()) {
            if (investigationTests.get(investigation).contains(test.getConcept()))
                return investigation;
        }
        return null;
    }

    private void setTestResultModelValue(Obs obs, TestResultModel trm) {
        Concept concept = Context.getConceptService().getConcept(obs.getConcept().getConceptId());
        trm.setTest(concept.getName().getName());
        if (concept != null) {
            String datatype = concept.getDatatype().getName();
            if (datatype.equalsIgnoreCase("Text")) {
                trm.setValue(obs.getValueText());
            } else if (datatype.equalsIgnoreCase("Numeric")) {
                if (obs.getValueText() != null) {
                    trm.setValue(obs.getValueText().toString());
                } else {
                    trm.setValue(obs.getValueNumeric().toString());
                }
                ConceptNumeric cn = Context.getConceptService().getConceptNumeric(concept.getConceptId());
                trm.setUnit(cn.getUnits());
                if (cn.getLowNormal() != null)
                    trm.setLowNormal(cn.getLowNormal().toString());
                if (cn.getHiNormal() != null)
                    trm.setHiNormal(cn.getHiNormal().toString());
                if (cn.getHiAbsolute() != null) {
                    trm.setHiAbsolute(cn.getHiAbsolute().toString());
                }
                if (cn.getHiCritical() != null) {
                    trm.setHiCritical(cn.getHiCritical().toString());
                }
                if (cn.getLowAbsolute() != null) {
                    trm.setLowAbsolute(cn.getLowAbsolute().toString());
                }
                if (cn.getLowCritical() != null) {
                    trm.setLowCritical(cn.getLowCritical().toString());
                }

            } else if (datatype.equalsIgnoreCase("Coded")) {
                trm.setValue(obs.getValueCoded().getName().getName());
            }
        }
    }

    private List<TestResultModel> formatTestResult(List<TestResultModel> testResultModels) {
        Collections.sort(testResultModels);
        List<TestResultModel> trms = new ArrayList<TestResultModel>();
        String investigation = null;
        String set = null;
        for (TestResultModel trm : testResultModels) {
            if (!trm.getInvestigation().equalsIgnoreCase(investigation)) {
                investigation = trm.getInvestigation();
                TestResultModel t = new TestResultModel();
                t.setInvestigation(investigation);
                t.setLevel(TestResultModel.LEVEL_INVESTIGATION);
                set = null;
                trms.add(t);
            }

            if (!trm.getSet().equalsIgnoreCase(set)) {
                set = trm.getSet();
                if (!trm.getConcept().getConceptClass().getName().equalsIgnoreCase("LabSet")) {
                    trm.setLevel(TestResultModel.LEVEL_SET);
                    trms.add(trm);
                } else {
                    TestResultModel t = new TestResultModel();
                    t.setSet(set);
                    t.setLevel(TestResultModel.LEVEL_SET);
                    t.setEncounterId(trm.getEncounterId());
                    t.setTestId(trm.getTestId());
                    trms.add(t);
                }
            }

            if (trm.getConcept().getConceptClass().getName().equalsIgnoreCase("LabSet")) {
                trms.add(trm);
            }
        }
        return trms;
    }
}
