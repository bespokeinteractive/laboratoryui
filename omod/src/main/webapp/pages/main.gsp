<% 
	ui.decorateWith("appui", "standardEmrPage")
%>

<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.11.0/moment.js"></script>

<div class="lab-tabs">
	<ul>
		<li><a href="#worklist">Worklist</a></li>
		<li><a href="#patient-report">Patient Report</a></li>
	</ul>
	
	<div id="worklist">
		${ ui.includeFragment("laboratoryui", "worklist") }
	</div>
	
	<div id="patient-report">
		${ ui.includeFragment("laboratoryui", "patientReport", [patientId: 33359]) }
	</div>
</div>

<script>
jq(function(){
	jq(".lab-tabs").tabs();
})
</script>
