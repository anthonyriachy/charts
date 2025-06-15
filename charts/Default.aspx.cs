using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace charts
{
    public partial class _Default : Page
    {
        private string ConnStr => System.Configuration.ConfigurationManager.ConnectionStrings["AIOConnectionString"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                PopulateFilters();
            }
        }

        private void PopulateFilters()
        {
            using (var cn = new SqlConnection(ConnStr))
            {
                var years = new List<int>();
                var types = new List<string>();
                var countries = new List<string>();
                var categories = new List<string>();
                var fileType = new List<string>();
                // Years
                using (var cmd = new SqlCommand("SELECT DISTINCT LawYear FROM SectionsITR ORDER BY LawYear", cn))
                {
                    cn.Open();
                    var rdr = cmd.ExecuteReader();
                    while (rdr.Read()) years.Add(rdr.GetInt32(0));
                    cn.Close();
                }
                ddlYear.DataSource = years;
                ddlYear.DataBind();
                ddlYear.Items.Insert(0, new ListItem("-- All --", ""));


                // Category
                using (var cmd = new SqlCommand("SELECT DISTINCT Category FROM SectionsITR ORDER BY Category", cn))
                {
                    cn.Open();
                    var rdr = cmd.ExecuteReader();
                    while (rdr.Read()) categories.Add(rdr.GetString(0));
                    cn.Close();
                }

                ddlCategories.DataSource = categories;
                ddlCategories.DataBind();
                ddlCategories.Items.Insert(0, new ListItem("-- All --", ""));


                // Countries
                using (var cmd = new SqlCommand("SELECT DISTINCT Country FROM SectionsITR ORDER BY Country", cn))
                {
                    cn.Open();
                    var rdr = cmd.ExecuteReader();
                    while (rdr.Read()) countries.Add(rdr.GetString(0));
                    cn.Close();
                }

                ddlCountries.DataSource = countries;
                ddlCountries.DataBind();


                // file type
                using (var cmd = new SqlCommand("SELECT DISTINCT FileType FROM SectionsITR ORDER BY FileType", cn))
                {
                    cn.Open();
                    var rdr = cmd.ExecuteReader();
                    while (rdr.Read()) fileType.Add(rdr.GetString(0));
                    cn.Close();
                }

                ddlfileType.DataSource = fileType;
                ddlfileType.DataBind();
                ddlfileType.Items.Insert(0, new ListItem("-- All --", ""));
            }
        }




        // Optional: implement sorting & paging handlers (gv_Sorting, gv_PageIndexChanging)
        protected void gv_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            var gv = (GridView)sender;
            gv.PageIndex = e.NewPageIndex;
            gv.DataBind();
        }
        protected void gv_Sorting(object sender, GridViewSortEventArgs e)
        {
            // you can sort the last-bound data source stored in ViewState, then rebind
        }
    }


}