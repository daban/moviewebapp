using Amdproject.Models;
using Npgsql;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Amdproject.Controllers
{
    public class DefaultController : Controller
    {
        NpgsqlParameter[] param;
        public ActionResult Index()
        {
            return View();
        }

        
        [HttpPost]
        public JsonResult partialview(string offset,string limit)
        {
            Int64 p1;int p2;
            p1 = Int64.Parse(offset);
            p2 = int.Parse(limit);
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[2];

            param[0] = new NpgsqlParameter("offsett", p1);
          
            param[1] = new NpgsqlParameter("limitt", p2);
            dt = dbhelper.getdata("partialload", param, dt);
            List<Filmmodel> pim = new List<Filmmodel>();

            pim = dbhelper.ConvertDataTable<Filmmodel>(dt);

           return Json(pim.ToList(),JsonRequestBehavior.AllowGet);
        }


        
        [HttpPost]
        public JsonResult rate(string fidd,string ratingg)
        {
            if (!Request.IsAuthenticated)
            {
                return Json("You need to login then you can rate movies", JsonRequestBehavior.AllowGet);
            }
            else
            {
                Int64 p1; int p2;
                p1 = Int64.Parse(fidd);
                p2 = int.Parse(ratingg);

                DataTable dt = new DataTable();
                int uid = int.Parse(User.Identity.Name.Split(',')[0]);
                param = new NpgsqlParameter[3];
                param[0] = new NpgsqlParameter("uidd", uid);
                param[1] = new NpgsqlParameter("fidd", p1);
                param[2] = new NpgsqlParameter("ratingg", p2);
                dt = dbhelper.getdata("rate", param, dt);
                var result = dt.Rows[0][0];
                dt.Dispose();
                return Json(result, JsonRequestBehavior.AllowGet);
            }

        }




        [HttpPost]
        public JsonResult deleterating(string fidd)
        {
            if (!Request.IsAuthenticated)
            {
                return Json("You need to login then you can delete your ratings", JsonRequestBehavior.AllowGet);
            }
            else
            {
                Int64 p1;
                p1 = Int64.Parse(fidd);
               

                DataTable dt = new DataTable();
                int uid = int.Parse(User.Identity.Name.Split(',')[0]);
                param = new NpgsqlParameter[2];
                param[0] = new NpgsqlParameter("uidd", uid);
                param[1] = new NpgsqlParameter("fidd", p1);
              
                dt = dbhelper.getdata("deleterate", param, dt);
                var result = dt.Rows[0][0];
                dt.Dispose();
                return Json(result, JsonRequestBehavior.AllowGet);
            }

        }




        [Authorize]
        public ActionResult suggestion()
        {

            return View();
        }


        [HttpPost]
        public JsonResult suggestpartial(string offset, string limit)
        {
            Int64 p1; int p2;
            p1 = Int64.Parse(offset);
            p2 = int.Parse(limit);
            int uid = int.Parse(User.Identity.Name.Split(',')[0]);
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[3];

            param[0] = new NpgsqlParameter("uidd", uid);
            param[1] = new NpgsqlParameter("offsett", p1);
            param[2] = new NpgsqlParameter("limitt", p2);
            dt = dbhelper.getdata("suggestion", param, dt);
            List<Filmmodel> pim = new List<Filmmodel>();

            pim = dbhelper.ConvertDataTable<Filmmodel>(dt);

            return Json(pim.ToList(), JsonRequestBehavior.AllowGet);
        }


    }
}