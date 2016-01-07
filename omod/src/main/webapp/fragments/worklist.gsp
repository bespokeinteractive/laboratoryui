<% ui.includeJavascript("laboratoryui", "jQuery.print.js") %>

<script>
	jq(function(){
		jq('#date').datepicker("option", "dateFormat", "dd/mm/yy");
		
		jq('#get-worklist').on('click', function () {
			var date = jq("#date").val();
			var phrase = jq("#phrase").val();
			var investigation = jq("#investigation").val();
			jq.getJSON('${ui.actionLink("laboratoryui", "worklist", "searchWorkList")}',
				{ 
					"date" : date,
					"phrase" : phrase,
					"investigation" : investigation
				}
			).success(function(data) {
				workList.items.removeAll();
				jq.each(data, function(index, testInfo){
					workList.items.push(testInfo);
				});
			});
		});
	});
</script>

<div>
	<form>
		<fieldset>
			<label for="date">Date</label>
			<input class="date" id="date" name="date" value="${currentDate}" />
			<label for="phrase">Patient Identifier/Name</label>
			<input id="phrase"/>
			<label for="investigation">Investigation</label>
			<select name="investigation" id="investigation">
				<option>Select an investigation</option>
				<% investigations.each { investigation -> %>
					<option value="${investigation.id}">${investigation.name.name}</option>
				<% } %>	
			</select>
			<br/>
			<input type="button" value="Get patients" id="get-worklist"/>
		</fieldset>
	</form>
</div>

<div>
	<label for="include-result">Include result</label>
	<input type="checkbox" id="include-result" >
	<button id="print-worklist">Print Worklist</button>
	<button id="export-worklist">Export Worklist</button>
</div>

<table id="worklist">
	<thead>
		<th>Sample ID</th>	
		<th>Date</th>
		<th>Patient ID</th>
		<th>Name</th>
		<th>Gender</th>
		<th>Age</th>
		<th>Test</th>
		<th>Results</th>
		<th>Reorder</th>
	</thead>
	<tbody data-bind="foreach: items">
		<td data-bind="text: sampleId"></td>
		<td data-bind="text: startDate"></td>
		<td data-bind="text: patientIdentifier"></td>
		<td data-bind="text: patientName"></td>
		<td data-bind="text: gender"></td>
		<td>
			<span data-bind="if: age < 1">Less than 1 year</span>
			<!-- ko if: age > 1 -->
				<span data-bind="value: age"></span>
			<!-- /ko -->
		</td>
		<td data-bind="text: test.name"></td>
		<td> 
			<a data-bind="attr: { href : 'javascript:showResultForm(' + testId + ')' }">Enter Result</a>
		</td>
		<td>
			<a data-bind="attr: { href : 'javascript:reorder(' + orderId + ')' }">Re-order</a>
		</td>
	</tbody>
</table>

<div id="result-form" title="Results">
	<form>
		<fieldset>
			<input type="hidden" name="wrap.testId" id="test-id" />
			<div data-bind="foreach: parameterOptions">
				<input type="hidden" data-bind="attr: { 'name' : 'wrap.results[' + \$index() + '].conceptName' }, value: title" >
				<p data-bind="text: 'Patient Name: ' + patientName"></p> 
				<p data-bind="text: 'Test: ' + testName"></p>
				<p data-bind="text: 'Date: ' + startDate"></p>
				<div data-bind="if: type.toLowerCase() === 'select'">
					<label for="result-option" class="input-position-class left" data-bind="text: title"></label>
					<select id="result-option" 
						data-bind="attr : { 'name' : 'wrap.results[' + \$index() + '].selectedOption' },
							foreach: options">
						<option data-bind="attr: { name : value, selected : (\$parent.defaultValue === value) }, text: label"></option>
					</select>
				</div>
				<div data-bind="if: type.toLowerCase() !== 'select'">
					<label for="result-text" data-bind="text: title"></label>
					<input class="result-text" data-bind="attr : { 'type' : type, 'name' : 'wrap.results[' + \$index() + '].value' }" >
				</div>
			</div>
		</fieldset>
	</form>
</div>

<div id="reorder-form" title="Re-order">
 	<form>
		<fieldset>
			<p data-bind="text: 'Patient Name: ' + details().patientName"></p> 
			<p data-bind="text: 'Test: ' + details().test.name"></p>
			<p data-bind="text: 'Date: ' + details().startDate"></p>
			<label for="name">Reorder Date</label>
			<input type="date" name="reorderDate" id="reorder-date" class="text ui-widget-content ui-corner-all">
			<input type="hidden" id="order" name="order" >

			<!-- Allow form submission with keyboard without duplicating the dialog button -->
			<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">
		</fieldset>
	</form>
</div>

