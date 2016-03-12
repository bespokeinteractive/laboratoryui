<% ui.includeJavascript("laboratoryapp", "jQuery.print.js") %>

<script>
    
	
    jq(function(){
        jq('#date').datepicker("option", "dateFormat", "dd/mm/yy");

        
		
    });
	
    var editResultsDialog,
		editResultsForm,
		editResultsParameterOpts = { editResultsParameterOptions : ko.observableArray([]) };

    jq(function(){
        ko.applyBindings(editResultsParameterOpts, jq("#edit-result-form")[0]);
		
		editResultsDialog = emr.setupConfirmationDialog({
			selector: '#edit-result-form',
			actions: {
				confirm: function() {
					saveEditResult();
					editResultsDialog.close();
				},
				cancel: function() {
					editResultsDialog.close();
				}
			}
		});
		
        /*editResultsDialog = jq("#edit-result-form").dialog({
            autoOpen: false,
            modal: true,
            width: 350,
            buttons: {
                Save: saveEditResult,
                Cancel: function() {
                    editResultsDialog.dialog( "close" );
                }
            },
            close: function() {
                editResultsForm[0].reset();
            }
        });*/

        editResultsForm = jq("#edit-result-form").find( "form" ).on( "submit", function( event ) {
            event.preventDefault();
            saveEditResult();
        });
    });

    function showEditResultForm(testId) {
        getEditResultTempLate(testId);
        editResultsForm.find("#edit-result-id").val(testId);
        editResultsDialog.show();
    }

    function getEditResultTempLate(testId) {
        jq.getJSON('${ui.actionLink("laboratoryapp", "result", "getResultTemplate")}',
                { "testId" : testId }
        ).success(function(editResultsParameterOptions){
                    editResultsParameterOpts.editResultsParameterOptions.removeAll();
                    var details = ko.utils.arrayFirst(result.items(), function(item) {
                        return item.testId == testId;
                    });
                    jq.each(editResultsParameterOptions, function(index, editResultsParameterOption) {
                        editResultsParameterOption['patientName'] = details.patientName;
                        editResultsParameterOption['testName'] = details.test.name;
                        editResultsParameterOption['startDate'] = details.startDate;
                        editResultsParameterOpts.editResultsParameterOptions.push(editResultsParameterOption);
                    });
                });
    }

    function saveEditResult(){
        var dataString = editResultsForm.serialize();
        jq.ajax({
            type: "POST",
            url: '${ui.actionLink("laboratoryapp", "result", "saveResult")}',
            data: dataString,
            dataType: "json",
            success: function(data) {
                if (data.status === "success") {
                    jq().toastmessage('showSuccessToast', data.message);
                    editResultsDialog.dialog("close");
                }
				else {
					jq().toastmessage('showErrorToast', data.error);
				}
            }
        });
    }

    function loadPatientReport(patientId){
        console.log(editResultsDate);
        queryparamenters = "?patientId=" + patientId + '&selectedDate=' + editResultsDate;
        window.location.replace('${ui.pageLink("laboratoryapp", "patientReport")}'+queryparamenters);
    }
    function Result() {
        self = this;
        self.items = ko.observableArray([]);
    }
    var result = new Result();

    jq(function(){
        ko.applyBindings(result, jq("#test-results")[0]);
    });
</script>

<div>
    <form>
        <fieldset>
			<div class="onerow">
				<div class="col4">
					<label for="accepted-date-edit-display">Date </label>
				</div>
				
				<div class="col4">
					<label for="search-results-for">Patient Identifier/Name</label>
				</div>
				
				<div class="col4 last">
					<label for="investigation-results">Investigation</label>
				</div>
			</div>
			
			<div class="onerow">
				<div class="col4">
					${ui.includeFragment("uicommons", "field/datetimepicker", [id: 'accepted-date-edit', label: 'Date', formFieldName: 'acceptedDate', useTime: false, defaultToday: true])}
				</div>
				
				<div class="col4">
					<input id="search-results-for"/>
				</div>
				
				<div class="col4 last">
					<select name="investigation" id="investigation-results">
						<option value="0">Select an investigation</option>
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

<table id="test-results">
    <thead>
    <th>Sample ID</th>
    <th>Date</th>
    <th>Patient ID</th>
    <th>Name</th>
    <th>Gender</th>
    <th>Age</th>
    <th>Test</th>
    <th>Results</th>
    <th>Reports</th>
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
        <a data-bind="attr: { href : 'javascript:showEditResultForm(' + testId + ')' }">Edit Result</a>
    </td>
    <td>
        <a data-bind="attr: { href : 'javascript:loadPatientReport(' + patientId + ')' }">Report</a>
    </td>
    </tbody>
</table>

<div id="edit-result-form" title="Results" class="dialog">
	<div class="dialog-header">
      <i class="icon-edit"></i>
      <h3>Edit Results</h3>
    </div>
	
	<div class="dialog-content">
		<form>
			<input type="hidden" name="wrap.testId" id="edit-result-id" />
			
			<div data-bind="foreach: editResultsParameterOptions">
				<input type="hidden" data-bind="attr: { 'name' : 'wrap.results[' + \$index() + '].conceptName' }, value: title" >
								
				<p>
					<div class="dialog-data">Patient Name:</div>
					<div class="inline" data-bind="text: patientName"></div>
				</p>
				
				<p>
					<div class="dialog-data">Test Name:</div>
					<div class="inline" data-bind="text: testName"></div>
				</p>
				
				<p>
					<div class="dialog-data">Patient Name:</div>
					<div class="inline" data-bind="text: startDate"></div>
				</p>
				
				
				<div data-bind="if: type && type.toLowerCase() === 'select'">
					<p>
						<label for="resultr-option" class="dialog-data input-position-class left" data-bind="text: title"></label>
						<select id="resultr-option"
								data-bind="attr : { 'name' : 'wrap.results[' + \$index() + '].selectedOption' },
								foreach: options">
							<option data-bind="attr: { name : value, selected : (\$parent.defaultValue === value) }, text: label"></option>
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
				
				<!--Other Inputs-->
				<div data-bind="if:(type && type.toLowerCase() !== 'select') && (type && type.toLowerCase() !== 'radio') && (type && type.toLowerCase() !== 'checkbox')">
					<p>
						<label for="result-text" data-bind="text: title" style="color:#ff3d3d;"></label>
						<input class="result-text" data-bind="attr : { 'type' : type, 'name' : 'wrap.results[' + \$index() + '].value', value : defaultValue }" >
					</p>
				</div>
				
				<div data-bind="if: !type">
					<label for="result-text" data-bind="text: title"></label>
					<input id="result-text" class="result-text" type="text" data-bind="attr : { 'name' : 'wrap.results[' + \$index() + '].value' }" >
				</div>
			</div>
		</form>
		
		<span class="button confirm right"> Save Results </span>
        <span class="button cancel"> Cancel </span>
	</div>
	
    
</div>



