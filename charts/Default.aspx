<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="charts._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- First: Bootstrap Modal for charts (unchanged) -->
    <div class="modal fade" id="chartsModal" tabindex="-1" aria-labelledby="chartsModalLabel" aria-hidden="true">
      <div class="modal-dialog modal-dialog-scrollable modal-xl">
        <div class="modal-content">
          <!-- رأس النافذة -->
          <div class="modal-header text-white" style="background-color: #880b4d;">
            <h5 class="modal-title" id="chartsModalLabel">لوحة الرسوم البيانية القانونية</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
          </div>

          <!-- جسم النافذة -->
          <div class="modal-body">
            <!-- أزرار التصدير -->
            <div class="filter-item filter-action mb-3 d-flex justify-content-end">
              <button type="button" class="btn-export" onclick="exportToExcel()">تصدير إلى Excel</button>
              <button type="button" class="btn-export ms-2" onclick="exportToPDF()">تصدير إلى PDF</button>
            </div>

            <!-- الفلاتر -->
            <div class="filters mb-4 mx-auto">
              <div class="filters-inner d-flex gap-3">

                <!-- سنة -->
                <div class="filter-item width" id="filterYear">
                  <label for="<%=ddlYear.ClientID%>">السنة</label>
                  <asp:DropDownList ID="ddlYear" runat="server" CssClass="searchable" />
                </div>

                <!-- التصنيف -->
                <div class="filter-item width" id="filterCategories">
                  <label for="<%=ddlCategories.ClientID%>">التصنيف</label>
                  <asp:DropDownList ID="ddlCategories" runat="server" CssClass="searchable" />
                </div>

                <!-- نوع الملف -->
                <div class="filter-item width" id="filterFileType">
                  <label for="<%=ddlfileType.ClientID%>">نوع الملف</label>
                  <asp:DropDownList ID="ddlfileType" runat="server" CssClass="searchable" />
                </div>

                <!-- الدول -->
                <div class="filter-item width" id="filterCountries">
                  <label for="<%= ddlCountries.ClientID %>">الدولة</label>
                  <asp:ListBox ID="ddlCountries" runat="server" CssClass="custom-listbox" SelectionMode="Multiple" />
                  <small class="form-text text-white mt-1" style="font-size:10px">
                    يمكنك اختيار <strong>أكثر من دولة</strong> بالضغط على زر <kbd>Ctrl</kbd> (لـ Windows) أو <kbd>Cmd</kbd> (لـ Mac) أثناء التحديد.
                  </small>
                </div>

              </div>

              <!-- تجميع حسب + تطبيق / إعادة ضبط -->
              <div class="last-filter d-flex flex-wrap justify-content-between mt-3">
                <div class="filter-item">
                  <label for="<%=ddlGroupBy.ClientID%>">تجميع حسب:</label>
                  <asp:DropDownList ID="ddlGroupBy" runat="server" AutoPostBack="false">
                    <asp:ListItem Text="--الكل--" Value="" />
                    <asp:ListItem Text="التصنيف" Value="Category" />
                    <asp:ListItem Text="نوع الملف" Value="FileType" />
                    <asp:ListItem Text="الدولة" Value="Country" />
                    <asp:ListItem Text="السنة" Value="Year" />
                  </asp:DropDownList>
                </div>

                <div class="filter-item filter-action d-flex">
                  <asp:Button ID="btnFilter" runat="server" Text="تطبيق الفلاتر" CssClass="btn-apply" OnClientClick="loadAllCharts(); return false;" />
                  <asp:Button ID="btnResetFilters" runat="server" Text="إعادة ضبط" CssClass="btn-reset ms-2" OnClientClick="resetFilters(); return false;" />
                </div>
              </div>
            </div>

            <!-- قائمة أنواع الرسوم -->
            <div id="chartMenuWrapper" class="mb-4">
              <button id="toggleChartMenu" type="button" class="btn btn-primary btn-sm">☰ أنواع الرسوم</button>
              <div id="chartMenu" class="mt-2 p-3 bg-light border rounded shadow-sm">
                <ul class="list-unstyled mb-0">
                  <li><a href="#" class="chart-menu-item" data-type="donut">رسم دائري</a></li>
                  <li><a href="#" class="chart-menu-item" data-type="bar">رسم عمودي</a></li>
                </ul>
              </div>
            </div>

            <!-- رسالة عدم وجود تحديد -->
            <div id="noSelectionMessage" class="text-center py-5" style="display: none;">
              <h5>يرجى اختيار فلتر واحد على الأقل لعرض الرسم البياني.</h5>
            </div>

            <!-- الرسوم البيانية -->
            <div class="chart-section-container bg-white rounded shadow-sm p-4 mx-auto">

              <!-- رسم دائري -->
              <div id="sectionCountry" class="chart-section position-relative mb-4 text-center">
                <canvas id="ctxDonut" width="900" height="600"></canvas>
                <div id="spinnerDonut"
                  style="display: none; position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%); background: rgba(255,255,255,0.8); padding: 0.5rem 1rem; border-radius: 4px; font-weight: bold;">
                  جاري التحميل…
                </div>
              </div>

              <!-- رسم بياني خطي -->
              <div id="sectionYear" class="chart-section position-relative mb-4 text-center" style="display: none;">
                <canvas id="ctxLine" width="900" height="600"></canvas>
                <div id="spinnerDonut"
                  style="display: none; position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%); background: rgba(255,255,255,0.8); padding: 0.5rem 1rem; border-radius: 4px; font-weight: bold;">
                  جاري التحميل…
                </div>
                <asp:GridView ID="gvLineData" runat="server" CssClass="table table-striped mt-3">
                  <Columns>
                    <asp:BoundField DataField="Label" HeaderText="السنة" />
                    <asp:BoundField DataField="Value" HeaderText="العدد" />
                  </Columns>
                </asp:GridView>
              </div>

              <!-- جدول البيانات -->
              <div class="info-table">
                <table id="tblDonutData" class="display table table-bordered" style="width: 100%; margin-top: 1rem;">
                  <thead class="table-light">
                    <tr>
                      <th>نوع القانون</th>
                      <th>العدد</th>
                      <th>السنة</th>
                      <th style="display: none;">FileUrl</th>  <!-- hidden column -->
                    </tr>
                  </thead>
                  <tbody>
                    <!-- يتم تعبئة الصفوف من خلال loadAllCharts() -->
                  </tbody>
                </table>
              </div>

            </div>
            <!-- End Chart Sections Container -->

            <!-- Hidden Fields (for GridView data serialization) -->
            <asp:HiddenField ID="gvDonutData_Data" runat="server" />
            <asp:HiddenField ID="gvLineData_Data" runat="server" />

          </div>
          <!-- End Modal Body -->

          <!-- Modal Footer -->
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
          </div>

        </div>
      </div>
    </div>
    <!-- End Bootstrap Modal -->

    <!-- New: Bootstrap Modal to show the file in an iframe -->
    <div class="modal fade" id="fileModal" tabindex="-1" aria-labelledby="fileModalLabel" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered modal-xl modal-dialog-scrollable">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="fileModalLabel">عرض الملف</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
          </div>
          <div class="modal-body p-0">
            <iframe id="fileIframe" style="width:100%; height:80vh; border:none;"></iframe>
          </div>
        </div>
      </div>
    </div>
    <!-- End File Bootstrap Modal -->



    <!-- Modal that lists multiple files -->
