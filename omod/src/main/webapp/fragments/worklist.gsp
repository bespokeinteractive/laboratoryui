<script>
	var resultDialog, 
		resultForm,
		selectedTestDetails,
		parameterOpts = { parameterOptions : ko.observableArray([]) };
	
	var reorderDialog, reorderForm;
	var scheduleDate = jq("#reorder-date");
	var orderIdd;
	var details = { 'patientName' : 'Patient Name', 'startDate' : 'Start Date', 'test' : { 'name' : 'Test Name' } }; 
	var testDetails = { details : ko.observable(details) }
	
	jq(function(){
		orderIdd = jq("#order");
		ko.applyBindings(parameterOpts, jq("#result-form")[0]);
		
		resultDialog = emr.setupConfirmationDialog({
			dialogOpts: {
				overlayClose: false,
				close: true
			},
			selector: '#result-form',
			actions: {
				confirm: function() {
					saveResult();
					resultDialog.close();
				},
				cancel: function() {
					resultDialog.close();
				}
			}
		});
		
		resultForm = jq("#result-form").find( "form" ).on( "submit", function( event ) {
			event.preventDefault();
			saveResult();
		});
	});
	
	jq(function(){
		reorderDialog = emr.setupConfirmationDialog({
			dialogOpts: {
				overlayClose: false,
				close: true
			},
			selector: '#reorder-form',
			actions: {
				confirm: function() {
					saveSchedule();
					reorderDialog.close();
				},
				cancel: function() {
					reorderDialog.close();
				}
			}
		});
		
		reorderForm = jq("#reorder-form").find( "form" ).on( "submit", function( event ) {
			event.preventDefault();
			saveSchedule();
		});

		ko.applyBindings(testDetails, jq("#reorder-form")[0]);

	});
	
	function showResultForm(testDetail) {
		selectedTestDetails = testDetail;
		getResultTemplate(testDetail.testId);
		resultForm.find("#test-id").val(testDetail.testId);
		
	}
	
	function getResultTemplate(testId) {
		jq.getJSON('${ui.actionLink("laboratoryapp", "result", "getResultTemplate")}',
			{ "testId" : testId }
		).success(function(parameterOptions){
			parameterOpts.parameterOptions.removeAll();
			var details = ko.utils.arrayFirst(workList.items(), function(item) {
				return item.testId == testId;
			});
			
			jq.each(parameterOptions, function(index, parameterOption) {
				if (parameterOption.options.length > 0){
					parameterOption.options.splice(0, 0, {"label":"- SELECT RESULT -", "value":""})
				}
			
				parameterOption['patientName'] = details.patientName;
				parameterOption['testName'] = details.test.name;
				parameterOption['startDate'] = details.startDate;
				parameterOpts.parameterOptions.push(parameterOption);
			});
			
			resultDialog.show();
		});
	}
	
	function saveResult(){
		var dataString = resultForm.serialize();
		jq.ajax({
			type: "POST",
			url: '${ui.actionLink("laboratoryapp", "result", "saveResult")}',
			data: dataString,
			dataType: "json",
			success: function(data) {
				if (data.status === "success") {
					jq().toastmessage('showNoticeToast', data.message);
					workList.items.remove(selectedTestDetails);
					resultDialog.dialog("close");
				}
			}
		});
	}

	function reorder(orderId) {
		jq("#reorder-form #order").val(orderId);
		var details = ko.utils.arrayFirst(workList.items(), function(item) {
			return item.orderId == orderId;
		});
		testDetails.details(details);
		reorderDialog.show();
	}

	function saveSchedule() {
		jq.post('${ui.actionLink("laboratoryapp", "queue", "rescheduleTest")}',
			{ "orderId" : orderIdd.val(), "rescheduledDate" : moment(jq("#reorder-date-field").val()).format('DD/MM/YYYY') },
			function (data) {
				if (data.status === "fail") {
					jq().toastmessage('showErrorToast', data.error);
				} else {				
					jq().toastmessage('showSuccessToast', data.message);
					var reorderedTest = ko.utils.arrayFirst(workList.items(), function(item) {
						return item.orderId == orderIdd.val();
					});
					workList.items.remove(reorderedTest);
				}
			},
			'json'
		);
	}
	
	function WorkList() {
		self = this;
		self.items = ko.observableArray([]);
	}
	var workList = new WorkList();
	
	jq(function(){
		ko.applyBindings(workList, jq("#test-worklist")[0]);
	});

	jq(function(){
		var worksheet = { items : ko.observableArray([]) };
		ko.applyBindings(worksheet, jq("#worksheet")[0]);
		jq("#print-worklist").on("click", function() {
			jq.getJSON('${ui.actionLink("laboratoryapp", "worksheet", "getWorksheet")}',
				{ 
					"date" : moment(jq('#accepted-date-field').val()).format('DD/MM/YYYY'),
					"phrase" : jq("#search-worklist-for").val(),
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
			var downloadLink = 
				emr.pageLink("laboratoryapp", "reportExport", 
					{
						"worklistDate" : 
							moment(jq('#accepted-date-field').val()).format('DD/MM/YYYY'),
						"phrase": jq("#search-worklist-for").val(),
						"investigation": jq("#investigation-worklist").val(),
						"includeResults": jq("#include-result").is(":checked")
					}
				);
			var win = window.open(downloadLink, '_blank');
			if(win){
				//Browser has allowed it to be opened
				win.focus();
			}else{
				//Broswer has blocked it
				alert('Please allow popups for this site');
			}
		});
	});

	function printData() {
		jq("#worksheet").print({
				globalStyles: false,
				mediaPrint: false,
				stylesheet: '${ui.resourceLink("referenceapplication","styles/referenceapplication.css")}',
				iframe: true
		});
	}
</script>

<div>
	<form>
		<fieldset>
			<div class="onerow">
				<div class="col4">
					<label for="accepted-date-display"> Date Accepted </label>
				</div>
				
				<div class="col4">
					<label for="search-worklist-for">Patient Identifier/Name</label>
				</div>
				
				<div class="col4 last">
					<label for="investigation-worklist">Investigation</label>
				</div>
			</div>
			
			<div class="onerow">
				<div class="col4">
					${ui.includeFragment("uicommons", "field/datetimepicker", [id: 'accepted-date', label: 'Date Accepted', formFieldName: 'acceptedDate', useTime: false, defaultToday: true])}
				</div>
				
				<div class="col4">
					<input id="search-worklist-for"/>
				</div>
				
				<div class="col4 last">
					<select name="investigation" id="investigation-worklist">
						<option value="0">Select an investigation</option>
						<% investigations.each { investigation -> %>
							<option value="${investigation.id}">${investigation.name.name}</option>
						<% } %>	
					</select>
				</div>
			</div>
			
			<div class="onerow" style="margin-top: 50px">
				<div class="col4">
					<label for="include-result">
						<input type="checkbox" id="include-result" >
						Include result
					</label>
				</div>
				
				<div class="col5 last" style="padding-top: 5px">
					<button type="button" class="task" id="print-worklist">Print Worklist</button>
					<button type="button" class="cancel" id="export-worklist">Export Worklist</button>
				</div>
				

			
			</div>
			
			<br/>
			<br/>
		</fieldset>
	</form>
</div>

<div>
	
	
</div>

<table id="test-worklist">
	<thead>
		<tr>
			<th style="width: 70px;">Sample ID</th>	
			<th>Date</th>
			<th>Patient ID</th>
			<th>Name</th>
			<th style="width: 53px;">Gender</th>
			<th style="width: 30px;">Age</th>
			<th>Test</th>
			<th style="width: 60px;">Action</th>
		</tr>
	</thead>
	<tbody data-bind="foreach: items">
		<tr>
			<td data-bind="text: sampleId"></td>
			<td data-bind="text: startDate"></td>
			<td data-bind="text: patientIdentifier"></td>
			<td data-bind="text: patientName"></td>
			<td data-bind="text: gender"></td>
			<td>
				<span data-bind="if: age < 1">< 1</span>
				<!-- ko if: age > 1 -->
					<span data-bind="text: age"></span>
				<!-- /ko -->
			</td>
			<td data-bind="text: test.name"></td>
			<td> 
				<a title="Enter Results" data-bind="click: showResultForm, attr: { href : '#' }"><i class="icon-list-ul small"></i></a>
				<a title="Re-order Test" data-bind="attr: { href : 'javascript:reorder(' + orderId + ')' }"><i class="icon-share small"></i></a>
			</td>
		</tr>
	</tbody>
</table>

<div id="result-form" title="Results" class="dialog">
	<div class="dialog-header">
      <i class="icon-list-ul"></i>
      <h3>Edit Results</h3>
    </div>
	
	<div class="dialog-content">
		<form>
			<input type="hidden" name="wrap.testId" id="test-id" />
			<div data-bind="if: parameterOptions()[0]">
				<p>
					<div class="dialog-data">Patient Name:</div>
					<div class="inline" data-bind="text: parameterOptions()[0].patientName"></div>
				</p>
				
				<p>
					<div class="dialog-data">Test Name:</div>
					<div class="inline" data-bind="text: parameterOptions()[0].testName"></div>
				</p>
				
				<p>
					<div class="dialog-data">Test Date:</div>
					<div class="inline" data-bind="text: parameterOptions()[0].startDate"></div>
				</p>
			</div>
			
			<div data-bind="foreach: parameterOptions">
				<input type="hidden" data-bind="attr: { 'name' : 'wrap.results[' + \$index() + '].conceptName' }, value: containerId?containerId+'.'+id:id" >
				
				<!--Test for Select-->
				<div data-bind="if:type && type.toLowerCase() === 'select'">
					<p>
						<span data-bind="if:title && title.toUpperCase() === 'TEST RESULT VALUE'">
							<label style="color:#ff3d3d;" data-bind="text: container"></label>						
						</span>
						
						<span data-bind="if:title && title.toUpperCase() !== 'TEST RESULT VALUE'">
							<label style="color:#ff3d3d;" data-bind="text: title"></label>						
						</span>
						
						<select id="result-option" data-bind="attr : { 'name' : 'wrap.results[' + \$index() + '].selectedOption' }, foreach: options" style="width: 98%;">
							<option data-bind="attr: { value : value, selected : (\$parent.defaultValue === value) }, text: label"></option>
						</select>
					</p>
				</div>

				<!--Test for radio or checkbox-->
				<div data-bind="if:(type && type.toLowerCase() === 'radio') || (type && type.toLowerCase() === 'checkbox')">
					<p>
						<div class="dialog-data"></div>
						<label for="result-text">
							<input id="result-text" class="result-text" data-bind="attr : { 'type' : type, 'name' : 'wrap.results[' + \$index() + '].value', value : defaultValue }" >
							<span data-bind="text: title"></span>
						</label>
					</p>
				</div>
				
				<!--Other Input Types-->
				<div data-bind="if:(type && type.toLowerCase() !== 'select') && (type && type.toLowerCase() !== 'radio') && (type && type.toLowerCase() !== 'checkbox')">
					<p id="data">
						<span data-bind="if:title && title.toUpperCase() === 'WRITE COMMENT'">
							<label data-bind="text: title + ' (' + container+')'" style="color:#ff3d3d;"></label>
						</span>
						
						<span data-bind="if:title && title.toUpperCase() !== 'WRITE COMMENT'">
							<label data-bind="text: title" style="color:#ff3d3d;"></label>
						</span>
						
						<input class="result-text" data-bind="attr : { 'type' : type, 'name' : 'wrap.results[' + \$index() + '].value', value : defaultValue }" >
					</p>
				</div>
				
				<div data-bind="if: !type">
					<p>
						<label for="result-text" data-bind="text: title"></label>
						<input class="result-text" type="text" data-bind="attr : {'name' : 'wrap.results[' + \$index() + '].value', value : defaultValue }" >
					</p>
				</div>
			</div>
		</form>
		
		<span class="button confirm right">Confirm</span>
        <span class="button cancel">Cancel</span>
	</div>
	
	
	
</div>

<div id="reorder-form" title="Re-order" class="dialog">
	<div class="dialog-header">
      <i class="icon-share"></i>
      <h3>Re-order Test Results</h3>
    </div>
	
	<div class="dialog-content">
		<form>
			<p>
				<div class="dialog-data">Patient Name:</div>
				<div class="inline" data-bind="text: details().patientName"></div>
			</p>
			
			<p>
				<div class="dialog-data">Test Name:</div>
				<div class="inline" data-bind="text: details().test.name"></div>
			</p>
			
			<p>
				<div class="dialog-data">Test Date:</div>
				<div class="inline" data-bind="text: details().startDate"></div>
			</p>
			
			<p>
				<label for="reorder-date-display" class="dialog-data">Reorder Date:</label>
				${ui.includeFragment("uicommons", "field/datetimepicker", [id: 'reorder-date', label: 'Reschedule To', formFieldName: 'rescheduleDate', useTime: false, defaultToday: true, startToday: true])}		
				<input type="hidden" id="order" name="order" >
			</p>

			<!-- Allow form submission with keyboard without duplicating the dialog button -->
			<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">
		</form>
		
		<span class="button confirm right"> Re-order </span>
        <span class="button cancel"> Cancel </span>
	</div>
 	
</div>


<!-- Worsheet -->
<table id="worksheet">
	<thead>
		<tr>
			<th>Order Date</th>
			<th>Patient Identifier</th>
			<th>Name</th>
			<th>Age</th>
			<th>Gender</th>
			<th>Sample Id</th>
			<th>Lab</th>
			<th>Test</th>
			<th>Result</th>
		</tr>
	</thead>
	<tbody data-bind="if: items().length == 0">
		<tr>
			<td colspan="9">No processed/pending test</td>
		</tr>
	</tbody>
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

<!-- Worksheet -->
<style>
.margin-left {
	margin-left: 10px;
}
#worksheet {
	display: none;
}
</style>
