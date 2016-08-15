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
			dialogOpts: {
				overlayClose: false,
				close: true
			},
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

        editResultsForm = jq("#edit-result-form").find( "form" ).on( "submit", function( event ) {
            event.preventDefault();
            saveEditResult();
        });
    });

    function showEditResultForm(testId) {
        getEditResultTempLate(testId);
        editResultsForm.find("#edit-result-id").val(testId);
        
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
				if (editResultsParameterOption.options.length > 0){
					editResultsParameterOption.options.splice(0, 0, {"label":"- SELECT RESULT -", "value":""})
				}
				
				editResultsParameterOption['patientName'] = details.patientName;
				editResultsParameterOption['testName'] = details.test.name;
				editResultsParameterOption['startDate'] = details.startDate;
				editResultsParameterOpts.editResultsParameterOptions.push(editResultsParameterOption);
			});
			
			editResultsDialog.show();
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

    function loadPatientReport(patientId, testId){
        window.location = emr.pageLink("laboratoryapp", "patientReport", {patientId: patientId, testId: testId});
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
					<label for="accepted-date-edit-display">Date</label>
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
						<option value="0">ALL INVESTIGATIONS</option>
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
		<th>Ordered</th>
		<th>Patient ID</th>
		<th>Name</th>
		<th style="width: 53px;">Gender</th>
		<th style="width: 30px;">Age</th>
		<th>Test</th>
		<th style="width: 60px;">Action</th>
    </thead>
	
    <tbody data-bind="foreach: items">
		<td data-bind="text: sampleId"></td>
		<td data-bind="text: startDate"></td>
		<td data-bind="text: patientIdentifier"></td>
		<td data-bind="text: patientName"></td>
		<td data-bind="text: gender"></td>
		<td data-bind="text: age"></td>
		<td data-bind="text: test.name"></td>
		<td>
			<a title="Edit Result" data-bind="attr: { href : 'javascript:showEditResultForm(' + testId + ')' }"><i class="icon-file-alt small"></i></a>
			<a title="View Report" data-bind="attr: { href : 'javascript:loadPatientReport(' + patientId + ', ' + testId + ')' }"><i class="icon-bar-chart small"></i></a>
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
			
			<div data-bind="if: editResultsParameterOptions()[0]">			
				<p>
					<div class="dialog-data">Patient Name:</div>
					<div class="inline" data-bind="text: editResultsParameterOptions()[0].patientName"></div>
				</p>
				
				<p>
					<div class="dialog-data">Test Name:</div>
					<div class="inline" data-bind="text: editResultsParameterOptions()[0].testName"></div>
				</p>
				
				<p>
					<div class="dialog-data">Patient Name:</div>
					<div class="inline" data-bind="text: editResultsParameterOptions()[0].startDate"></div>
				</p>				
			</div>
			
			<div data-bind="foreach: editResultsParameterOptions">
				<input type="hidden" data-bind="attr: { 'name' : 'wrap.results[' + \$index() + '].conceptName' }, value: containerId?containerId+'.'+id:id" >
								
				
				<div data-bind="if:type && type.toLowerCase() === 'select'">
					<p>
						<span data-bind="if:title && title.toUpperCase() === 'TEST RESULT VALUE'">
							<label style="color:#ff3d3d;" data-bind="text: container"></label>						
						</span>
						
						<span data-bind="if:title && title.toUpperCase() !== 'TEST RESULT VALUE'">
							<label style="color:#ff3d3d;" data-bind="text: title"></label>						
						</span>
						
						<select id="result-option" 
							data-bind="attr : { 'name' : 'wrap.results[' + \$index() + '].selectedOption' },
								foreach: options" style="width: 98%;">
							<option data-bind="attr: { value : value, selected : (\$parent.defaultValue === label) }, text: label"></option>
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
		
		<span class="button confirm right">Save Results</span>
        <span class="button cancel">Cancel</span>
	</div>
	
    
</div>