<div class="modal fade" id="fileListModal" tabindex="-1" aria-labelledby="fileListModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-scrollable modal-md">
    <div class="modal-content">
      <div class="modal-header" style="background-color: #880b4d; color: white;">
        <h5 class="modal-title" id="fileListModalLabel">اختر الملف لفتحه</h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="إغلاق"></button>
      </div>
      <div class="modal-body">
        <ul id="fileListContainer" class="list-group">
          <!-- JavaScript will append <li> elements here -->
        </ul>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">إغلاق</button>
      </div>
    </div>
  </div>
</div>

 











 <script>
     let donutChart = null;
     let selectedChartType = 'bar';

     function loadAllCharts() {
         $('#spinnerDonut').hide();

         // 1) Read filter values
         const years = $('#<%=ddlYear.ClientID%>').val();
        const categories = $('#<%=ddlCategories.ClientID%>').val();
        const fileType = $('#<%=ddlfileType.ClientID%>').val();
        const groupBy = $('#<%=ddlGroupBy.ClientID%>').val();
        const countries = $('#<%=ddlCountries.ClientID%> option:selected').map((_, o) => o.value).get();

         function hasSelection(v) {
             if (!v) return false;
             if (Array.isArray(v)) return v.length > 0;
             if (typeof v === 'string') return v.trim().length > 0;
             return true;
         }

         // If absolutely no filter is selected, clear charts & table and show "no selection" message
         if (![years, categories, fileType, groupBy, countries].some(hasSelection)) {
             if (donutChart) { donutChart.destroy(); donutChart = null; }
             $('#sectionCountry').hide();
             $('#tblDonutData').hide();
             $('#noSelectionMessage').show();
             return;
         }
         $('#noSelectionMessage').hide();

         // 2) Build filters object
         const filters = {
             year: years,
             category: categories,
             fileType,
             groupBy,
             country: countries,
             type: groupBy ? 'grouped' : 'donut'
         };

         // Pick chart type strictly from selectedChartType (bar or donut)
         let clientType = selectedChartType; // never 'line' here

         // 3) AJAX call
         $.ajax({
             url: 'ChartDataHandler.ashx',
             data: filters,
             dataType: 'json',
             traditional: true
         }).done(ds => {
             console.log("Server returned:", ds);

             // Destroy existing DataTable, if any
             if ($.fn.dataTable.isDataTable('#tblDonutData')) {
                 $('#tblDonutData').DataTable().clear().destroy();
             }

             // If no data returned, show empty table
             if (!ds.length) {
                 alert('لا توجد بيانات');
                 if (donutChart) { donutChart.destroy(); donutChart = null; }
                 $('#sectionCountry').hide();

                 // Build empty DataTable with consistent columns (Label/Value/Year/FileUrls)
                 $('#tblDonutData').show().DataTable({
                     data: [],
                     columns: [
                         { title: 'نوع القانون', data: 'Label' },
                         { title: 'العدد', data: 'Value' },
                         { title: 'السنة', data: 'Year' },
                         { title: 'FileUrls', data: 'FileUrls', visible: false }
                     ],
                     paging: false,
                     searching: false,
                     info: false,
                     ordering: false,
                     language: { emptyTable: 'لا توجد بيانات' }
                 });
                 return;
             }

             // 4) DONUT/BAR (grouped or ungrouped)
             $('#sectionCountry').show();
             $('#spinnerDonut').show();

             // Destroy prior chart instance if it exists
             if (donutChart) donutChart.destroy();

             // Chart: build labelsArray & dataArray
             let labelsArray, dataArray;
             if (groupBy === 'Year') {
                 // Aggregate ds by Year field across all returned rows
                 const byYear = {};
                 // Also collect FileUrls per year if needed in table
                 const fileUrlsByYear = {};
                 ds.forEach(r => {
                     const yr = r.Year;
                     byYear[yr] = (byYear[yr] || 0) + (Number(r.Value) || 0);

                     if (!fileUrlsByYear[yr]) fileUrlsByYear[yr] = new Set();
                     (r.FileUrls || []).forEach(url => fileUrlsByYear[yr].add(url));
                 });
                 // Sort years numerically ascending
                 const sortedYears = Object.keys(byYear).sort((a, b) => {
                     const na = Number(a), nb = Number(b);
                     return (!isNaN(na) && !isNaN(nb)) ? na - nb : a.localeCompare(b);
                 });
                 labelsArray = sortedYears; // ["2001","2002",...]
                 dataArray = sortedYears.map(y => byYear[y]);
                 // We'll reuse fileUrlsByYear below for DataTable
                 // Attach to a variable in this scope:
                 window._fileUrlsByYear = fileUrlsByYear;
             } else {
                 // Non-Year grouping: labels come directly from ds[].Label
                 labelsArray = ds.map(r => r.Label);
                 dataArray = ds.map(r => r.Value);
             }

             // Create bar or doughnut chart
             donutChart = new Chart(
                 document.getElementById('ctxDonut').getContext('2d'),
                 {
                     type: clientType === 'bar' ? 'bar' : 'doughnut',
                     data: {
                         labels: labelsArray,
                         datasets: [{
                             label: clientType === 'bar' ? 'Count' : '',
                             data: dataArray,
                             backgroundColor: labelsArray.map((_, i) => `hsl(${(i * 40) % 360},60%,60%)`)
                         }]
                     },
                     options: {
                         responsive: true,
                         scales: clientType === 'bar'
                             ? {
                                 x: {
                                     beginAtZero: true,
                                     title: {
                                         display: true,
                                         text: (groupBy === 'Year' ? 'السنة' : '')
                                     }
                                 },
                                 y: {
                                     beginAtZero: true,
                                     title: {
                                         display: true,
                                         text: 'Count'
                                     }
                                 }
                             }
                             : {},
                         plugins: {
                             legend: { display: clientType !== 'bar' }
                         }
                     }
                 }
             );

             // 5) Build DataTable data & columns:
             let tableData, columnsDef;

             if (groupBy === 'Year') {
                 // One row per year
                 const byYear = {};
                 const fileUrlsByYear = window._fileUrlsByYear || {};
                 // We already have byYear sums and fileUrlsByYear sets from above
                 // Convert to array of objects:
                 const sortedYears = Object.keys(byYear).length ? Object.keys(byYear) : Object.keys(fileUrlsByYear);
                 // But to recompute byYear reliably in case window._fileUrlsByYear empty:
                 // Re-aggregate from ds:
                 const tmpByYear = {};
                 const tmpFileUrls = {};
                 ds.forEach(r => {
                     const yr = r.Year;
                     tmpByYear[yr] = (tmpByYear[yr] || 0) + (Number(r.Value) || 0);
                     if (!tmpFileUrls[yr]) tmpFileUrls[yr] = new Set();
                     (r.FileUrls || []).forEach(url => tmpFileUrls[yr].add(url));
                 });
                 const sorted = Object.keys(tmpByYear).sort((a, b) => {
                     const na = Number(a), nb = Number(b);
                     return (!isNaN(na) && !isNaN(nb)) ? na - nb : a.localeCompare(b);
                 });
                 tableData = sorted.map(y => ({
                     Label: y,               // year
                     Value: tmpByYear[y],    // total count
                     Year: y,                // redundancy; can be used for click logic
                     FileUrls: Array.from(tmpFileUrls[y] || [])
                 }));
                 // Columns for Year grouping: show year as first column
                 columnsDef = [
                     {
                         title: 'السنة',
                         data: 'Label',
                         render: data => `<span style="text-decoration:underline;color:blue;cursor:pointer">${data}</span>`
                     },
                     { title: 'العدد', data: 'Value' },
                     // We can omit a separate 'Year' column since Label already is year.
                     { title: 'FileUrls', data: 'FileUrls', visible: false }
                 ];
             } else {
                 // Non-year grouping: show each ds row as-is
                 tableData = ds;
                 let firstColumnTitle = '';
                 switch (groupBy) {
                     case 'Country': firstColumnTitle = 'الدولة'; break;
                     case 'Category': firstColumnTitle = 'التصنيف'; break;
                     case 'FileType': firstColumnTitle = 'نوع الملف'; break;
                     default: firstColumnTitle = 'نوع القانون'; break;
                 }
                 columnsDef = [
                     {
                         title: firstColumnTitle,
                         data: 'Label',
                         render: (data, type, row) => {
                             const safeLabel = $('<div>').text(data).html();
                             const safeTooltip = $('<div>').text(row.Tooltip || '').html();
                             return `<span title="${safeTooltip}">${safeLabel}</span>`;
                         }
                     },
                     { title: 'العدد', data: 'Value' },
                     {
                         title: 'السنة',
                         data: 'Year',
                         render: data => `<span style="text-decoration:underline;color:blue;cursor:pointer">${data}</span>`
                     },
                     { title: 'FileUrls', data: 'FileUrls', visible: false }
                 ];
             }

             // Initialize DataTable
             $('#tblDonutData').show().DataTable({
                 data: tableData,
                 columns: columnsDef,
                 paging: true,
                 searching: true,
                 language: { emptyTable: 'لا توجد بيانات' }
             });

             // Row-click logic: open file(s)
             $('#tblDonutData tbody').off('click').on('click', 'tr', function () {
                 const tableDataApi = $('#tblDonutData').DataTable();
                 const row = tableDataApi.row(this).data();
                 if (!row || !row.FileUrls || row.FileUrls.length === 0) return;

                 if (row.FileUrls.length === 1) {
                     $('#fileIframe').attr('src', row.FileUrls[0]);
                     $('#fileModal').modal('show');
                 } else {
                     const container = $('#fileListContainer');
                     container.empty();
                     row.FileUrls.forEach(url => {
                         const fname = url.split('/').pop();
                         const li = $(`
                            <li class="list-group-item list-group-item-action" style="cursor:pointer;">
                                ${fname}
                            </li>
                        `);
                         li.on('click', () => {
                             $('#fileListModal').modal('hide');
                             $('#fileIframe').attr('src', url);
                             $('#fileModal').modal('show');
                         });
                         container.append(li);
                     });
                     $('#fileListModal').modal('show');
                 }
             });

             $('#spinnerDonut').hide();

         }).fail(() => {
             $('#spinnerDonut').hide();
             alert('فشل في تحميل البيانات');
         });
     }

     // Toggle between bar and donut via the “chart-menu” buttons
     $('.chart-menu-item').on('click', function (e) {
         e.preventDefault();
         selectedChartType = $(this).data('type'); // 'bar' or 'doughnut'
         $('#sectionCountry').show();
         loadAllCharts();
     });

     // Toggle the chart‐type menu visibility
     document.getElementById('toggleChartMenu').onclick = e => {
         e.preventDefault();
         document.getElementById('chartMenu').classList.toggle('d-none');
     };

     $(function () {
         $('.searchable').on('change', loadAllCharts);
         $('#<%=ddlCountries.ClientID%>').on('change', loadAllCharts);
        $('#<%=btnFilter.ClientID%>').on('click', e => { e.preventDefault(); loadAllCharts(); });
        loadAllCharts();
    });

     $(document).ready(function () {
         const ddlGroupBy = $('#<%=ddlGroupBy.ClientID%>');
        function updateFilterVisibility() {
            const val = ddlGroupBy.val();
            $('#filterYear, #filterCategories, #filterFileType, #filterCountries').show();
            if (val === 'Country') {
                $('#<%=ddlCountries.ClientID%>').val([]).trigger('change');
                $('#filterCountries').slideUp();
            } else if (val === 'Category') {
                $('#<%=ddlCategories.ClientID%>').val('').trigger('change');
                $('#filterCategories').slideUp();
            } else if (val === 'FileType') {
                $('#<%=ddlfileType.ClientID%>').val('').trigger('change');
                $('#filterFileType').slideUp();
            } else if (val === 'Year') {
                $('#<%=ddlYear.ClientID%>').val('').trigger('change');
                $('#filterYear').slideUp();
            }
        }
        updateFilterVisibility();
        ddlGroupBy.on('change', updateFilterVisibility);
    });

    function resetFilters() {
        $('#<%=ddlYear.ClientID%>').val('');
        $('#<%=ddlCategories.ClientID%>').val('');
        $('#<%=ddlfileType.ClientID%>').val('');
        $('#<%=ddlGroupBy.ClientID%>').val('');
        $('#<%=ddlCountries.ClientID%> option').prop('selected', false);
         $('.searchable').trigger('change');
         loadAllCharts();
     }

     function exportToExcel() {
         const table = document.getElementById('tblDonutData');
         if (!table) {
             alert('Table not found.');
             return;
         }
         const workbook = XLSX.utils.book_new();
         const worksheet = XLSX.utils.table_to_sheet(table, { raw: true });
         XLSX.utils.book_append_sheet(workbook, worksheet, 'Data');
         XLSX.writeFile(workbook, 'ChartData.xlsx');
     }

     async function exportToPDF() {
         const dt = $('#tblDonutData').DataTable();
         if (!dt) {
             alert('DataTable not initialized.');
             return;
         }
         const originalLength = dt.page.len();
         const originalPage = dt.page.info().page;
         try {
             dt.page.len(-1).draw(false);
             await new Promise(resolve => dt.one('draw', () => resolve()));
             const container = document.querySelector('.chart-section-container');
             if (!container) {
                 alert('Chart container not found.');
                 return;
             }
             const canvas = await html2canvas(container, { scale: 2 });
             const imgData = canvas.toDataURL('image/jpeg', 1.0);
             const { jsPDF } = window.jspdf;
             const pdf = new jsPDF({ orientation: 'landscape', unit: 'pt', format: 'a4' });
             const pageWidth = pdf.internal.pageSize.getWidth();
             const imgWidth = pageWidth - 40;
             const imgHeight = (canvas.height * imgWidth) / canvas.width;
             pdf.addImage(imgData, 'JPEG', 20, 20, imgWidth, imgHeight);
             pdf.save('ChartAndData.pdf');
         } catch (err) {
             console.error(err);
             alert('Error generating PDF.');
         } finally {
             dt.page.len(originalLength).page(originalPage).draw(false);
         }
     }
 </script>










 
