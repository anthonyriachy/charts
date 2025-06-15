<%@ WebHandler Language="C#" Class="ChartDataHandler" %>
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Web;

public class ChartPoint {
  public string Label { get; set; }
  public int    Value { get; set; }
}

public class ChartDataHandler : IHttpHandler {
  public void ProcessRequest(HttpContext ctx) {
    ctx.Response.ContentType = "application/json";
    string type    = ctx.Request["type"]    ?? "donut";
    string year    = ctx.Request["year"]    ?? "";
    string lawType = ctx.Request["lawType"] ?? "";

    var list = new List<ChartPoint>();
    string conn = System.Configuration.ConfigurationManager
                    .ConnectionStrings["AIOConnectionString"].ConnectionString;
    using (var cn = new SqlConnection(conn))
    using (var cmd = cn.CreateCommand()) {
      if (type == "line") {
        cmd.CommandText = @"
          SELECT LawYear, COUNT(*) AS Count
          FROM SectionsITR
          WHERE (@Type = '' OR LawType = @Type)
          GROUP BY LawYear
          ORDER BY LawYear";
        cmd.Parameters.AddWithValue("@Type", lawType);
      }
      else { // donut
        cmd.CommandText = @"
          SELECT LawType, COUNT(*) AS Count
          FROM SectionsITR
          WHERE (@Year = '' OR LawYear = @Year)
            AND (@Type = '' OR LawType = @Type)
          GROUP BY LawType
          ORDER BY Count DESC";
        cmd.Parameters.AddWithValue("@Year", year);
        cmd.Parameters.AddWithValue("@Type", lawType);
      }

      cn.Open();
      var rdr = cmd.ExecuteReader();
      while (rdr.Read()) {
        string lbl = (type == "line")
          ? rdr.GetInt32(0).ToString()
          : rdr.GetString(0);
        int val = rdr.GetInt32(1);
        list.Add(new ChartPoint { Label = lbl, Value = val });
      }
    }

    var json = new System.Web.Script.Serialization
                     .JavaScriptSerializer().Serialize(list);
    ctx.Response.Write(json);
  }

  public bool IsReusable => false;
}
