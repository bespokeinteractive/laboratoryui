<% 
	ui.decorateWith("appui", "standardEmrPage", [title: "Laboratory Dashboard"])
	ui.includeCss("registration", "onepcssgrid.css")
%>

<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.11.0/moment.js"></script>
<script>
	jq(function(){
		jq(".lab-tabs").tabs();
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
	#referred-date label{
		display: none;
	}
	form input{
		width: 92%;
	}
	form select{
		width: 100%;
	}
	.add-on {
		float: right;
		left: auto;
		margin-left: -31px;
		margin-top: 8px;
		position: absolute;
	}
	.toast-item {
		background: #333 none repeat scroll 0 0;
	}
	
	#test-queue, #worklist, #results {
		margin-top: 10px;
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
					<li><a href="#reports">Reports</a></li>
					<li><a href="#status">Functional Status</a></li>
					<li><a href="#tests">Confidential Test Orders</a></li>
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
				
				<div id="reports">
					${ ui.includeFragment("laboratoryapp", "patientReports") }
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