<script>
	var dialog, 
	form, 
	parameterOpts = { parameterOptions : ko.observableArray([]) };
	
	jq(function(){
		ko.applyBindings(parameterOpts, jq("#result-form")[0]);
		
		dialog = jq("#result-form").dialog({
			autoOpen: false,
			modal: true,
			width: 350,
			buttons: {
				Save: saveResult,
				Cancel: function() {
					dialog.dialog( "close" );
				}
			},
			close: function() {
				form[ 0 ].reset();
				allFields.removeClass( "ui-state-error" );
			}
		});
		
		form = dialog.find( "form" ).on( "submit", function( event ) {
			event.preventDefault();
			saveResult();
		});
	});
	
	function showResultForm(testId) {
		getResultTemplate(testId);
		form.find("#test-id").val(testId);
		dialog.dialog( "open" );
	}
	
	function getResultTemplate(testId) {
		jq.getJSON('${ui.actionLink("laboratoryui", "result", "getResultTemplate")}',
			{ "testId" : testId }
		).success(function(parameterOptions){
			parameterOpts.parameterOptions.removeAll();
			var details = ko.utils.arrayFirst(workList.items(), function(item) {
				return item.testId == testId;
			});
			jq.each(parameterOptions, function(index, parameterOption) {
				parameterOption['patientName'] = details.patientName;
				parameterOption['testName'] = details.test.name;
				parameterOption['startDate'] = details.startDate;
				parameterOpts.parameterOptions.push(parameterOption);
			});
		});
	}
	
	function saveResult(){
		var dataString = form.serialize();
		jq.ajax({
			type: "POST",
			url: '${ui.actionLink("laboratoryui", "result", "saveResult")}',
			data: dataString,
			dataType: "json",
			success: function(data) {
				if (data.status === "success") {
					jq().toastmessage('showSuccessToast', data.message);
					dialog.dialog("close");
				}
			}
		});
	}
</script>

<script>
var rescheduleDialog, rescheduleForm;
var scheduleDate = jq("#reorder-date");
var orderId = jq("#order");
var details = { 'patientName' : 'Patient Name', 'startDate' : 'Start Date', 'test' : { 'name' : 'Test Name' } }; 
var testDetails = { details : ko.observable(details) }

jq(function(){	
	rescheduleDialog = jq("#reorder-form").dialog({
		autoOpen: false,
		width: 350,
		modal: true,
		buttons: {
			"Re-order": saveSchedule,
			Cancel: function() {
				rescheduleDialog.dialog( "close" );
			}
		},
		close: function() {
			rescheduleForm[ 0 ].reset();
			allFields.removeClass( "ui-state-error" );
		}
	});
	
	rescheduleForm = rescheduleDialog.find( "form" ).on( "submit", function( event ) {
		event.preventDefault();
		saveSchedule();
	});

	ko.applyBindings(testDetails, jq("#reorder-form")[0]);

});

function reorder(orderId) {
	jq("#reorder-form #order").val(orderId);
	var details = ko.utils.arrayFirst(workList.items(), function(item) {
		return item.orderId == orderId;
	});
	testDetails.details(details);
	rescheduleDialog.dialog( "open" );
}

function saveSchedule() {
	jq.post('${ui.actionLink("laboratoryui", "LaboratoryQueue", "rescheduleTest")}',
		{ "orderId" : orderId.val(), "rescheduledDate" : moment(scheduleDate.val()).format('DD/MM/YYYY') },
		function (data) {
			if (data.status === "fail") {
				jq().toastmessage('showErrorToast', data.error);
			} else {				
				jq().toastmessage('showSuccessToast', data.message);
				var reorderedTest = ko.utils.arrayFirst(workList.items(), function(item) {
					return item.orderId == orderId.val();
				});
				workList.items.remove(reorderedTest);
				rescheduleDialog.dialog("close");
			}
		},
		'json'
	);
}
</script>

<script>
	function WorkList() {
		self = this;
		self.items = ko.observableArray([]);
	}
	var workList = new WorkList();
	
	jq(function(){
		ko.applyBindings(workList, jq("#worklist")[0]);
	});
</script>

<!-- Worsheet -->
<table id="worksheet">
	<thead>
		<th>Order Date</th>
		<th>Patient Identifier</th>
		<th>Name</th>
		<th>Age</th>
		<th>Gender</th>
		<th>Sample Id</th>
		<th>Lab</th>
		<th>Test</th>
		<th>Result</th>
	</thead>
	<tbody data-bind="foreach: items">
		<tr>
			<td data-bind="text: startDate"></td>
			<td data-bind="text: patientIdentifier"></td>
			<td data-bind="text: patientName"></td>
			<td data-bind="text: age"></td>
			<td data-bind="text: gender"></td>
			<td data-bind="text: sampleId"></td>
			<td data-bind="text: investigation"></td>
			<td data-bind="text: test.name"></td>
			<td data-bind="text: value"></td>
		</tr>
	</tbody>
</table>
<script>
jq(function(){
	var worksheet = { items : ko.observableArray([]) };
	ko.applyBindings(worksheet, jq("#worksheet")[0]);
	jq("#worksheet").hide();
	jq("#print-worklist").on("click", function() {
		jq.getJSON('${ui.actionLink("laboratoryui", "worksheet", "getWorksheet")}',
			{ 
				"date" : jq("#date").val(),
				"phrase" : jq("#phrase").val(),
				"investigation" : jq("#investigation").val(),
				"showResults" : jq("#include-result").is(":checked")
			}
		).success(function(data) {
			worksheet.items.removeAll();
			jq.each(data, function (index, item) {
				worksheet.items.push(item);
			});
			printData();
		});
	});
	
	jq("#export-worklist").on("click", function() {
		window.location = "/" + OPENMRS_CONTEXT_PATH + "/module/laboratory/download.form?" +
			"date=" + jq("#date").val() + "&phrase=" + jq("#phrase").val() +
			"&investigation=" + jq("#investigation").val() +
			"&showResults=" + jq("#include-result").is(":checked");
	});
});

function printData() {
	jq("#worksheet").print({
            mediaPrint: false,
            stylesheet: '${ui.resourceLink("referenceapplication","styles/referenceapplication.css")}',
            iframe: true
    });
}
</script>
<!-- Worksheet -->