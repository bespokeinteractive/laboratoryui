<%
    ui.includeCss("uicommons", "datatables/dataTables_jui.css")
    ui.includeJavascript("patientqueueui", "jquery.dataTables.min.js")
%>
<script type="text/javascript">
    var dataTable;
    var billableServices;
    jQuery(document).ready(function() {
        dataTable=jQuery('#functionalStatus').DataTable({
            searching: false,
            lengthChange: false,
            pageLength: 15,
            jQueryUI: true,
            pagingType: 'full_numbers',
            sort: false,
            dom: 't<"fg-toolbar ui-toolbar ui-corner-bl ui-corner-br ui-helper-clearfix datatables-info-and-pg"ip>',
            language: {
                zeroRecords: 'No Investigations ordered.',
                paginate: {
                    first: 'First',
                    previous: 'Previous',
                    next: 'Next',
                    last: 'Last'
                }
            }
        });

        getBillableServices();

        jQuery('#functionalStatus tbody').on("click", function(){

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
                    var isChecked = billableService.disable?"checked=checked":"";
                    dataRows.push([billableService.name, '<input type="checkbox" "'+ isChecked + '">'])
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

<table id='functionalStatus'>
    <thead>
    <tr>
        <th>Test</th>
        <th>Disabled</th>
    </tr>
    </thead>
    <tbody>
    </tbody>
</table>
<form method="POST">
    <input type='hidden' id='serviceIds' name='serviceIds' value=''/>
    <input type='submit' value='Save'/>
</form>