<!-- Underline CSS; make sure this is loaded before the script runs -->
<style>
.underlined-year {
    text-decoration: underline;
    color: blue;
    cursor: pointer;
}
</style>


           <!-- Original CSS (unchanged) -->
            <style>
                :root {
                    --primary: #880b4d;
                    --light: #f9f9f9;
                    --light-bg: #f9f9f9;
                    --dark-text: #333;
                    --text: "white";
                }

                .underlined-year {
    text-decoration: underline;
    color: blue;
    cursor: pointer;
}


                .btn-close{
                    margin:0 !important;
                    color:white !important;
                }


                .filter-item.width {
                  flex: 1 !important; /* Responsive width that allows wrap */
                  min-width: 100px; /* Prevents being too small */
                  max-width: 80% !important;
                }

                .btn-reset {
                    background-color: #ccc;
                    border: 1px solid #999;
                    color: #333;
                    padding: 6px 12px;
                    cursor: pointer;
                }
                .btn-reset:hover {
                    background-color: #bbb;
                }

                .btn-export {
                    background-color: var(--primary);
                    color: white;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 4px;
                    cursor: pointer;
                    font-weight: 500;
                }
                .btn-export:hover {
                    background-color: #a21a6a;
                }

                .dataTables_wrapper label {
                    padding: 0 16px;
                }
                .sorting {
                    padding: 8px 16px !important;
                }
                tbody > tr > td {
                    padding: 8px 16px !important;
                }
                .paginate_button.current {
                    background-color: var(--primary) !important;
                    color: var(--text) !important;
                }
                .dataTables_info {
                    padding: 1rem;
                }
                div.dataTables_wrapper div.dataTables_paginate ul.pagination li a {
                    background-color: var(--primary);
                    color: white !important;
                    border: none;
                    border-radius: 4px;
                    margin: 0 2px;
                    padding: 6px 12px;
                    font-weight: 500;
                }
                div.dataTables_wrapper div.dataTables_paginate ul.pagination li.active a {
                    background-color: #a21a6a !important;
                    color: white !important;
                }
                div.dataTables_wrapper div.dataTables_paginate ul.pagination li a:hover {
                    background-color: #c2185b;
                }

                .last-filter {
                    width: 100%;
                    flex-direction: row;
                    display: flex;
                    gap: 16px;
                }

                .filters {
                    display: flex;
                    flex-direction: column;
                    gap: 1rem;
                    align-items: flex-start;
                    background: var(--primary);
                    padding: 1rem;
                    border-radius: 8px;
                    color: white;
                    margin-bottom: 1.5rem;
                    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
                    width: 100%;
                }
                .filters-inner {
                    flex-direction: row;
                    flex-wrap:wrap;
                    display: flex;
                    gap: 16px;
                 
                }

                .filter-item {
                    display: flex;
                    flex-direction: column;
                }
           

                .filter-item label,
                .filters label {
                    margin-bottom: 0.25rem;
                    font-weight: 600;
                    color: var(--text);
                    margin-right: 0.5rem;
                }
                .filter-item select,
                .filters select {
                    padding: 0.4rem 0.5rem;
                    border: 1px solid #ccc;
                    border-radius: 4px;
                    background: white;
                    font-size: 0.9rem;
                }

                .filters button {
                    padding: 0.5rem 0.75rem;
                    background: white;
                    color: var(--primary);
                    font-weight: 600;
                    border: none;
                    border-radius: 4px;
                    font-size: 0.9rem;
                    cursor: pointer;
                }
                .filters button:hover {
                    background: #f0f0f0;
                }

                .filter-action {
                    flex: 1;
                    align-self: flex-end;
                    display: flex;
                    flex-direction: row;
                    justify-content: space-between;
                    gap: 16px;
                }

                .btn-apply {
                    padding: 0.5rem 1rem;
                    background: var(--primary);
                    color: white;
                    border: none;
                    border-radius: 4px;
                    cursor: pointer;
                    font-weight: 600;
                }
                .btn-apply:hover {
                    background: #a21a6a;
                }

                #chartMenu {
                    transition: all 0.3s ease;
                }
                #chartMenu.d-none {
                    display: none;
                }
                #toggleChartMenu {
                    background-color: var(--primary);
                    color: white;
                    border: none;
                    padding: 6px 12px;
                    border-radius: 4px;
                }

                #chartMenu {
                    position: static;
                    width: 100%;
                    background: var(--light);
                    border: 1px solid #ddd;
                    padding: 1rem;
                    border-radius: 8px;
                    margin-top: 0.5rem;
                }
                #chartMenu ul {
                    list-style: none;
                    padding: 0;
                    margin: 0;
                }
                #chartMenu li + li {
                    margin-top: 0.75rem;
                }
                #chartMenu a {
                    display: block;
                    padding: 0.5rem 0.75rem;
                    color: var(--dark-text);
                    font-weight: 500;
                    border-radius: 4px;
                    text-decoration: none;
                    transition: background 0.2s, color 0.2s;
                    cursor: pointer;
                }
                #chartMenu a:hover,
                #chartMenu a.active {
                    background: var(--primary);
                    color: white;
                }

                .chart-section-container {
                    width: 100%;
                    background: white;
                    border-radius: 8px;
                    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
                    padding: 2rem;
                }
                .chart-section {
                    width: 100%;
                    margin-bottom: 2rem;
                }
                .chart-section h3 {
                    margin-top: 0;
                    color: var(--primary);
                }
                #spinnerDonut,
                #spinnerLine {
                    font-size: 1rem;
                    color: var(--primary);
                }

                .info-table table {
                    width: 100%;
                    margin-top: 1rem;
                }
            </style>
    <!-- Auto-open the modal on page load -->
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            var chartsModal = new bootstrap.Modal(document.getElementById('chartsModal'));
            chartsModal.show();
        });
    </script>

