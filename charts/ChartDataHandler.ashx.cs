using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;

namespace charts
{
    /// <summary>
    /// HTTP handler for returning chart data as JSON.
    /// Now returns LawTitle and FilePath together.
    /// </summary>
    public class ChartDataHandler : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.ContentEncoding = System.Text.Encoding.UTF8;
            context.Response.HeaderEncoding = System.Text.Encoding.UTF8;

            // 1) Read query parameters
            string yearFilter = context.Request["year"]?.Trim() ?? string.Empty;
            string[] countries = context.Request["country"]?
                .Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(s => s.Trim())
                .Where(s => !string.IsNullOrEmpty(s))
                .ToArray()
                ?? Array.Empty<string>();
            string categoryFilter = context.Request["category"]?.Trim() ?? string.Empty;
            string fileTypeFilter = context.Request["fileType"]?.Trim() ?? string.Empty;
            string groupBy = context.Request["groupBy"]?.Trim() ?? string.Empty;

            bool groupingByYear = string.Equals(groupBy, "Year", StringComparison.OrdinalIgnoreCase);
            bool hasCountries = countries != null && countries.Length > 0;

            var points = new List<ChartPoint>();
            string connStr = ConfigurationManager.ConnectionStrings["AIOConnectionString"]?.ConnectionString;
            if (string.IsNullOrEmpty(connStr))
            {
                context.Response.StatusCode = 500;
                var errNoConn = new { error = "Connection string 'AIOConnectionString' is not configured." };
                context.Response.Write(new JavaScriptSerializer().Serialize(errNoConn));
                return;
            }

            try
            {
                using (var conn = new SqlConnection(connStr))
                using (var cmd = conn.CreateCommand())
                {
                    string groupCol;
                    if (string.IsNullOrEmpty(groupBy) || groupBy.Equals("Country", StringComparison.OrdinalIgnoreCase))
                        groupCol = "Country";
                    else if (groupBy.Equals("Category", StringComparison.OrdinalIgnoreCase))
                        groupCol = "Category";
                    else if (groupBy.Equals("FileType", StringComparison.OrdinalIgnoreCase))
                        groupCol = "FileType";
                    else if (groupingByYear)
                        groupCol = null;
                    else
                        groupCol = "Country";

                    var whereT1List = new List<string> { "(@Year = '' OR LawYear = @Year)", "(@Category = '' OR Category = @Category)", "(@FileType = '' OR FileType = @FileType)" };
                    var whereT2List = new List<string> { "(@Year = '' OR t2.LawYear = @Year)", "(@Category = '' OR t2.Category = @Category)", "(@FileType = '' OR t2.FileType = @FileType)" };

                    if (hasCountries)
                    {
                        var countryParams = new List<string>();
                        for (int i = 0; i < countries.Length; i++)
                        {
                            string paramName = "@c" + i;
                            countryParams.Add(paramName);
                            cmd.Parameters.Add(new SqlParameter(paramName, SqlDbType.NVarChar, 200) { Value = countries[i] });
                        }
                        string inClause = string.Join(",", countryParams);
                        whereT1List.Add($"Country IN ({inClause})");
                        whereT2List.Add($"t2.Country IN ({inClause})");
                    }

                    string whereT1 = string.Join(" AND ", whereT1List);
                    string whereT2 = string.Join(" AND ", whereT2List);

                    if (!groupingByYear)
                    {
                        if (string.IsNullOrEmpty(groupCol)) groupCol = "Country";
                        cmd.CommandText = $@"
                        SELECT
                            t1.[{groupCol}] AS Label,
                            MIN(LawYear) AS Year,
                            COUNT(*) AS Value,
                            STUFF((
                                SELECT DISTINCT ';' + t2.LawTitle + '|' + t2.FilePath
                                FROM SectionsITR t2
                                WHERE t2.[{groupCol}] = t1.[{groupCol}]
                                  AND {whereT2}
                                FOR XML PATH(''), TYPE
                            ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS Files
                        FROM SectionsITR t1
                        WHERE {whereT1}
                        GROUP BY t1.[{groupCol}]
                        ORDER BY Value DESC;";
                    }
                    else
                    {
                        cmd.CommandText = $@"
                        SELECT
                            t1.Country AS Label,
                            t1.LawYear AS Year,
                            COUNT(*) AS Value,      
                            STUFF((
                                SELECT DISTINCT ';' + t2.LawTitle + '|' + t2.FilePath
                                FROM SectionsITR t2
                                WHERE t2.Country = t1.Country
                                  AND t2.LawYear = t1.LawYear
                                  AND {whereT2}
                                FOR XML PATH(''), TYPE
                            ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS Files
                        FROM SectionsITR t1
                        WHERE {whereT1}
                        GROUP BY t1.Country, t1.LawYear
                        ORDER BY t1.Country ASC, t1.LawYear ASC;";
                    }

                    // Add parameters
                    cmd.Parameters.Add(new SqlParameter("@Year", SqlDbType.NVarChar, 50) { Value = (object)yearFilter ?? string.Empty });
                    cmd.Parameters.Add(new SqlParameter("@Category", SqlDbType.NVarChar, 200) { Value = (object)categoryFilter ?? string.Empty });
                    cmd.Parameters.Add(new SqlParameter("@FileType", SqlDbType.NVarChar, 200) { Value = (object)fileTypeFilter ?? string.Empty });

                    conn.Open();
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string label = reader["Label"]?.ToString() ?? string.Empty;
                            string rawYear = reader["Year"]?.ToString() ?? string.Empty;
                            int val = 0;
                            if (int.TryParse(reader["Value"]?.ToString(), out int tmpVal))
                                val = tmpVal;

                            string filesRaw = reader["Files"] as string ?? string.Empty;

                            var files = filesRaw
                                .Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries)
                                .Select(f =>
                                {
                                    var parts = f.Split('|');
                                    return new ChartFile
                                    {
                                        LawTitle = parts[0],
                                        FilePath = parts.Length > 1
                                            ? parts[1].Replace(@"C:\ITR_solution", "").Replace("\\", "/")
                                            : ""
                                    };
                                })
                                .Distinct()
                                .ToList();

                            var tooltipParts = new List<string>();
                            if (string.IsNullOrEmpty(yearFilter) && !string.IsNullOrEmpty(rawYear))
                                tooltipParts.Add($"السنة: {rawYear}");

                            points.Add(new ChartPoint
                            {
                                Label = label,
                                Year = rawYear,
                                Value = val,
                                Tooltip = string.Join("، ", tooltipParts),
                                Files = files
                            });
                        }
                    }
                }

                var json = new JavaScriptSerializer().Serialize(points);
                context.Response.Write(json);
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                var error = new { error = ex.Message };
                context.Response.Write(new JavaScriptSerializer().Serialize(error));
            }
        }

        public bool IsReusable => false;
    }

    public class ChartPoint
    {
        public string Label { get; set; }
        public string Year { get; set; }
        public int Value { get; set; }
        public string Tooltip { get; set; }
        public List<ChartFile> Files { get; set; }
    }

    public class ChartFile
    {
        public string LawTitle { get; set; }
        public string FilePath { get; set; }
    }
}
