<script>
	var queueData,
		rescheduleDialog,
		rescheduleForm,
		acceptForm,
		scheduleDate,
		orderId,
		defaultSampleId,
		details,
		testDetails;

	jq(function(){
		queueData = new QueueData();
		rescheduleDialog, rescheduleForm, acceptForm;
		scheduleDate = jq("#reschedule-date-field");
		orderId = jq("#order");
		defaultSampleId = jq("#defaultSampleId");
		details = { 'patientName' : 'Patient Name', 'startDate' : 'Start Date', 'test' : { 'name' : 'Test Name' } }; 
		testDetails = { details : ko.observable(details) }
	});

	function acceptTest() {
		jq.post('${ui.actionLink("laboratoryapp", "queue", "acceptLabTest")}',
			{ 'orderId' : orderId.val(), 'confirmedSampleId': defaultSampleId.val()},
			function (data) {
				if (data.status === "success") {
					var acceptedTest = ko.utils.arrayFirst(queueData.tests(), function(item) {
						return item.orderId == orderId.val();
					});
					queueData.tests.remove(acceptedTest);
					acceptedTest.status = "accepted";
					acceptedTest.sampleId = data.sampleId;				
					queueData.tests.push(acceptedTest);
				} else if (data.status === "fail") {
					jq().toastmessage('showErrorToast', data.error);
				}
			},
			'json'
		);
	}

	jq(function(){
		acceptDialog = emr.setupConfirmationDialog({
			dialogOpts: {
				overlayClose: false,
				close: true
			},
			selector: '#accept-form',
			actions: {
				confirm: function() {
					acceptTest();
					acceptDialog.close();
				},
				cancel: function() {
					acceptDialog.close();
				}
			}
		});
		
		ko.applyBindings(testDetails, jq("#reschedule-form")[0]);
	});

	jq(function(){
		rescheduleDialog = emr.setupConfirmationDialog({
			dialogOpts: {
				overlayClose: false,
				close: true
			},
			selector: '#reschedule-form',
			actions: {
				confirm: function() {
					saveQueueSchedule();
					rescheduleDialog.close();
				},
				cancel: function() {
					rescheduleDialog.close();
				}
			}
		});

		ko.applyBindings(testDetails, jq("#reschedule-form")[0]);

	});

	function saveQueueSchedule() {
		jq.post('${ui.actionLink("laboratoryapp", "queue", "rescheduleTest")}',
			{ "orderId" : orderId.val(), "rescheduledDate" : moment(scheduleDate.val()).format('DD/MM/YYYY') },
			function (data) {
				if (data.status === "fail") {
					jq().toastmessage('showErrorToast', data.error);
				} else {
					jq().toastmessage('showSuccessToast', data.message);
					var rescheduledTest = ko.utils.arrayFirst(queueData.tests(), function(item) {
						return item.orderId == orderId.val();
					});
					queueData.tests.remove(rescheduledTest);
				}
			},
			'json'
		);
	}

	function reschedule(orderId) {
		jq("#reschedule-form #order").val(orderId);
		var details = ko.utils.arrayFirst(queueData.tests(), function(item) {
			return item.orderId == orderId;
		});
		testDetails.details(details);
		rescheduleDialog.show();
	}

	function accept(orderId) {
		jq("#reschedule-form #order").val(orderId);

		jq.post('${ui.actionLink("laboratoryapp", "queue", "fetchSampleID")}',
			{ 'orderId' : orderId },
			function (data) {
				if (data) {

					defaultSampleId.val(data.defaultSampleId);
					acceptDialog.show();

				} else{
					jq().toastmessage('showErrorToast', data.error);
				}
			},
			'json'
		);
	}
	function QueueData() {
		self = this;
		self.tests = ko.observableArray([]);
	}


	jq(function(){		
		ko.applyBindings(queueData, jq("#test-queue")[0]);
		
		jq("#reschedule-date").datepicker("option", "dateFormat", "dd/MM/yyyy");
	});
</script>

