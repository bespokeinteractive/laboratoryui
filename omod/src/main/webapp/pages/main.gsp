 <% 
	ui.decorateWith("appui", "standardEmrPage", [title: "Laboratory Dashboard"])
	ui.includeCss("registration", "onepcssgrid.css")
	
	ui.includeJavascript("uicommons", "moment.js")
	ui.includeJavascript("laboratoryapp", "jQuery.print.js")
	ui.includeJavascript("laboratoryapp", "jq.browser.select.js")
%>

<script>
	var editResultsDate;
	
	jq(function(){
		jq(".lab-tabs").tabs();
		getQueuePatients(false);
		getResults(false);
		getWorklists(false);
		
		jq("#refresh").on("click", function(){
			if (jq('#queue').is(':visible')){
				getQueuePatients();
			}
			else if(jq('#worklist').is(':visible')){
				getWorklists();
			}
			else if(jq('#results').is(':visible')){
				getResults();
			}
			else {
				jq().toastmessage('showErrorToast', "Tab Content not Available");
			}
		});
		
		jq("#inline-tabs li").click(function() {
			if (jq(this).attr("aria-controls") == "queue"){
				jq('#refresh a').html('<i class="icon-refresh"></i> Get Patients');
				getQueuePatients(false);
			}
			else if (jq(this).attr("aria-controls") == "worklist"){
				jq('#refresh a').html('<i class="icon-refresh"></i> Get Worklist');
				getWorklists(false);
			}
			else if (jq(this).attr("aria-controls") == "results"){
				jq('#refresh a').html('<i class="icon-refresh"></i> Get Results');
				getResults(false);
			}
			else if (jq(this).attr("aria-controls") == "status"){
				jq('#refresh a').html('<i class="icon-refresh"></i> Get Functional Status');
			}
			else if (jq(this).attr("aria-controls") == "tests"){
				jq('#refresh a').html('<i class="icon-refresh"></i> Get Test Orders');
			}
        });
		
		function getQueuePatients(showToast) {
			if (typeof showToast === 'undefined') {
				showToast=true;
			}
			
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
				if (data.length === 0 && showToast) {
					jq().toastmessage('showErrorToast', "No Records found!");
				}
				queueData.tests.removeAll();
				jq.each(data, function(index, testInfo){
					queueData.tests.push(testInfo);
				});
			});
		}
		
		function getWorklists(showToast) {
			if (typeof showToast === 'undefined') {
				showToast=true;
			}
			
			var date = moment(jq('#accepted-date-field').val()).format('DD/MM/YYYY');
			var searchWorklistFor = jq("#search-worklist-for").val();
			var investigation = jq("#investigation-worklist").val();
			
			jq.getJSON('${ui.actionLink("laboratoryapp", "worklist", "searchWorkList")}',
				{ 
					"date" : date,
					"phrase" : searchWorklistFor,
					"investigation" : investigation
				}
			).success(function(data) {
				if (data.length === 0 && showToast) {
					jq().toastmessage('showErrorToast', "No Records found!");
				}
				workList.items.removeAll();
				jq.each(data, function(index, testInfo){
					workList.items.push(testInfo);
				});
			});
		}
		
		function getResults(showToast){
			if (typeof showToast === 'undefined'){
				showToast=true;
			}
			
			var date = moment(jq('#accepted-date-edit-field').val()).format('DD/MM/YYYY');
            var searchResultsFor = jq("#search-results-for").val();
            var investigation = jq("#investigation-results").val();

            jq.getJSON('${ui.actionLink("laboratoryapp", "editResults", "searchForResults")}',
				{
					"date" : date,
					"phrase" : searchResultsFor,
					"investigation" : investigation
				}
            ).success(function(data) {
				if (data.length === 0 && showToast) {
					jq().toastmessage('showErrorToast', "No Records found!");
				}
				result.items.removeAll();
				jq.each(data, function(index, testInfo){
					result.items.push(testInfo);
				});
			});
		}
		
		jq('#referred-date').on("change", function (dateText) {
			getQueuePatients();
        });
		
		jq('#accepted-date').on("change", function (dateText) {
			getWorklists();
        });
		
		jq('#accepted-date-edit').on("change", function (dateText) {
			editResultsDate = moment(jq('#accepted-date-edit-field').val()).format('DD/MM/YYYY');
			getResults();
        });
		
		jq('#investigation').bind('change keyup', function() {
			getQueuePatients();
		});
		
		jq('#investigation-worklist').bind('change keyup', function() {
			getWorklists();
		});
		
		jq('#investigation-results').bind('change keyup', function() {
			getResults();
		});
		
		jq('input').keydown(function (e) {
			var key = e.keyCode || e.which;
			if (key == 9 || key == 13) {
				if (jq(this).attr('id') == 'search-queue-for'){
					getQueuePatients();
				}
				else if (jq(this).attr('id') == 'search-worklist-for'){
					getWorklists();
				}
				else if (jq(this).attr('id') == 'search-results-for'){
					getResults();
				}
			}
		});
	});
	
	
