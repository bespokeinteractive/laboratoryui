package org.openmrs.module.laboratoryapp.page.controller;

import org.openmrs.Concept;
import org.openmrs.api.context.Context;
import org.openmrs.ui.framework.page.PageModel;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Set;

/**
 * Created by Dennys Henry on 2/18/2016.
 */
public class MainPageController {
    public void get(PageModel model) {
        model.addAttribute("date", new Date());
    }
}
