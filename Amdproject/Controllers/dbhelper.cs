using Npgsql;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Reflection;
using System.Web;
using System.Web.Helpers;

namespace Amdproject.Controllers
{
   
    public class dbhelper
    {
        public static NpgsqlConnection conn;
        public static NpgsqlConnection getcon()
        {
           
            return new NpgsqlConnection(ConfigurationManager.ConnectionStrings["conn"].ConnectionString);
        }

        public static string docmd(string query,NpgsqlParameter[] p)
        {
            string result = "ok";

            conn = getcon();
            
           if (conn.State == System.Data.ConnectionState.Closed) conn.Open();
           NpgsqlCommand cmd = new NpgsqlCommand(query, conn);
           cmd.CommandType = System.Data.CommandType.StoredProcedure;
           cmd.Parameters.AddRange(p);
           cmd.ExecuteNonQuery();
           if(conn.State == System.Data.ConnectionState.Open) conn.Close();
           return result;
        }

       

        public static DataTable getdata(string query, NpgsqlParameter[] p,DataTable dt)
        {
            conn = getcon();
            NpgsqlDataAdapter da = new NpgsqlDataAdapter(query, conn);
            da.SelectCommand.CommandType = System.Data.CommandType.StoredProcedure;
            da.SelectCommand.Parameters.AddRange(p);
            da.Fill(dt);
            return dt;
        }

        public static DataTable view(string query,DataTable dt)
        {
            conn = getcon();
            NpgsqlDataAdapter da = new NpgsqlDataAdapter(query, conn);
           

            da.Fill(dt);
            return dt;
        }




        public static List<T> ConvertDataTable<T>(DataTable dt)
        {
            List<T> data = new List<T>();
            
            foreach (DataRow row in dt.Rows)
            {
                T item = GetItem<T>(row);
                data.Add(item);
            }
            return data;
        }
        private static T GetItem<T>(DataRow dr)
        {
            
            Type temp = typeof(T);
            T obj = Activator.CreateInstance<T>();

            foreach (DataColumn column in dr.Table.Columns)
            {
                foreach (PropertyInfo pro in temp.GetProperties())
                {
                    if (pro.Name == column.ColumnName)
                        try {
                            pro.SetValue(obj, dr[column.ColumnName], null);
                        }
                        catch
                        {
                            
                           //  pro.SetValue(obj, "", null);
                        }
                    else
                        continue;
                }
            }
            return obj;
        }



    }

   
}