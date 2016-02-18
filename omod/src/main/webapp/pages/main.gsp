<% 
	ui.decorateWith("appui", "standardEmrPage", [title: "Laboratory Dashboard"])
%>

<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.11.0/moment.js"></script>
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
				
			</div>
		</div>
	</div>





</body>





<script>
jq(function(){
	jq(".lab-tabs").tabs();
})
</script>
