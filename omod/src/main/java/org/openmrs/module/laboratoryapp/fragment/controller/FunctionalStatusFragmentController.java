package org.openmrs.module.laboratoryapp.fragment.controller;

import org.openmrs.Concept;
import org.openmrs.api.context.Context;
import org.openmrs.module.hospitalcore.BillingService;
import org.openmrs.module.hospitalcore.model.BillableService;
import org.openmrs.module.laboratoryapp.util.LaboratoryTestUtil;
import org.openmrs.ui.framework.SimpleObject;
import org.openmrs.ui.framework.UiUtils;

import java.util.*;

/**
 * Created by ngarivictor on 2/24/2016.
 */
public class FunctionalStatusFragmentController {
    public void controller(){

    }
   public List<SimpleObject> getBillableServices(UiUtils uiUtils) {
        Map<Concept, Set<Concept>> testTreeMap = LaboratoryTestUtil.getAllowableTests();
        Set<Concept> concepts = new HashSet<Concept>();
            for (Concept key : testTreeMap.keySet()) {
            concepts.addAll(testTreeMap.get(key));
        }
        BillingService billingService = Context.getService(BillingService.class);
        List<BillableService> billableServices = new ArrayList<BillableService>();
        for (Concept concept : concepts) {
            BillableService billableService = billingService
                    .getServiceByConceptId(concept.getConceptId());
            if (billableService != null) {
                if (billableService.getPrice() != null)
                    billableServices.add(billableService);
            }
        }
        return SimpleObject.fromCollection(billableServices,uiUtils,"name","serviceId","disable");
    }
}