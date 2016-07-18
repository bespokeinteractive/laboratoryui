<%
    ui.includeCss("uicommons", "datatables/dataTables_jui.css")
    ui.includeJavascript("patientqueueapp", "jquery.dataTables.min.js")
%>
<script type="text/javascript">
    var dataTable;
    var billableServices;
    var serviceIds = [];
    jQuery(document).ready(function() {
        jq('#functionalStatus').on('change', 'input.service-status', function() {
            var index = jq.inArray(jq(this).val(), serviceIds);
            if (index > -1) {
                serviceIds.splice(index, 1);
            } else {
                serviceIds.push(jq(this).val());
            }
        });
		
		jq('#filter-status').on('keyup',function(){
			var searchPhrase = jq(this).val();
            dataTable.search(searchPhrase).draw();
		});

        dataTable=jQuery('#functionalStatus').DataTable({
            searching: true,
            lengthChange: false,
            pageLength: 15,
            jQueryUI: true,
            pagingType: 'full_numbers',
            sort: false,
            dom: 't<"fg-toolbar ui-toolbar ui-corner-bl ui-corner-br ui-helper-clearfix datatables-info-and-pg"ip>',
            language: {
                zeroRecords: 'No Services Found',
                paginate: {
                    first: 'First',
                    previous: 'Previous',
                    next: 'Next',
                    last: 'Last'
                }
            }
        });
		
		dataTable.on( 'order.dt search.dt', function () {
			dataTable.column(0, {search:'applied', order:'applied'}).nodes().each( function (cell, i) {
				cell.innerHTML = i+1;
			} );
		} ).draw();

        getBillableServices();

        jQuery('#functionalStatus tbody').on("click", function(){
            jq('#submitSave').on("click", function(){

                jq.post('${ui.actionLink('laboratoryapp','functionalStatus','updateBillableServices')}',
                        { "serviceIds" : serviceIds.toString() },
                        function (data) {
                            if (data.status === "fail") {
                                jq().toastmessage('showErrorToast', data.error);
                            } else {
                                jq().toastmessage('showSuccessToast', "saved");

                            }
                        },
                        'json'
                );
            });
        });


    });

    function getBillableServices() {
        jQuery.ajax({
            type: "GET",
            url: "${ui.actionLink('laboratoryapp','functionalStatus','getBillableServices')}",
            dataType: "json",
            success: function (data) {
                billableServices = data

               var dataRows = [];

                _.each(billableServices, function(billableService) {
                    var isChecked = (billableService.disable === true) ?"checked=checked":"";
                    dataRows.push([0, billableService.name, '<input type="checkbox" class="service-status" '+ isChecked + '" value="'+ billableService.serviceId +'">'])
                });

                dataTable.rows.add(dataRows);
                dataTable.draw();
            },
            error: function (xhr, ajaxOptions, thrownError) {
                alert(xhr);
                jQuery("#ajaxLoader").hide();
            }
        });
    }

</script>

<style>	
	.paging_full_numbers .fg-button {
		margin: 1px;
	}
	.paging_full_numbers {
		width: 62% !important;
	}	
	.dataTables_info {
		float: left;
		width: 35%;
	}
</style>


<fieldset style="margin: 0 0 5px">		
	<form style="padding-left: 10px;">
		<label for="filter-status">Filter Functional Status</label>			
		<input type="text" id="filter-status" placeholder="Filter Status" style="width: 94.6%; padding-left: 30px;"/>
		<i class="icon-search small" style="color: rgb(242, 101, 34); float: right; position: relative; margin-top: -32px; margin-right: 96.7%;"></i>
	</form>
</fieldset>


<table id='functionalStatus' style="width: 100%;">
    <thead>
    <tr>
        <th style="width: 10px!important;">#</th>
        <th>STATUS</th>
        <th>DISABLED</th>
    </tr>
    </thead>
    <tbody>
    </tbody>
</table>

    <input type='hidden' id='serviceIds' name='serviceIds' value=''/>
    <input type='submit' id='submitSave' value='Save'/>
