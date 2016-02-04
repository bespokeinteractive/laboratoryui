<% ui.includeJavascript("laboratoryapp", "jQuery.print.js") %>

<script>
    jq(function(){
        jq('#date').datepicker("option", "dateFormat", "dd/mm/yy");

        jq('#get-results').on('click', function () {
            var date = moment(jq('#accepted-date-field').val()).format('DD/MM/YYYY');
            var phrase = jq("#phrase").val();
            var investigation = jq("#investigation").val();
            jq.getJSON('${ui.actionLink("laboratoryapp", "results", "searchWorkList")}',
                    {
                        "date" : date,
                        "phrase" : phrase,
                        "investigation" : investigation
                    }
            ).success(function(data) {
                        if (data.length === 0) {
                            jq().toastmessage('showNoticeToast', "No match found!");
                        }
                        result.items.removeAll();
                        jq.each(data, function(index, testInfo){
                            result.items.push(testInfo);
                        });
                    });
        });
    });
</script>

<div>
    <form>
        <fieldset>
            ${ui.includeFragment("uicommons", "field/datetimepicker", [id: 'accepted-date', label: 'Date', formFieldName: 'acceptedDate', useTime: false, defaultToday: true])}
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
            <input type="button" value="Get patients" id="get-results"/>
        </fieldset>
    </form>
</div>

<table id="results">
    <thead>
    <th>Sample ID</th>
    <th>Date</th>
    <th>Patient ID</th>
    <th>Name</th>
    <th>Gender</th>
    <th>Age</th>
    <th>Test</th>
    <th>Results</th>
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
        <a data-bind="attr: { href : 'javascript:showReSultForm(' + testId + ')' }">Edit Result</a>
    </td>
    </tbody>
</table>

<div id="myresult-form" title="Results">
    <form>
        <fieldset>
            <input type="hidden" name="wrap.testId" id="testresult-id" />
            <div data-bind="foreach: resultsParameterOptions">
                <input type="hidden" data-bind="attr: { 'name' : 'wrap.results[' + \$index() + '].conceptName' }, value: title" >
                <p data-bind="text: 'Patient Name: ' + patientName"></p>
                <p data-bind="text: 'Test: ' + testName"></p>
                <p data-bind="text: 'Date: ' + startDate"></p>
                <div data-bind="if: type && type.toLowerCase() === 'select'">
                    <label for="resultr-option" class="input-position-class left" data-bind="text: title"></label>
                    <select id="resultr-option"
                            data-bind="attr : { 'name' : 'wrap.results[' + \$index() + '].selectedOption' },
							foreach: options">
                        <option data-bind="attr: { name : value, selected : (\$parent.defaultValue === value) }, text: label"></option>
                    </select>
                </div>
                <div data-bind="if: type && type.toLowerCase() !== 'select'">
                    <label for="result-text" data-bind="text: title"></label>
                    <input id="result-text" class="result-text" data-bind="attr : { 'type' : type, 'name' : 'wrap.results[' + \$index() + '].value' }" >
                </div>
                <div data-bind="if: !type">
                    <label for="result-text" data-bind="text: title"></label>
                    <input class="result-text" type="text" data-bind="attr : { 'name' : 'wrap.results[' + \$index() + '].value' }" >
                </div>
            </div>
        </fieldset>
    </form>
</div>


<script>
    var resultsDialog,
            resultsForm,
            resultsParameterOpts = { resultsParameterOptions : ko.observableArray([]) };

    jq(function(){
        ko.applyBindings(resultsParameterOpts, jq("#myresult-form")[0]);

        resultsDialog = jq("#myresult-form").dialog({
            autoOpen: false,
            modal: true,
            width: 350,
            buttons: {
                Save: saveReSult,
                Cancel: function() {
                    resultsDialog.dialog( "close" );
                }
            },
            close: function() {
                resultsForm[0].reset();
            }
        });

        resultsForm = resultsDialog.find( "form" ).on( "submit", function( event ) {
            event.preventDefault();
            saveReSult();
        });
    });

    function showReSultForm(testId) {
        getResultTempLate(testId);
        resultsForm.find("#testresult-id").val(testId);
        resultsDialog.dialog( "open" );
    }

    function getResultTempLate(testId) {
        jq.getJSON('${ui.actionLink("laboratoryapp", "result", "getResultTemplate")}',
                { "testId" : testId }
        ).success(function(resultsParameterOptions){
                    resultsParameterOpts.resultsParameterOptions.removeAll();
                    var details = ko.utils.arrayFirst(result.items(), function(item) {
                        return item.testId == testId;
                    });
                    jq.each(resultsParameterOptions, function(index, resultsParameterOption) {
                        resultsParameterOption['patientName'] = details.patientName;
                        resultsParameterOption['testName'] = details.test.name;
                        resultsParameterOption['startDate'] = details.startDate;
                        resultsParameterOpts.resultsParameterOptions.push(resultsParameterOption);
                    });
                });
    }

    function saveReSult(){
        var dataString = resultsForm.serialize();
        jq.ajax({
            type: "POST",
            url: '${ui.actionLink("laboratoryapp", "result", "saveResult")}',
            data: dataString,
            dataType: "json",
            success: function(data) {
                if (data.status === "success") {
                    jq().toastmessage('showNoticeToast', data.message);
                    resultsDialog.dialog("close");
                }
            }
        });
    }
</script>

<script>
    function Result() {
        self = this;
        self.items = ko.observableArray([]);
    }
    var result = new Result();

    jq(function(){
        ko.applyBindings(result, jq("#results")[0]);
    });
</script>