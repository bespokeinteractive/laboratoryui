package org.openmrs.module.laboratoryapp.page.controller;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Set;

import org.openmrs.Concept;
import org.openmrs.api.context.Context;
import org.openmrs.module.hospitalcore.model.Lab;
import org.openmrs.module.laboratory.LaboratoryService;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.page.PageModel;
import org.openmrs.module.appui.UiSessionContext;
import org.openmrs.module.referenceapplication.ReferenceApplicationWebConstants;
import org.openmrs.ui.framework.page.PageRequest;


public class QueuePageController {

	public String get(UiSessionContext sessionContext,
					PageModel model,
					PageRequest pageRequest,
					UiUtils ui) {
		pageRequest.getSession().setAttribute(ReferenceApplicationWebConstants.SESSION_ATTRIBUTE_REDIRECT_URL,ui.thisUrl());
		sessionContext.requireAuthentication();
		Boolean isPriviledged = Context.hasPrivilege("Access Laboratory");
		if(!isPriviledged){
			return "redirect: index.htm";
		}
		SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
		String dateStr = sdf.format(new Date());
		model.addAttribute("currentDate", dateStr);
		LaboratoryService ls = (LaboratoryService) Context.getService(LaboratoryService.class);
		Lab department = ls.getCurrentDepartment();
		if(department!=null){
			Set<Concept> investigations = department.getInvestigationsToDisplay();
			model.addAttribute("investigations", investigations);
		}
		return null;
	}

}
