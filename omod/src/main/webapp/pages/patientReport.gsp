<%
    ui.decorateWith("appui", "standardEmrPage", [title: "Laboratory Reports"])
	ui.includeJavascript("billingui", "moment.js")
%>

<script>
	var results = { 'items' : ko.observableArray([]) };
    var initialResults = [];
	
	<% currentResults.data.each { item -> %>
    initialResults.push(${item.toJson()});
    <% } %>

    jq(document).ready(function () {
        jq(".dashboard-tabs").tabs();

        jq('#surname').html(stringReplace('${patient.names.familyName}')+',<em>surname</em>');
        jq('#othname').html(stringReplace('${patient.names.givenName}')+' &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <em>other names</em>');
        jq('#agename').html('${patient.age} years ('+ moment('${patient.birthdate}').format('DD,MMM YYYY') +')');
		jq('.tad').text('Last Visit: '+ moment('${previousVisit}').format('DD.MM.YYYY hh:mm')+' HRS');
		
		ko.applyBindings(results, jq("#patient-report")[0]);

        jq.each(initialResults, function(index, initialResult) {
            results.items.push(initialResult);
        });
    });
</script>

<style>
	.new-patient-header .demographics .gender-age {
		font-size: 14px;
		margin-left: -55px;
		margin-top: 12px;
	}
	.new-patient-header .demographics .gender-age span {
		border-bottom: 1px none #ddd;
	}
	.new-patient-header .identifiers {
		margin-top: 5px;
	}
	#breadcrumbs a, #breadcrumbs a:link, #breadcrumbs a:visited {
		text-decoration: none;
	}
	#breadcrumbs a:hover{
		text-decoration: underline;
	}
	.new-patient-header .demographics .gender-age {
		font-size: 14px;
		margin-left: -55px;
		margin-top: 12px;
	}
	.new-patient-header .demographics .gender-age span {
		border-bottom: 1px none #ddd;
	}
	.new-patient-header .identifiers {
		margin-top: 5px;
	}
	.tag {
		padding: 2px 10px;
	}
	.tad {
		background: #666 none repeat scroll 0 0;
		border-radius: 1px;
		color: white;
		display: inline;
		font-size: 0.8em;
		margin-left: 4px;
		padding: 2px 10px;
	}
	.status-container {
		padding: 5px 10px 5px 5px;
	}
	.catg{
		color: #363463;
		margin: 35px 10px 0 0;
	}
</style>

<body>
	<div class="clear"></div>
	<div class="container">
		<div class="example">
			<ul id="breadcrumbs">
				<li>
					<a href="${ui.pageLink('referenceapplication','home')}">
						<i class="icon-home small"></i></a>
				</li>
				
				<li>
					<i class="icon-chevron-right link"></i>
					<a href="${ui.pageLink('laboratoryapp','main')}#results">Laboratory</a>
				</li>
				
				<li>
					<i class="icon-chevron-right link"></i>
					Patient Reports
				</li>
			</ul>
		</div>
		
		<div class="patient-header new-patient-header">
			<div class="demographics">
				<h1 class="name">
					<span id="surname"></span>
					<span id="othname"></span>
					
					<span class="gender-age">
						<span>
							<% if (patient.gender == "F") { %>
								Female
							<% } else { %>
								Male
							<% } %>
						</span>
						<span id="agename"></span>
						
					</span>
				</h1>
				
				<br/>
				<div id="stacont" class="status-container">
					<span class="status active"></span>
					Visit Status
				</div>
				<div class="tag">Outpatient ${fileNumber}</div>
				<div class="tad">Last Visit</div>
			</div>

			<div class="identifiers">
				<em>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;Patient ID</em>
				<span>${patient.getPatientIdentifier()}</span>
				<br>
				
				<div class="catg">
					<i class="icon-tags small" style="font-size: 16px"></i><small>Category:</small> ${category} 
				</div>
			</div>
			<div class="close"></div>
		</div>
	</div>



	<table id="patient-report" style="margin-top: 5px">
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
			<tr data-bind="if: (level && level.toUpperCase() === 'LEVEL_INVESTIGATION')">
				<td colspan="5"><b data-bind="text: investigation"></b></td>
			</tr>

			<tr data-bind="if: (level && level.toUpperCase() === 'LEVEL_SET')">
				<td colspan="5"><b data-bind="text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + set"></b></td>
			</tr>
			
			<tr data-bind="if: (level && level.toUpperCase() === 'LEVEL_TEST')">
				<td data-bind="text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + test"></td>
				<td data-bind="text: value"></td>
				<td data-bind="text: unit"></td>
				<td>
					<div data-bind="if: (lowNormal || hiNormal)">
						<span data-bind="text: 'Adult/Male:' + lowNormal + '//' + hiNormal"></span>
					</div>
					<div data-bind="if: (lowCritical || lowCritical)">
						<span data-bind="text: 'Female:' + lowCritical + '//' + hiCritical"></span>
					</div>
					<div data-bind="if: (lowAbsolute || hiAbsolute)">
						<span data-bind="text: 'Child:' + lowAbsolute + '//' + hiAbsolute"></span>
					</div>
				</td>
				<td>
					<div data-bind="if: (level && level.toUpperCase() === 'LEVEL_TEST')">
						${test}
					</div>
				</td>
			</tr>
		</tbody>
	</table>
</body>