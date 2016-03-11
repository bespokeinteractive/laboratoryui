package org.openmrs.module.laboratoryapp.page.controller;

import org.openmrs.Concept;
import org.openmrs.api.context.Context;
import org.openmrs.module.appui.UiSessionContext;
import org.openmrs.module.referenceapplication.ReferenceApplicationWebConstants;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.page.PageModel;
import org.openmrs.ui.framework.page.PageRequest;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Set;

/**
 * Created by Dennys Henry on 2/18/2016.
 */
public class MainPageController {
    public void get( UiSessionContext sessionContext,
                    PageModel model,
                    PageRequest pageRequest,
                    UiUtils ui) {
        pageRequest.getSession().setAttribute(ReferenceApplicationWebConstants.SESSION_ATTRIBUTE_REDIRECT_URL,ui.thisUrl());
        sessionContext.requireAuthentication();
        model.addAttribute("date", new Date());
    }
}