<div>
	<form>
		<fieldset>
			<div class="onerow">
				<div class="col4">
					<label for="referred-date-display">Date Ordered </label>
				</div>
				
				<div class="col4">
					<label for="search-queue-for">Patient Identifier/Name</label>
				</div>
				
				<div class="col4 last">
					<label for="investigation">Investigation</label>
				</div>
			</div>
			
			<div class="onerow">
				<div class="col4">
					${ui.includeFragment("uicommons", "field/datetimepicker", [id: 'referred-date', label: 'Date Ordered', formFieldName: 'referredDate', useTime: false, defaultToday: true])}
				</div>
				
				<div class="col4">
					<input id="search-queue-for" type="text"/>
				</div>
				
				<div class="col4 last">
					<select name="investigation" id="investigation">
						<option value="0">ALL</option>
						<% investigations.each { investigation -> %>
							<option value="${investigation.id}">${investigation.name.name}</option>
						<% } %>	
					</select>
				</div>
			</div>
		
			<br/>
			<br/>
		</fieldset>
	</form>
</div>

<table id="test-queue" >
	<thead>
		<tr>
			<th>Date</th>
			<th>Patient ID</th>
			<th>Name</th>
			<th style="width: 53px">Gender</th>
			<th style="width: 30px">Age</th>
			<th>Test</th>
			<th style="width: 70px;">Sample ID</th>
			<th style="width: 60px;">Action</th>			
		</tr>
	</thead>
	<tbody data-bind="foreach: tests">
		<tr>
			<td data-bind="text: startDate"></td>
			<td data-bind="text: patientIdentifier"></td>
			<td data-bind="text: patientName"></td>
			<td data-bind="text: gender"></td>
			<td data-bind="text: age"></td>
			<td data-bind="text: test.name"></td>
			<td data-bind="attr: { class : 'test-sample-id-' + orderId }">
				<span data-bind="text: sampleId"></span>
				<span data-bind="ifnot: sampleId">&nbsp; &nbsp;&#8212;</span>
			</td>
			
			<td>
				<center id="action-icons">
					<span data-bind="if: status" class="accepted">Accepted</span>
					<span data-bind="ifnot: status">
						<a title="Accept" data-bind="attr: { href: 'javascript:accept(' + orderId + ')' }" ><i class="icon-ok small"></i></a>
					</span>
					
					<span data-bind="ifnot: status"> 
						<a title="Reschedule" data-bind="attr: { href : 'javascript:reschedule(' + orderId + ')' }"><i class="icon-repeat small"></i></a>
					</span>
				</center>
				
			</td>
			
			
			
		</tr>


	</tbody>
</table>

<div id="accept-form" title="Accept" class="dialog">
	<div class="dialog-header">
      <i class="icon-ok"></i>
      <h3>Accept Test</h3>
    </div>
	
	<div class="dialog-content">
		<form>
			<label>Sample ID</label>
			<input type="text" id="defaultSampleId">
			<input type="hidden" id="order_ID">
			<p data-bind="text:test.name"></p>
		</form>
		
		<span class="button confirm right"> Confirm </span>
        <span class="button cancel"> Cancel </span>
	</div>
	
</div>

<div id="reschedule-form" title="Reschedule" class="dialog">
	<div class="dialog-header">
      <i class="icon-repeat"></i>
      <h3>Reschedule Tests</h3>
    </div>
	
	<div class="dialog-content">
		<form>
			<p>
				<div class="dialog-data">Patient Name:</div>
				<div class="inline" data-bind="text: details().patientName"></div>
			</p> 
			
			<p >
				<div class="dialog-data">Test Name:</div>
				<div class="inline" data-bind="text: details().test.name"></div>
			</p>
			
			
			<p>
				<div class="dialog-data">Test Date:</div>
				<div class="inline" data-bind="text: details().startDate"></div>
			</p>
			
			<p>
				<div class="dialog-data">Reschedule To:</div>
				${ui.includeFragment("uicommons", "field/datetimepicker", [id: 'reschedule-date', label: 'Reschedule To', formFieldName: 'rescheduleDate', useTime: false, defaultToday: true, startToday: true])}
			</p>
					
			
			<input type="hidden" id="order" name="order" >

			<!-- Allow form submission with keyboard without duplicating the dialog button -->
			<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">
		</form>
		
		<span class="button confirm right"> Confirm </span>
        <span class="button cancel"> Cancel </span>
	</div>
</div>
