<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.11.0/moment.js"></script>

<script>
	function QueueData() {
		self = this;
		self.tests = ko.observableArray([]);
	}

	var queueData = new QueueData();

	jq(function(){		
		ko.applyBindings(queueData, jq("#test-queue")[0]);
		
		jq("#reschedule-date").datepicker("option", "dateFormat", "dd/MM/yyyy");
	});
</script>

<div>
	<form>
		<fieldset>
			${ui.includeFragment("uicommons", "field/datetimepicker", [id: 'referred-date', label: 'Date Ordered', formFieldName: 'referredDate', useTime: false, defaultToday: true])}
			<label for="search-queue-for">Patient Identifier/Name</label>
			<input id="search-queue-for"/>
			<label for="investigation">Investigation</label>
			<select name="investigation" id="investigation">
				<option value="0">ALL</option>
				<% investigations.each { investigation -> %>
					<option value="${investigation.id}">${investigation.name.name}</option>
				<% } %>	
			</select>
			<br/>
			<input type="button" value="Get patients" id="get-tests"/>
		</fieldset>
	</form>
</div>

<table id="test-queue" >
	<thead>
		<tr>
			<th>Date</th>
			<th>Patient ID</th>
			<th>Name</th>
			<th>Gender</th>
			<th>Age</th>
			<th>Test</th>
			<th>Accept</th>
			<th>Sample ID</th>
			<th>Reschedule</th>			
		</tr>
	</thead>
	<tbody data-bind="foreach: tests">
		<tr>
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
			<td data-bind="attr: { class : 'test-status-' + orderId }">
				<span data-bind="if: status">Accepted</span>
				<span data-bind="ifnot: status">
					<a data-bind="attr: { href: 'javascript:accept(' + orderId + ')' }">
						Accept
					</a>
				</span>
			</td>
			<td data-bind="attr: { class : 'test-sample-id-' + orderId }, text: sampleId"></td>
			<div id="accept-form" title="Accept">
				<form>
					<fieldset>
						<label>Sample ID</label>
						<input type="text" id="defaultSampleId">
						<input type="hidden" id="order_ID">
						<p data-bind="text:test.name"></p>
					</fieldset>
				</form>
			</div>
			<td>
				<span data-bind="ifnot: status"> 
					<a data-bind="attr: { href : 'javascript:reschedule(' + orderId + ')' }">Reschedule</a>
				</span>
			</td>
		</tr>


	</tbody>
</table>

<div id="reschedule-form" title="Reschedule">
 	<form>
		<fieldset>
			<p data-bind="text: 'Patient Name: ' + details().patientName"></p> 
			<p data-bind="text: 'Test: ' + details().test.name"></p>
			<p data-bind="text: 'Date: ' + details().startDate"></p>
			<label for="name">Reschedule To</label>
			<input type="date" name="rescheduleDate" id="reschedule-date" class="text ui-widget-content ui-corner-all">
			<input type="hidden" id="order" name="order" >

			<!-- Allow form submission with keyboard without duplicating the dialog button -->
			<input type="submit" tabindex="-1" style="position:absolute; top:-1000px">
		</fieldset>
	</form>
</div>


<script>
jq(function(){
	jq("#get-tests").on("click", function(){
		var date = jq("#referred-date-field").val();
		var searchQueueFor = jq("#search-queue-for").val();
		var investigation = jq("#investigation").val();
		jq.getJSON('${ui.actionLink("laboratoryapp", "Queue", "searchQueue")}',
			{ 
				"date" : moment(date).format('DD/MM/YYYY'),
				"phrase" : searchQueueFor,
				"investigation" : investigation,
				"currentPage" : 1
			}
		).success(function(data) {
			if (data.length === 0) {
				jq().toastmessage('showNoticeToast', "No match found!");
			}
			queueData.tests.removeAll();
			jq.each(data, function(index, testInfo){
				queueData.tests.push(testInfo);
			});
		});
	});
});
</script>

<script>
var dialog, form, acceptForm;
var scheduleDate = jq("#reschedule-date");
var orderId = jq("#order");
var  defaultSampleId = jq("#defaultSampleId");
var details = { 'patientName' : 'Patient Name', 'startDate' : 'Start Date', 'test' : { 'name' : 'Test Name' } }; 
var testDetails = { details : ko.observable(details) }

function acceptTest() {

	console.log(orderId.val());
	console.log(defaultSampleId.val());

	jq.post('${ui.actionLink("laboratoryapp", "queue", "acceptLabTest")}',
		{ 'orderId' : orderId.val(), 'confirmedSampleId': defaultSampleId.val()},
		function (data) {
			if (data.status === "success") {
				console.log("Test accepted");
				var acceptedTest = ko.utils.arrayFirst(queueData.tests(), function(item) {
					return item.orderId == orderId;
				});
				console.log("Accepted test (before update): " + acceptedTest);
				queueData.tests.remove(acceptedTest);
				acceptedTest.status = "accepted";
				acceptedTest.sampleId = data.sampleId;				
				console.log("Accepted test (after before update): " + acceptedTest);
				queueData.tests.push(acceptedTest);
			} else if (data.status === "fail") {
				jq().toastmessage('showErrorToast', data.error);
			}
		},
		'json'
	);
}

jq(function(){
	acceptDialog = jq("#accept-form").dialog({
		autoOpen: false,
		height: 250,
		width: 400,
		modal: true,
		buttons: {
			Accept: acceptTest,
			Cancel: function() {
				acceptDialog.dialog( "close" );
			}
		},
		close: function() {
			acceptForm[ 0 ].reset();
		}
	});

	acceptForm = acceptDialog.find( "form" ).on( "submit", function( event ) {
		event.preventDefault();
		acceptTest(orderId.val());
	});

	ko.applyBindings(testDetails, jq("#reschedule-form")[0]);
});

jq(function(){	
	dialog = jq("#reschedule-form").dialog({
		autoOpen: false,
		height: 350,
		width: 400,
		modal: true,
		buttons: {
			Reschedule: saveSchedule,
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
		saveSchedule();
	});

	ko.applyBindings(testDetails, jq("#reschedule-form")[0]);

});

function saveSchedule() {
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
				dialog.dialog("close");
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
	dialog.dialog( "open" );
}

function accept(orderId) {
	jq("#reschedule-form #order").val(orderId);

	jq.post('${ui.actionLink("laboratoryapp", "queue", "fetchSampleID")}',
			{ 'orderId' : orderId },
			function (data) {
				if (data) {
					console.log(data.defaultSampleId);
					defaultSampleId.val(data.defaultSampleId);
					acceptDialog.dialog( "open" );

				} else{
					jq().toastmessage('showErrorToast', data.error);
				}
			},
			'json'
	);
}

</script>
