package org.openmrs.module.laboratoryapp.page.controller;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.openmrs.Concept;
import org.openmrs.api.context.Context;
import org.openmrs.module.hospitalcore.model.LabTest;
import org.openmrs.module.laboratory.LaboratoryService;
import org.openmrs.module.laboratoryapp.util.LaboratoryTestUtil;
import org.openmrs.module.laboratoryapp.util.LaboratoryUtil;
import org.openmrs.module.laboratoryapp.util.TestModel;
import org.openmrs.ui.framework.UiUtils;
import org.openmrs.ui.framework.page.FileDownload;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestParam;

public class ReportExportPageController {

	private static Logger logger = LoggerFactory.getLogger(ReportExportPageController.class);

	public FileDownload get(
			@RequestParam(value = "worklistDate", required = false) String worklistDateString,
			@RequestParam(value = "phrase", required = false) String phrase,
			@RequestParam(value = "investigation", required = false) Integer investigationId,
			@RequestParam(value = "includeResults", required = false) String includeResults,
			UiUtils ui) {
		LaboratoryService laboratoryService = Context.getService(LaboratoryService.class);
		Date worklistDate;
		try {
			worklistDate = new SimpleDateFormat("dd/MM/yyyy").parse(worklistDateString);
			Map<Concept, Set<Concept>> testTreeMap = LaboratoryTestUtil.getAllowableTests();
			Set<Concept> allowableTests = new HashSet<Concept>();
			Concept investigation = Context.getConceptService().getConcept(investigationId);
			if (investigation != null) {
				allowableTests = testTreeMap.get(investigation);
			} else {
				for (Concept c : testTreeMap.keySet()) {
					allowableTests.addAll(testTreeMap.get(c));
				}
			}
			List<LabTest> laboratoryTests = laboratoryService.getAllLaboratoryTestsByDate(worklistDate, phrase, allowableTests);
			List<TestModel> formattedLaboratoyTests = LaboratoryUtil.generateModelsForWorksheet(laboratoryTests, testTreeMap, includeResults);;
			String filename = "Lab Worklist for " + ui.formatDatePretty(worklistDate) + ".xls";
			String contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
			//String contentType = "application/vnd.ms-excel";
			return new FileDownload(filename, contentType, buildExcelDocument(formattedLaboratoyTests));
		} catch (ParseException e) {
			logger.error("Error when parsing order date!", e.getMessage());
		} catch (IOException e) {
			logger.error("Error while generating excel document", e.getMessage());
		}
		return null;
	}

	private byte[] buildExcelDocument(List<TestModel> tests) throws IOException {
		HSSFWorkbook worklistBook = new HSSFWorkbook();
		HSSFSheet worklistSheet = worklistBook.createSheet("Lab worklist");
		setExcelHeader(worklistSheet);
		setExcelRows(worklistSheet, tests);
		ByteArrayOutputStream excelOutput = new ByteArrayOutputStream();

		worklistBook.write(excelOutput);
		return excelOutput.toByteArray();
	}
	
	private void setExcelHeader(HSSFSheet excelSheet) {
		HSSFRow excelHeader = excelSheet.createRow(0);
		excelHeader.createCell(0).setCellValue("Accepted Date");
		excelHeader.createCell(1).setCellValue("Patient Identifier");
		excelHeader.createCell(2).setCellValue("Name");
		excelHeader.createCell(3).setCellValue("Age");
		excelHeader.createCell(4).setCellValue("Gender");
		excelHeader.createCell(5).setCellValue("Sample No.");
		excelHeader.createCell(6).setCellValue("Lab");
		excelHeader.createCell(7).setCellValue("Test");
		excelHeader.createCell(8).setCellValue("Test Name");
		excelHeader.createCell(9).setCellValue("Result");
	}

	private void setExcelRows(HSSFSheet excelSheet, List<TestModel> tests){
		int record = 1;
		for (TestModel test : tests) {
			HSSFRow excelRow = excelSheet.createRow(record++);
			excelRow.createCell(0).setCellValue(test.getAcceptedDate());
			excelRow.createCell(1).setCellValue(test.getPatientIdentifier());
			excelRow.createCell(2).setCellValue(test.getPatientName());
			excelRow.createCell(3).setCellValue(test.getAge());
			excelRow.createCell(4).setCellValue(test.getGender());
			excelRow.createCell(5).setCellValue(test.getSampleId());
			excelRow.createCell(6).setCellValue(test.getInvestigation());
			excelRow.createCell(7).setCellValue(test.getTest().getDisplayString());
			excelRow.createCell(8).setCellValue(test.getTestName().getDisplayString());
			excelRow.createCell(9).setCellValue(test.getValue());
		}
	}

}
