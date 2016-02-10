<form>
    <p>
        <label for="result-date">Result Date</label>
        <input type="text" id="result-date" >
    </p>
    <button id="get-report">Get Report</button>
</form>
<div class="clear"></div>

${ui.includeFragment("coreapps", "patientHeader", [patient: patient])}

<table id="patient-report">
    <thead>
    <tr>
        <th>Test</th>
        <th>Result</th>
        <th>Units</th>
        <th>Reference Range</th>
    </tr>
    </thead>
    <tbody data-bind="foreach: items">
    <tr>
        <td>
            <div data-bind="if: (level && level.toUpperCase() === 'LEVEL_INVESTIGATION')">
                <b data-bind="text: investigation"></b>
            </div>
            <div data-bind="if: (level && level.toUpperCase() === 'LEVEL_SET')">
                <span data-bind="text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + set"></span>
            </div>
            <div data-bind="if: (level && level.toUpperCase() === 'LEVEL_TEST')">
                <span data-bind="text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + test"></span>
            </div>
        </td>
        <td data-bind="text: value"></td>
        <td data-bind="text: unit"></td>
        <td>
            <div data-bind="if: (lowNormal || hiNormal)">
                <span data-bind="text: 'Adult/Male:' + lowNormal} + '//' + hiNormal"></span>
            </div>
            <div data-bind="if: (lowCritical || lowCritical)">
                <span data-bind="text: 'Female:' + lowCritical + '//' + hiCritical"></span>
            </div>
            <div data-bind="if: (lowAbsolute || hiAbsolute)">
                <span data-bind="text: 'Child:' + lowAbsolute + '//' + hiAbsolute"></span>
            </div>
        </td>
    </tr>
    </tbody>
</table>

<script>
    var results = { 'items' : ko.observableArray([]) };
    var initialResults = [];
    <% currentResults.each { item -> %>
    initialResults.push(${item});
    <% } %>

    jq(function(){
        ko.applyBindings(results, jq("#patient-report")[0]);

        jq.each(initialResults, function(index, initialResult) {
            results.items.push(initialResult);
        });
    });
</script>
