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
    public class FRPersonController : Controller
    {
        // GET: FRPerson

            
        NpgsqlParameter[] param;
        public filmrelatedpesonmodel getdetail(Int64? id)
        {
            filmrelatedpesonmodel model = new filmrelatedpesonmodel();
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[1];
            param[0] = new NpgsqlParameter("idd", NpgsqlTypes.NpgsqlDbType.Bigint);
            param[0].Value = id;

            dt = dbhelper.getdata("getfrpdetail", param, dt);

            if (dt.Rows.Count > 0)
            {
                model.id = Int64.Parse(dt.Rows[0][0].ToString());
                model.frpname = dt.Rows[0][1].ToString();
                model.dob = DateTime.Parse(dt.Rows[0][2].ToString());
                model.pic = dt.Rows[0][3].ToString();
                model.Gender = dt.Rows[0][4].ToString();
                model.uid = int.Parse(dt.Rows[0][5].ToString());
            }
            return model;
          }

        [Authorize]
        public ActionResult frpinfo(Int64?id)
        {
            if (id == null)
            {
                return View();
            }
            else
            {
                var model = getdetail(id);
                if (model.frpname == null)
                {
                    return View();
                }
                return View(model);
            }
        }


        [Authorize]
        [HttpPost]
        public ActionResult frpinfo(filmrelatedpesonmodel model, FormCollection fr)
        {

            try
            {

                int uid = int.Parse(User.Identity.Name.Split(',')[0]);

           // string s = model.name + model.pic + model.DOB + model.Gender;
              
                if (ModelState.IsValid)
                {
                    param = new NpgsqlParameter[5];
                    param[0] = new NpgsqlParameter("namee", model.frpname);
                    param[1] = new NpgsqlParameter("dobb", NpgsqlTypes.NpgsqlDbType.Date);
                    if (model.dob == null) param[1].Value = DBNull.Value;
                    else param[1].Value = model.dob;
                    if (model.pic == null)
                        param[2] = new NpgsqlParameter("piccs", DBNull.Value);
                    else
                        param[2] = new NpgsqlParameter("piccs", model.pic);
                        param[3] = new NpgsqlParameter("genderr", model.Gender);
                        param[4] = new NpgsqlParameter("uidd", uid);
                    string result = dbhelper.docmd("addfrp", param);
                    ViewBag.error = result;
                }


                return View(model);
        }
            catch (Exception ex)
            {
                ViewBag.error = ex.Message;
                return View();
    }

}


        [Authorize]
        [HttpPost]
        public JsonResult getlastrecordid()
        {
            int uid = int.Parse(User.Identity.Name.Split(',')[0]);
            param = new NpgsqlParameter[3];
            param[0] = new NpgsqlParameter("tablee", "filmrelatedpersons");
            param[1] = new NpgsqlParameter("field", "id");
            param[2] = new NpgsqlParameter("uid", uid);
            DataTable dt = new DataTable();
            dt = dbhelper.getdata("lastrecordbyuid", param, dt);
            return Json(dt.Rows[0][0]);

        }




        DataTable deleteresult = new DataTable();
        [Authorize]
        [HttpPost]
        public JsonResult Delete(Int64 id)
        {
            string result = "ok";
            try
            {


                param = new NpgsqlParameter[1];
                param[0] = new NpgsqlParameter("idd", id);
                deleteresult = dbhelper.getdata("deletefrpersons", param, deleteresult);
                result = deleteresult.Rows[0][0].ToString();
            }
            catch(Exception ex)
            {
                result = ex.Message;
            }
            return Json(result);

        }

        [Authorize]
        [HttpPost]
        public JsonResult Update(Int64 id, string frpname, DateTime dob, string pic, string gender)
        {

            DataTable dt = new DataTable();
            param = new NpgsqlParameter[5];
            param[0] = new NpgsqlParameter("idd", id);
            param[1] = new NpgsqlParameter("frpnamee", frpname);
            param[2] = new NpgsqlParameter("dobb", NpgsqlTypes.NpgsqlDbType.Date);
            param[2].Value = dob;

            param[3] = new NpgsqlParameter("piccs", pic);
            param[4] = new NpgsqlParameter("genderr", gender);
            dt = dbhelper.getdata("updatefrpesons", param, dt);
            string res = dt.Rows[0][0].ToString();
            dt.Dispose();
            return Json(res);

        }



        public ActionResult overview()
        {
            return View();
        }


        [HttpPost]
        public JsonResult partialview(string offset, string limit)
        {
            Int64 p1; int p2;
            p1 = Int64.Parse(offset);
            p2 = int.Parse(limit);
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[2];

            param[0] = new NpgsqlParameter("offsett", p1);

            param[1] = new NpgsqlParameter("limitt", p2);
            dt = dbhelper.getdata("frpoverview", param, dt);
            List<filmrelatedpesonmodel> pim = new List<filmrelatedpesonmodel>();

            pim = dbhelper.ConvertDataTable<filmrelatedpesonmodel>(dt);

            return Json(pim.ToList(), JsonRequestBehavior.AllowGet);
        }




        public PartialViewResult Listfrp(string name)
        {
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[1];
            param[0] = new NpgsqlParameter("keyword", name);
            dt = dbhelper.getdata("frpsearchbykeyword", param, dt);
            List<filmrelatedpesonmodel> pim = new List<filmrelatedpesonmodel>();
            pim = dbhelper.ConvertDataTable<filmrelatedpesonmodel>(dt);
            return PartialView("Listfrp", pim);
        }


    }
}