</script>
<style>
	.new-patient-header .identifiers {
		margin-top: 5px;
	}
	.name {
		color: #f26522;
	}
	#inline-tabs{
		background: #f9f9f9 none repeat scroll 0 0;
	}
	#breadcrumbs a, #breadcrumbs a:link, #breadcrumbs a:visited {
		text-decoration: none;
	}
	form fieldset, .form fieldset {
		padding: 10px;
		width: 97.4%;
	}
	#referred-date label,
	#accepted-date label,
	#accepted-date-edit label{
		display: none;
	}
	form input[type="text"],
	form input[type="number"]{
		width: 92%;
	}
	form select{
		width: 100%;
	}
	form input:focus, form select:focus{
		outline: 2px none #007fff;
		border: 1px solid #777;
	}
	.add-on {
		color: #f26522;
		float: right;
		left: auto;
		margin-left: -31px;
		margin-top: 8px;
		position: absolute;
	}
	.webkit .add-on {
	  color:#F26522;
	  float:right;
	  left:auto;
	  margin-left:-31px;
	  margin-top:-27px!important;
	  position:relative!important;
	}
	.toast-item {
		background: #333 none repeat scroll 0 0;
	}
	
	#queue table, #worklist table, #results table{
		font-size: 14px;
		margin-top: 10px;
	}
	#refresh{
		border: 1px none #88af28;
		color: #fff !important;
		float: right;
		margin-right: -10px;
		margin-top: 5px;
	}
	#refresh a i{
		font-size: 12px;
	}
	form label, .form label {
		color: #028b7d;
	}
	.col5 {
		width: 65%;
	}
	.col5 button{
		float: right;
		margin-left: 3px;
		margin-right: 0;
		min-width: 180px;
	}
	form input[type="checkbox"] {
		margin: 5px 8px 8px;
	}
	.toast-item-image {
		top: 25px;
	}
	.ui-widget-content a {
		color: #007fff;
	}
	.accepted{
		color: #f26522;
	}
	#modal-overlay {
		background: #000 none repeat scroll 0 0;
		opacity: 0.4 !important;
	}
	.dialog-data{
		display: inline-block;
		width: 120px;
		color: #028b7d;
	}
	.inline{
		display: inline-block;
	}
	#reschedule-date label,
	#reorder-date label{
		display: none;
	}
	#reschedule-date-display,
	#reorder-date-display{
		min-width: 1px;
		width: 235px;
	}
	.dialog{
		display: none;
	}
	.dialog select {
		display: inline;
		width: 255px;
	}
	.dialog select option {
		font-size: 		1em;
		padding-left: 	10px;
	}
	#modal-overlay {
		background: #000 none repeat scroll 0 0;
		opacity: 0.4 !important;
	}
</style>
<header>
</header>
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
					<a>Laboratory</a>
				</li>
				
				<li>
				</li>
			</ul>
		</div>
		
		<div class="patient-header new-patient-header">
			<div class="demographics">
				<h1 class="name" style="border-bottom: 1px solid #ddd;">
					<span>LABORATORY DASHBOARD &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</span>
				</h1>
			</div>

			<div class="identifiers">
				<em>Current Time:</em>
				<span>${date}</span>
			</div>
			
			<div class="lab-tabs" style="margin-top: 40px!important;">
				<ul id="inline-tabs">
					<li><a href="#queue">Queue</a></li>
					<li><a href="#worklist">Worklist</a></li>
					<li><a href="#results">Results</a></li>
					<li><a href="#status">Functional Status</a></li>
					<li><a href="#tests">Test Orders</a></li>
					
					<li id="refresh" class="ui-state-default">
						<a style="color:#fff" class="button confirm">
							<i class="icon-refresh"></i>
							Get Patients
						</a>
					</li>
				</ul>
				
				<div id="queue">
					${ ui.includeFragment("laboratoryapp", "queue") }
				</div>
				
				<div id="worklist">
					${ ui.includeFragment("laboratoryapp", "worklist") }
				</div>

				<div id="results">
					${ ui.includeFragment("laboratoryapp", "editResults") }
				</div>
				
				<div id="status">
					${ ui.includeFragment("laboratoryapp", "functionalStatus") }
				</div>
				
				<div id="tests">
					${ ui.includeFragment("laboratoryapp", "testOrders") }
				</div>
			</div>
		</div>
	</div>
</body>






