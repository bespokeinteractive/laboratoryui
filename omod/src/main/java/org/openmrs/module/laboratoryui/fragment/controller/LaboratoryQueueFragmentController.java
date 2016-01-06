package org.openmrs.module.laboratoryui.fragment.controller;

import java.text.ParseException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.openmrs.Concept;
import org.openmrs.Order;
import org.openmrs.api.context.Context;
import org.openmrs.module.laboratory.LaboratoryService;
import org.openmrs.module.laboratory.util.LaboratoryConstants;
import org.openmrs.module.laboratoryui.util.LaboratoryTestUtil;
import org.openmrs.module.laboratoryui.util.LaboratoryUtil;
import org.openmrs.ui.framework.SimpleObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestParam;

public class LaboratoryQueueFragmentController {
	
	private static Logger logger = LoggerFactory.getLogger(LaboratoryQueueFragmentController.class);

	public SimpleObject acceptLabTest(
			@RequestParam("orderId") Integer orderId) {
		Order order = Context.getOrderService().getOrder(orderId);
		if (order != null) {
			try {
				LaboratoryService ls = (LaboratoryService) Context.getService(LaboratoryService.class);
				String sampleId = getSampleId(orderId);
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
