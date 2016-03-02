<%
    ui.decorateWith("appui", "standardEmrPage")
%>

<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.11.0/moment.js"></script>
<script>
    var dateFormat = require('dateformat');
    var now = new Date();
    dateFormat(now, "dddd, mmmm dS, yyyy");
</script>

<script>
    function strReplace(word) {
        var res = word.replace("[", "");
        res=res.replace("]","");
        return res;
    }

    jQuery(document).ready(function () {
        jq(".dashboard-tabs").tabs();

        jq('#surname').html(strReplace('${patient.names.familyName}')+',<em>surname</em>');
        jq('#othname').html(strReplace('${patient.names.givenName}')+' &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <em>other names</em>');
        jq('#agename').html('${patient.age} years ('+ moment('${patient.birthdate}').format('DD,MMM YYYY') +')');
    });
</script>

    <div class="patient-header new-patient-header">
        <div class="demographics">
    <h1>
    <span id="surname">${patient.names.familyName},<em>surname</em></span>
    <span id="othname">${patient.names.givenName} &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;<em>other names</em></span>

<span class="gender-age">
    <span>
        <% if (patient.gender == "F") { %>
        Female
        <% } else { %>
        Male
        <% } %>
    </span>
    <span id="agename">${patient.age} years (15.Oct.1996) </span>

</span>
    </h1>
            </div>
    <div class="identifiers">
        <em>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;Patient ID</em>
        <span>${patient.getPatientIdentifier()}</span>
        <br>

    </div>
    <div/>

<table id="patient-report">
    <thead>
    <tr>
        <th>Test</th>
        <th>Result</th>
        <th>Units</th>
        <th>Reference Range</th>
        <th>Date Ordered</th>
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
        <td>
            ${test}
        </td>

    </tr>
    </tbody>
</table>

<script>
    var results = { 'items' : ko.observableArray([]) };
    var initialResults = [];
    <% currentResults.data.each { item -> %>
    initialResults.push(${item.toJson()});
    <% } %>

    jq(function(){
        ko.applyBindings(results, jq("#patient-report")[0]);

        jq.each(initialResults, function(index, initialResult) {
            results.items.push(initialResult);
        });
    });
</script>
