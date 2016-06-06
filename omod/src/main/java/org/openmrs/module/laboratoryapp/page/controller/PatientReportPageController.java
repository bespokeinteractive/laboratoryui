package org.openmrs.module.laboratoryapp.page.controller;

import org.openmrs.*;
import org.openmrs.api.context.Context;
import org.openmrs.module.appui.UiSessionContext;
import org.openmrs.module.hospitalcore.model.LabTest;
import org.openmrs.module.hospitalcore.util.PatientDashboardConstants;
import org.openmrs.module.laboratory.LaboratoryService;
import org.openmrs.module.hospitalcore.HospitalCoreService;
import org.openmrs.module.laboratoryapp.util.LaboratoryTestUtil;
import org.openmrs.module.laboratoryapp.util.LaboratoryUtil;
import org.openmrs.module.laboratoryapp.util.TestResultModel;
import org.openmrs.module.referenceapplication.ReferenceApplicationWebConstants;
import org.openmrs.ui.framework.SimpleObject;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.fragment.FragmentConfiguration;
import org.openmrs.ui.framework.fragment.FragmentModel;
import org.openmrs.ui.framework.page.PageModel;
import org.openmrs.ui.framework.page.PageRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestParam;
import org.apache.commons.lang.StringUtils;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * Created by Francis on 2/10/2016.
 */
public class PatientReportPageController {
    private static Logger logger = LoggerFactory.getLogger(PatientReportPageController.class);
    public String get(
            UiSessionContext sessionContext,
            @RequestParam("patientId") Integer patientId,
            @RequestParam(value = "selectedDate", required = false) String dateStr,
            PageModel model,
            UiUtils ui,
            PageRequest pageRequest){
        pageRequest.getSession().setAttribute(ReferenceApplicationWebConstants.SESSION_ATTRIBUTE_REDIRECT_URL,ui.thisUrl());
        sessionContext.requireAuthentication();
        Boolean isPriviledged = Context.hasPrivilege("Access Laboratory");
        if(!isPriviledged){
            return "redirect: index.htm";
        }
        Patient patient = Context.getPatientService().getPatient(patientId);
        HospitalCoreService hcs = Context.getService(HospitalCoreService.class);

        model.addAttribute("patient", patient);
        model.addAttribute("patientIdentifier", patient.getPatientIdentifier());
        model.addAttribute("age", patient.getAge());
        model.addAttribute("gender" , patient.getGender());
        model.addAttribute("name", patient.getNames());
        model.addAttribute("category", patient.getAttribute(14));
        model.addAttribute("previousVisit",hcs.getLastVisitTime(patient));

        if (patient.getAttribute(43) == null){
            model.addAttribute("fileNumber", "");
        }
        else if (StringUtils.isNotBlank(patient.getAttribute(43).getValue())){
            model.addAttribute("fileNumber", "(File: "+patient.getAttribute(43)+")");
        }
        else {
            model.addAttribute("fileNumber", "");
        }

        LaboratoryService ls = Context.getService(LaboratoryService.class);

        Date selectedDate = new Date();

        SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
        try {
            selectedDate = dateFormat.parse(dateStr);
        } catch (ParseException e) {
            e.printStackTrace();
        }

        if (patient != null) {

            List<LabTest> tests;
            try {
                tests = ls.getLaboratoryTestsByDateAndPatient(selectedDate, patient);
                if ((tests != null) && (!tests.isEmpty())) {
                    Map<Concept, Set<Concept>> testTreeMap = LaboratoryTestUtil.getAllowableTests();
                    List<TestResultModel> trms = renderTests(tests, testTreeMap);
                    trms = formatTestResult(trms);

                    List<SimpleObject> results = SimpleObject.fromCollection(trms, ui,
                            "investigation", "set", "test", "value", "hiNormal",
                            "lowNormal", "lowAbsolute", "hiAbsolute", "hiCritical", "lowCritical",
                            "unit", "level", "concept", "encounterId", "testId");
                    SimpleObject currentResults = SimpleObject.create("data", results);
                    model.addAttribute("currentResults", currentResults);
                    model.addAttribute("test", ui.formatDatePretty(tests.get(0).getOrder().getStartDate()));

                }
            } catch (ParseException e) {
                logger.error(e.getMessage());
            }
        }
        return null;
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
