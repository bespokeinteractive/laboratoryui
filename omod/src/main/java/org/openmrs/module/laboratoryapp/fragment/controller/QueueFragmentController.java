package org.openmrs.module.laboratoryapp.fragment.controller;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.openmrs.Concept;
import org.openmrs.Order;
import org.openmrs.api.context.Context;
import org.openmrs.module.hospitalcore.model.Lab;
import org.openmrs.module.laboratory.LaboratoryService;
import org.openmrs.module.laboratory.util.LaboratoryConstants;
import org.openmrs.module.laboratoryapp.util.LaboratoryTestUtil;
import org.openmrs.module.laboratoryapp.util.LaboratoryUtil;
import org.openmrs.module.laboratoryapp.util.TestModel;
import org.openmrs.ui.framework.SimpleObject;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.fragment.FragmentModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestParam;
import org.openmrs.module.appui.UiSessionContext;

public class QueueFragmentController {

	private static Logger logger = LoggerFactory.getLogger(QueueFragmentController.class);
	
	public void controller(UiSessionContext sessionContext, FragmentModel model) {
		sessionContext.requireAuthentication();
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

	public List<SimpleObject> searchQueue(
			@RequestParam(value = "date", required = false) String dateStr,
			@RequestParam(value = "phrase", required = false) String phrase,
			@RequestParam(value = "investigation", required = false) Integer investigationId,
			@RequestParam(value = "currentPage", required = false) Integer currentPage,
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
			if (currentPage == null)
				currentPage = 1;
			List<Order> orders = ls.getOrders(date, phrase, allowableTests,
					currentPage);
			List<TestModel> tests = LaboratoryUtil.generateModelsFromOrders(
					orders, testTreeMap);
			simpleObjects = SimpleObject.fromCollection(tests, ui, "startDate", "patientIdentifier", "patientName", "gender", "age", "test.name", "orderId", "sampleId", "status");
		} catch (ParseException e) {
			e.printStackTrace();
			logger.error("Error when parsing order date!", e.getMessage());
		}
		return simpleObjects;
	}

	public SimpleObject acceptLabTest(
			@RequestParam("orderId") Integer orderId,
			@RequestParam("confirmedSampleId") String sampleId) {
		Order order = Context.getOrderService().getOrder(orderId);
		if (order != null) {
			try {
				LaboratoryService ls = (LaboratoryService) Context.getService(LaboratoryService.class);
				Integer acceptedTestId = ls.acceptTest(order, sampleId);
				if (acceptedTestId > 0) {
					return SimpleObject.create("acceptedTestId", acceptedTestId, "sampleId", sampleId, "status", "success");
				} else {
					List<Object> simpleObjectElements = new ArrayList<Object>();
					simpleObjectElements.add("status");
					simpleObjectElements.add("fail");
					simpleObjectElements.add("error");
					if (acceptedTestId.equals(LaboratoryConstants.ACCEPT_TEST_RETURN_ERROR_EXISTING_SAMPLEID)) {
						simpleObjectElements.add("Existing sample id found");
					} else if (acceptedTestId == LaboratoryConstants.ACCEPT_TEST_RETURN_ERROR_EXISTING_TEST) {
						simpleObjectElements.add("Existing accepted test found");
					}
					return SimpleObject.create(simpleObjectElements);
				}
			} catch (Exception e) {
				return SimpleObject.create("status", "fail", "error", "Error occured while saving test.");
			}
		}
		return SimpleObject.create("status", "fail", "error", "Order {" + orderId + "} not found.");
	}

	public SimpleObject fetchSampleID(@RequestParam("orderId") Integer orderId)
	{
		String defaultSampleId = this.getSampleId(orderId);

		return SimpleObject.create("defaultSampleId",defaultSampleId);
	}
	
	private String getSampleId(Integer orderId){
		Map<Concept, Set<Concept>> testTreeMap = LaboratoryTestUtil.getAllowableTests();
		Order order = Context.getOrderService().getOrder(orderId);
		LaboratoryService ls = Context.getService(LaboratoryService.class);
		try {
			String sampleId = ls.getDefaultSampleId(LaboratoryUtil.getInvestigationName(order.getConcept(), testTreeMap));
			return sampleId;
		} catch (ParseException e) {
			logger.error(e.getMessage());
		}
		return "";
	}

	public SimpleObject rescheduleTest(
			@RequestParam("orderId") Integer orderId,
			@RequestParam("rescheduledDate") String rescheduledDateStr) {
		Order order = Context.getOrderService().getOrder(orderId);
		if (order != null) {
			LaboratoryService ls = Context.getService(LaboratoryService.class);
			Date rescheduledDate;
			try {
				rescheduledDate = LaboratoryUtil.parseDate(rescheduledDateStr);
				String status = ls.rescheduleTest(order, rescheduledDate);
				return SimpleObject.create("status", "success", "message", status);
			} catch (ParseException e) {
				logger.error("Unable to parse date [" + rescheduledDateStr + "]", e.getMessage());
				return SimpleObject.create("status", "fail", "error", "invalid date: " + rescheduledDateStr);
			}
		}
		logger.warn("Order (" + orderId +") not found");
		return SimpleObject.create("status", "fail", "error", "Order (" + orderId +") not found");
	}

}
