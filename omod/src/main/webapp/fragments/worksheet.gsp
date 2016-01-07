<table id="worksheet">
	<thead>
		<th>Order Date</th>
		<th>Patient Identifier</th>
		<th>Name</th>
		<th>Age</th>
		<th>Gender</th>
		<th>Sample Id</th>
		<th>Lab</th>
		<th>Test</th>
		<th>Result</th>
	</thead>
	<tbody>
		<tr>
			<td data-bind="text: startDate"></td>
			<td data-bind="text: patientIdentifier"></td>
			<td data-bind="text: patientName"></td>
			<td data-bind="text: gender"></td>
			<td data-bind="text: sampleId"></td>
			<td data-bind="text: investigation"></td>
			<td data-bind="text: test.name"></td>
			<td data-bind="text: value"></td>
		</tr>
	</tbody>
</table>