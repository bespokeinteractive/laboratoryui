package org.openmrs.module.laboratoryapp.fragment.controller;

import org.apache.commons.lang3.StringUtils;
import org.openmrs.Concept;
import org.openmrs.api.context.Context;
import org.openmrs.module.hospitalcore.BillingService;
import org.openmrs.module.hospitalcore.model.BillableService;
import org.openmrs.module.laboratoryapp.util.LaboratoryTestUtil;
import org.openmrs.ui.framework.SimpleObject;
import org.openmrs.ui.framework.UiUtils;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.*;

/**
 * Created by ngarivictor on 2/24/2016.
 */
public class FunctionalStatusFragmentController {
    public void controller() {

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
        return SimpleObject.fromCollection(billableServices, uiUtils, "name", "serviceId", "disable");
    }

    public void updateBillableServices(
            @RequestParam(value = "serviceIds", required = false) String serviceIds
           ) {

        if (!StringUtils.isBlank(serviceIds)) {
            String[] ids = serviceIds.split(",");
            for (String id : ids) {
                try {
                    if (!StringUtils.isBlank(id)) {
                      Integer sid = Integer.parseInt(id);
                        saveBillableService(sid);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }

    }


    private void saveBillableService(Integer serviceId) {
        BillingService billingService = Context.getService(BillingService.class);
        BillableService billableService = billingService.getServiceById(serviceId);
        if (billableService != null) {
            billableService.setDisable(!billableService.getDisable());
            billingService.saveService(billableService);
        }
    }
}
