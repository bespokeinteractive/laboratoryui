<% 
	ui.decorateWith("appui", "standardEmrPage")
%>

<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.11.0/moment.js"></script>

<div class="lab-tabs">
	<ul>
	    <li><a href="#queue">Queue</a></li>
		<li><a href="#worklist">Worklist</a></li>
	</ul>
	
	<div id="queue">
	    ${ ui.includeFragment("laboratoryapp", "queue") }
	</div>
	
	<div id="worklist">
		${ ui.includeFragment("laboratoryapp", "worklist") }
	</div>
	
</div>

<script>
jq(function(){
	jq(".lab-tabs").tabs();
})
</script>