</asp:Content>










































































<%--<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <!DOCTYPE html>

    <div class="filter-item filter-action">
        <button type="button" class="btn-export" onclick="exportToExcel()">Export to Excel</button>
        <button type="button" class="btn-export" onclick="exportToPDF()">Export to PDF</button>
    </div>


    <!-- FILTERS -->
    <div class="filters">
        <div class="filters-inner">
            <div class="filter-item">
                <label for="<%=ddlYear.ClientID%>" id="filterYears">Year</label>
                <asp:DropDownList ID="ddlYear" runat="server" CssClass="searchable" />
            </div>
            <div class="filter-item" id="filterLawType">
                <label for="<%=ddlLawType.ClientID%>">Law Type</label>
                <asp:DropDownList ID="ddlLawType" runat="server" CssClass="searchable" />
            </div>

            <div class="filter-item" id="filterCategories">
                <label for="<%=ddlCategories.ClientID%>">Category</label>
                <asp:DropDownList ID="ddlCategories" runat="server" CssClass="searchable" />
            </div>
            <div class="filter-item" id="filterFileType">
                <label for="<%=ddlfileType.ClientID%>">File Type</label>
                <asp:DropDownList ID="ddlfileType" runat="server" CssClass="searchable" />
            </div>
            <div class="filter-item" id="filterCountries">
                <label for="<%=ddlCountries.ClientID%>">Country</label>
                <asp:ListBox ID="ddlCountries" runat="server" CssClass="searchable" SelectionMode="Multiple" />


            </div>

        </div>
        <div class=" last-filter ">

            <div class="filter-item">
                <label for="<%=ddlGroupBy.ClientID%>">Group by:</label>
                <asp:DropDownList ID="ddlGroupBy" runat="server" AutoPostBack="false">
                    <asp:ListItem Text="--All--" Value="" />
                    <asp:ListItem Text="Category" Value="Category" />
                    <asp:ListItem Text="File Type" Value="FileType" />
                    <asp:ListItem Text="Law Type" Value="LawTypeArabic" />
                    <asp:ListItem Text="Country" Value="Country" />

                </asp:DropDownList>
            </div>
            <div class="filter-item filter-action">
                <asp:Button ID="btnFilter" runat="server" Text="Apply Filter" CssClass="btn-apply" OnClientClick="loadAllCharts(); return false;" />
                <asp:Button ID="btnResetFilters" runat="server" Text="Reset Filters" CssClass="btn-reset" OnClientClick="resetFilters(); return false;" />

            </div>
        </div>
    </div>

    <div id="chartMenuWrapper">
        <button id="toggleChartMenu" type="button" class="btn-toggle">☰</button>

        <div id="chartMenu">
            <ul>
                <li><a href="#" id="menuDonut" data-type="donut">Donut Chart</a></li>
                <li><a href="#" id="menuBar" data-type="bar">Bar Chart</a></li>
            </ul>
        </div>
    </div>




    <div class="chart-section-container">
        <div id="sectionCountry" class="chart-section" style="position: relative; margin: auto;">

            <!-- 1) Canvas for the doughnut -->
            <canvas id="ctxDonut" width="900" height="600"></canvas>

            <!-- 2) Loading spinner -->
            <div id="spinnerDonut"
                style="display: none; position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%); background: rgba(255,255,255,0.8); padding: 5px 10px; border-radius: 4px; font-weight: bold;">
                Loading…
            </div>
        </div>

        <div id="sectionYear" class="chart-section" style="display: none; position: relative;">
            <canvas id="ctxLine" width="900" height="600"></canvas>
            <div id="spinnerDonut"
                style="display: none; position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%); background: rgba(255,255,255,0.8); padding: 5px 10px; border-radius: 4px; font-weight: bold;">
                Loading…
            </div>
            <asp:GridView ID="gvLineData" runat="server">
                <Columns>
                    <asp:BoundField DataField="Label" HeaderText="Year" />
                    <asp:BoundField DataField="Value" HeaderText="Count" />
                </Columns>
            </asp:GridView>
        </div>

        <div class="info-table">
            <table id="tblDonutData" class="display" style="width: 100%; margin-top: 1rem;">
                <thead>
                    <tr>
                        <th>Law Type</th>
                        <th>Count</th>
                    </tr>
                </thead>
                <tbody>
                    <!-- rows will be injected by loadAllCharts() -->
                </tbody>
            </table>
        </div>
    </div>





    <!-- Hidden fields for each GridView -->
    <asp:HiddenField ID="gvDonutData_Data" runat="server" />
    <asp:HiddenField ID="gvLineData_Data" runat="server" />

    <!-- CLIENT SCRIPT -->
    <script>
        let donutChart = null;
        let lineChart = null;
        let selectedChartType = 'bar';

        function loadAllCharts() {
            // hide both spinners, then show whichever you need
            $('#spinnerDonut, #spinnerLine').hide();

            // gather filters
            const years = $('#<%=ddlYear.ClientID%>').val();
        const lawType = $('#<%=ddlLawType.ClientID%>').val();
        const categories = $('#<%=ddlCategories.ClientID%>').val();
        const fileType = $('#<%=ddlfileType.ClientID%>').val();
        const groupBy = $('#<%=ddlGroupBy.ClientID%>').val();
        const countries = $('#<%=ddlCountries.ClientID%> option:selected')
                .map((_, o) => o.value).get();

            function hasSelection(v) {
                if (!v) return false;
                if (Array.isArray(v)) return v.length > 0;
                if (typeof v === 'string') return v.trim().length > 0;
                return true;
            }

            // if nothing selected, clear charts & table
            if (![years, lawType, categories, fileType, groupBy, countries].some(hasSelection)) {
                if (donutChart) { donutChart.destroy(); donutChart = null; }
                if (lineChart) { lineChart.destroy(); lineChart = null; }
                $('#sectionCountry, #sectionYear').hide();
                if ($.fn.dataTable.isDataTable('#tblDonutData')) {
                    $('#tblDonutData').DataTable().clear().destroy();
                }
                $('#tblDonutData').hide();
                return;
            }

            // build filters
            const filters = {
                year: years, lawType, category: categories,
                fileType, groupBy, country: countries,
                type: groupBy ? 'grouped' : 'donut'
            };
            const clientType = countries.length > 1 ? 'line' : selectedChartType;

            $.ajax({
                url: 'ChartDataHandler.ashx',
                data: filters,
                dataType: 'json',
                traditional: true
            }).done(ds => {
                // 0. Destroy old DataTable
                if ($.fn.dataTable.isDataTable('#tblDonutData')) {
                    $('#tblDonutData').DataTable().clear().destroy();
                }

                // 1. No data?
                if (!ds.length) {
                    alert('No data.');

                    // hide charts
                    if (donutChart) { donutChart.destroy(); donutChart = null; }
                    if (lineChart) { lineChart.destroy(); lineChart = null; }
                    $('#sectionCountry, #sectionYear').hide();

                    // show and re-init table with empty data + "No data found" message
                    $('#tblDonutData').show().DataTable({
                        data: [],      // no rows
                        columns: [
                            { title: 'Law Type' },
                            { title: 'Count' }
                        ],
                        paging: false,
                        searching: false,
                        info: false,
                        ordering: false,
                        language: {
                            emptyTable: 'No data found'
                        }
                    });
                    return;
                }

                // LINE CHART
                if (clientType === 'line') {
                    $('#sectionCountry').hide();
                    $('#sectionYear').show();
                    $('#spinnerLine').show();

                    // collect years
                    const allYears = Array.from(new Set(
                        ds.flatMap(s => s.data.map(pt => pt.x))
                    )).sort();

                    // align datasets
                    const datasets = ds.map(s => {
                        const mapY = Object.fromEntries(s.data.map(pt => [pt.x, pt.y]));
                        return {
                            label: s.label,
                            data: allYears.map(y => mapY[y] || 0),
                            fill: true,
                            tension: 0.4,
                            cubicInterpolationMode: 'monotone'
                        };
                    });

                    // draw bar-horizontal chart
                    if (lineChart) lineChart.destroy();
                    lineChart = new Chart(
                        document.getElementById('ctxLine').getContext('2d'),
                        {
                            type: 'bar',
                            data: { labels: allYears, datasets },
                            options: {
                                indexAxis: 'y',
                                responsive: true,
                                scales: {
                                    x: { beginAtZero: true, title: { display: true, text: 'Count' } },
                                    y: { title: { display: true, text: 'Year' } }
                                },
                                plugins: { legend: { position: 'top' } }
                            }
                        }
                    );

                    // build table rows: series label + each point
                    const rowData = ds.flatMap(s =>
                        s.data.map(pt => [s.label, pt.y])
                    );
                    $('#tblDonutData').DataTable({
                        data: rowData,
                        columns: [
                            { title: 'Series' },
                            { title: 'Value' }
                        ],
                        paging: true,
                        searching: true
                    });
                    $('#tblDonutData').show();
                    $('#spinnerLine').hide();
                    return;
                }

                // DONUT or BAR
                $('#sectionYear').hide();
                $('#sectionCountry').show();
                $('#spinnerDonut').show();

                // draw doughnut or bar
                if (donutChart) donutChart.destroy();
                donutChart = new Chart(
                    document.getElementById('ctxDonut').getContext('2d'),
                    {
                        type: clientType === 'bar' ? 'bar' : 'doughnut',
                        data: {
                            labels: ds.map(r => r.Label),
                            datasets: [{
                                label: clientType === 'bar' ? 'Count' : '',
                                data: ds.map(r => r.Value),
                                backgroundColor: ds.map((_, i) => `hsl(${i * 40 % 360},60%,60%)`)
                            }]
                        },
                        options: {
                            responsive: true,
                            scales: clientType === 'bar' ? {
                                x: { beginAtZero: true }, y: { beginAtZero: true }
                            } : {},
                            plugins: { legend: { display: clientType !== 'bar' } }
                        }
                    }
                );

                // populate table: Label | Value
                const rowData = ds.map(r => [r.Label, r.Value]);
                $('#tblDonutData').DataTable({
                    data: rowData,
                    columns: [
                        { title: 'Value' },
                        { title: 'Count' }
                    ],
                    paging: true,
                    searching: true
                });
                $('#tblDonutData').show();
                $('#spinnerDonut').hide();
            })
                .fail(() => {
                    $('#spinnerDonut, #spinnerLine').hide();
                    alert('Failed loading chart data');
                });
        }

        // chart-type menu
        $('#chartMenu a').on('click', e => {
            e.preventDefault();
            $('#chartMenu a').removeClass('active');
            $(e.currentTarget).addClass('active');
            selectedChartType = $(e.currentTarget).data('type') === 'bar' ? 'bar' : 'doughnut';
            $('#sectionYear').hide();
            $('#sectionCountry').show();
            loadAllCharts();
        });

        // toggle sidebar
        document.getElementById('toggleChartMenu').onclick = e => {
            e.preventDefault();
            document.getElementById('chartMenu').classList.toggle('hidden');
        };

        // on load
        $(function () {
            $('.searchable').on('change', loadAllCharts);
            $('#<%=btnFilter.ClientID%>').on('click', e => { e.preventDefault(); loadAllCharts(); });
      loadAllCharts();
  });



        $(document).ready(function () {

            const ddlGroupBy = $('#<%=ddlGroupBy.ClientID%>');

        function updateFilterVisibility() {
            const groupByValue = ddlGroupBy.val();

            // Show all by default
            $('#filterCountries, #filterCategories, #filterLawType, #filterFileType').show();

            // Clear and hide specific ones depending on groupBy
            if (groupByValue === 'Country') {
                $('#<%=ddlCountries.ClientID%>').val([]).trigger('change'); // clear multiselect
              $('#filterCountries').slideUp();
          } else if (groupByValue === 'Category') {
              $('#<%=ddlCategories.ClientID%>').val('').trigger('change');
              $('#filterCategories').slideUp();
          } else if (groupByValue === 'LawTypeArabic') {
              $('#<%=ddlLawType.ClientID%>').val('').trigger('change');
              $('#filterLawType').slideUp();
          } else if (groupByValue === 'FileType') {
              $('#<%=ddlfileType.ClientID%>').val('').trigger('change');
                $('#filterFileType').slideUp();
            }
        }

        // Initial call on page load
        updateFilterVisibility();

        // Bind to dropdown change
        ddlGroupBy.on('change', updateFilterVisibility);
    });

        function resetFilters() {
            // Clear single-selection dropdowns by setting their value to empty or default
            $('#<%=ddlYear.ClientID%>').val('');
        $('#<%=ddlLawType.ClientID%>').val('');
        $('#<%=ddlCategories.ClientID%>').val('');
        $('#<%=ddlfileType.ClientID%>').val('');
        $('#<%=ddlGroupBy.ClientID%>').val(''); // Reset Group By dropdown to default (all)

        // Clear multi-select listbox selections
        $('#<%=ddlCountries.ClientID%> option').prop('selected', false);

            // Optionally trigger any change events if needed for UI updates
            $('.searchable').trigger('change');

            // Also update visibility of filters according to the groupBy reset
            updateFilterVisibility();

            // Reload charts with cleared filters
            loadAllCharts();

        }
    </script>




    <style>
        :root {
            --primary: #880b4d;
            --light: #f9f9f9;
            --light-bg: #f9f9f9;
            --dark-text: #333;
            --text: "white";
        }


        .btn-reset {
            background-color: #ccc;
            border: 1px solid #999;
            color: #333;
            padding: 6px 12px;
            margin-left: 10px;
            cursor: pointer;
        }

            .btn-reset:hover {
                background-color: #bbb;
            }

        .btn-export {
            background-color: var(--primary);
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            margin-right: 8px;
            cursor: pointer;
            font-weight: 500;
        }

            .btn-export:hover {
                background-color: #a21a6a;
            }



        .dataTables_wrapper label {
            padding: 0 16px
        }

        .sorting {
            padding: 8px 16px !important;
        }

        tbody > tr > td {
            padding: 8px 16px !important;
        }

        .paginate_button.current {
            background-color: var(--primary) !important;
            color: var(--text) !important;
        }

        /* Padding around pagination controls */
        .dataTables_info {
            padding: 1rem; /* Adjust as needed */
        }

        /* Style the page number buttons */
        div.dataTables_wrapper div.dataTables_paginate ul.pagination li a {
            background-color: var(--primary); /* Change this to your desired color */
            color: white !important;
            border: none;
            border-radius: 4px;
            margin: 0 2px;
            padding: 6px 12px;
            font-weight: 500;
        }

        /* Style the active page button */
        div.dataTables_wrapper div.dataTables_paginate ul.pagination li.active a {
            background-color: #a21a6a !important; /* A slightly darker primary */
            color: white !important;
        }

        /* Hover effect */
        div.dataTables_wrapper div.dataTables_paginate ul.pagination li a:hover {
            background-color: #c2185b;
        }

        .last-filter {
            width: 100%;
            flex-direction: row;
            display: flex;
            gap: 16px;
        }

        /* Filters container */
        .filters {
            display: flex;
            flex-direction: column;
            gap: 1rem;
            align-items: flex-start;
            background: var(--primary);
            padding: 1rem;
            border-radius: 8px;
            color: white;
            margin-bottom: 1.5rem;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
            width: 90%;
            margin: auto;
            margin-top: 16px
        }

        .filters-inner {
            flex-direction: row;
            display: flex;
            gap: 16px;
            flex-wrap: wrap;
        }



        .filter-item {
            display: flex;
            flex-direction: column;
            min-width: 100px;
        }

            .filter-item label,
            .filters label {
                margin-bottom: 0.25rem;
                font-weight: 600;
                color: var(--text);
                margin-right: 0.5rem;
            }

            .filter-item select,
            .filters select {
                padding: 0.4rem 0.5rem;
                border: 1px solid #ccc;
                border-radius: 4px;
                background: white;
                min-width: 8rem;
                font-size: 0.9rem;
            }

        .filters button {
            padding: 0.5rem 0.75rem;
            background: white;
            color: var(--primary);
            font-weight: 600;
            border: none;
            border-radius: 4px;
            font-size: 0.9rem;
            cursor: pointer;
        }

            .filters button:hover {
                background: #f0f0f0;
            }

        .filter-action {
            flex: 1;
            align-self: flex-end;
            display: flex;
            flex-direction: row;
            justify-content: space-between;
            gap: 16px;
        }

        .btn-apply {
            padding: 0.5rem 1rem;
            background: var(--primary);
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-weight: 600;
        }

            .btn-apply:hover {
                background: #a21a6a;
            }








        #chartMenu {
            transition: all 0.3s ease;
        }

            #chartMenu.hidden {
                display: none;
            }

        #toggleChartMenu {
            margin-bottom: 10px;
            background-color: var(--primary);
            color: white;
            border: none;
            padding: 6px 12px;
            cursor: pointer;
            border-radius: 4px;
        }

        #chartMenuWrapper {
            margin-bottom: 1rem;
        }






        /* Sidebar menu */
        #chartMenu {
            position: fixed;
            top: 20%;
            left: 0;
            width: 150px;
            background: var(--light);
            border-right: 1px solid #ddd;
            padding: 1rem;
            border-top-right-radius: 8px;
            border-bottom-right-radius: 8px;
            z-index: 1000;
        }

            #chartMenu ul {
                list-style: none;
                padding: 0;
                margin: 0;
            }

            #chartMenu li + li {
                margin-top: 0.75rem;
            }

            #chartMenu a {
                display: block;
                padding: 0.5rem;
                color: var(--dark-text);
                font-weight: 500;
                border-radius: 4px;
                text-decoration: none;
                transition: background 0.2s, color 0.2s;
                cursor: pointer;
            }

                #chartMenu a:hover,
                #chartMenu a.active {
                    background: var(--primary);
                    color: white;
                }



        .sectionCountry {
            width: 100%;
        }

        .chart-section-container {
            width: 90%;
            margin: 20px auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
        }

        /* Chart sections */
        .chart-section {
            width: 60%;
            margin: auto;
            margin-bottom: 2rem;
            padding: 1rem;
        }

            .chart-section h3 {
                margin-top: 0;
                color: var(--primary);
            }

        /* Spinners */
        #spinnerDonut,
        #spinnerLine {
            font-size: 1rem;
            color: var(--primary);
        }

        /* GridView styling */
        .gridview {
            width: 100%;
            border-collapse: collapse;
            margin-top: 1rem;
        }

            .gridview th,
            .gridview td {
                padding: 0.5rem;
                border: 1px solid #ddd;
                text-align: left;
            }

            .gridview th {
                background: var(--light);
            }

            .gridview tr:nth-child(even) {
                background: #fafafa;
            }
    </style>




</asp:Content>--%>
