using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Amdproject.Models;
using Npgsql;

namespace Amdproject.Controllers
{

   
    public class FilmsController : Controller
    {

        NpgsqlParameter[] param;
        public Filmmodel getdetail(Int64? id)
        {
            Filmmodel model = new Filmmodel();
            DataTable dt = new DataTable();
           
           
            dt = dbhelper.view("select * from getfilmdetail where fid=" + id+"", dt);

            if (dt.Rows.Count > 0)
            {
                model.fid = Int64.Parse(dt.Rows[0][0].ToString());
                model.parentId = int.Parse(dt.Rows[0]["parentid"].ToString());
                model.fname = dt.Rows[0]["fname"].ToString();
                model.pic = dt.Rows[0]["pic"].ToString();
                model.about = dt.Rows[0]["about"].ToString();
                model.rdate = int.Parse( dt.Rows[0]["rdate"].ToString());
                model.cats = new List<catorrole>();
                foreach(DataRow dr in dt.Rows)
                {
                    model.cats.Add(new catorrole { id = int.Parse(dr["id"].ToString()), name = dr["gname"].ToString() });
                }

            }
            
            




            return model;
        }
        public Int64 getfilmid(string fname,int rdate ,Int64 parentid)
        {


            DataTable dt = new DataTable();
            param = new NpgsqlParameter[3];
            param[0] = new NpgsqlParameter("@fnamee", NpgsqlTypes.NpgsqlDbType.Text);
            param[0].Value = fname;
            param[1] = new NpgsqlParameter("@rdatee", NpgsqlTypes.NpgsqlDbType.Integer);
            param[1].Value = rdate;
            param[2] = new NpgsqlParameter("@parentidd", NpgsqlTypes.NpgsqlDbType.Bigint);
            param[2].Value = parentid;
            dt = dbhelper.getdata("getfilmid", param, dt);
           
            return Int64.Parse(dt.Rows[0][0].ToString());
        }
        public void getfilms(Int64? id)
        {
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[1];
          
            param[0] = new NpgsqlParameter("cond", NpgsqlTypes.NpgsqlDbType.Bigint);
            if (id == null)param[0].Value = DBNull.Value;
            else param[0].Value = DBNull.Value;
            dt = dbhelper.getdata("getfilms", param, dt);
            List<Filmmodel> filmlist = new List<Filmmodel>();

            filmlist = dbhelper.ConvertDataTable<Filmmodel>(dt);
            filmlist.Add(new Filmmodel { fname = " No Parent  " });
            var item = filmlist[filmlist.Count - 1];

           filmlist.RemoveAt(filmlist.Count - 1);
            filmlist.Insert(0, item);

            ViewBag.films = new SelectList(filmlist, "fid", "fname");
        }
        public void getgenres()
        {
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[1];
            param[0] = new NpgsqlParameter("cond", DBNull.Value);
            dt = dbhelper.getdata("getgenre", param, dt);
            List<catorrole> genrelist = new List<catorrole>();

            genrelist = dbhelper.ConvertDataTable<catorrole>(dt);
           

            ViewBag.genre = new SelectList(genrelist, "id", "name");
        }
        public void getroles()
        {
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[1];
            param[0] = new NpgsqlParameter("cond", DBNull.Value);
            dt = dbhelper.getdata("getroles", param, dt);
            List<catorrole> rolelist = new List<catorrole>();
            rolelist = dbhelper.ConvertDataTable<catorrole>(dt);
            ViewBag.roles = new SelectList(rolelist, "id", "name");
        }
        public void getfrpnames()
        {
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[0];
            dt = dbhelper.getdata("getfrpnames", param, dt);
            List<catorrole> rolelist = new List<catorrole>();
            rolelist = dbhelper.ConvertDataTable<catorrole>(dt);
            ViewBag.frpnames = new SelectList(rolelist, "id", "name");
        }


        [Authorize]
        public ActionResult Films(Int64? id)
        {
            if (id == null)
            {
                getgenres();
                getfilms(null);
                return View();
            }
            else
            {

                getgenres();
                getfilms(id);
                var model = getdetail(id);
                getroles();
                getfrpnames();
                if (model.cats == null)
                {
                    return View();
                }
               
                return View(model);
            }
        }
        [Authorize]
        [HttpPost]
        public ActionResult Films(Filmmodel model,FormCollection fr)
        {

            try
            {
              
                int uid = int.Parse(User.Identity.Name.Split(',')[0]);
                string parentid = fr["parentid"].ToString();
                string genre = fr["multiple"].ToString();
                string[] arr = genre.Split(',');
                getgenres();
                getfilms(null);
                if (ModelState.IsValid)
                {
                    param = new NpgsqlParameter[6];
                    param[0] = new NpgsqlParameter("fname", model.fname);
                    param[1] = new NpgsqlParameter("rdate", NpgsqlTypes.NpgsqlDbType.Integer);
                    param[1].Value = model.rdate;
                    if (model.pic == null)
                        param[2] = new NpgsqlParameter("pic", DBNull.Value);
                    else
                        param[2] = new NpgsqlParameter("pic", model.pic);

                if (model.about == null)
                    param[3] = new NpgsqlParameter("about", DBNull.Value);
                else
                    param[3] = new NpgsqlParameter("about", model.about);
             
                    if (parentid.Length == 0)param[4] = new NpgsqlParameter("parentid", DBNull.Value);
                    else param[4] = new NpgsqlParameter("parentid", NpgsqlTypes.NpgsqlDbType.Bigint);
                    param[4].Value = decimal.Parse(parentid);
                    param[5] = new NpgsqlParameter("uid", uid);
                   string result = dbhelper.docmd("Addnewfilm", param);
                    if (result == "ok")
                    {
                     //   System.Threading.Thread.Sleep(3000);
                        ViewBag.error = model.fname + " " + model.rdate + " " + parentid;
                    Int64 filmid = getfilmid(model.fname, model.rdate, model.parentId);
                    ViewBag.error = filmid;
                        foreach(string cat in arr)
                        {
                            param = new NpgsqlParameter[2];
                            param[0] = new NpgsqlParameter("filmid", NpgsqlTypes.NpgsqlDbType.Bigint);
                            param[0].Value = filmid;
                            param[1] = new NpgsqlParameter("genreid", NpgsqlTypes.NpgsqlDbType.Integer);
                            
                            param[1].Value = int.Parse(cat);
                          ViewBag.error= dbhelper.docmd("addgenretofilms", param);

                        }

                        
                    }
                   
                }

               
                return View();
            }
            catch (Exception ex)
          {
           ViewBag.error = ex.Message;
               return View();
           }

        }

        
        DataTable deleteresult = new DataTable();
        [Authorize]
        [HttpPost]
        public JsonResult Delete(Int64 fid)
        {
            
            int uid = int.Parse(User.Identity.Name.Split(',')[0]);
            param = new NpgsqlParameter[1];
            param[0] = new NpgsqlParameter("id", fid);
          
            deleteresult = dbhelper.getdata("deletemovie", param, deleteresult);
            return Json(deleteresult.Rows[0][0]);

        }

        [Authorize]
        [HttpPost]
        public JsonResult Update(Int64 fid,string fname,int rdate,string pic,string about,Int64 parentid,string genre)
        {

            param = new NpgsqlParameter[7];
            param[0] = new NpgsqlParameter("fidd", fid);
            param[1] = new NpgsqlParameter("fnamee", fname);
            param[2] = new NpgsqlParameter("rdatee", rdate);
            param[3] = new NpgsqlParameter("piccs", pic);
            param[4] = new NpgsqlParameter("aboutt", about);
            param[5] = new NpgsqlParameter("parentidd", parentid);
            param[6] = new NpgsqlParameter("genree", genre);
            return Json(dbhelper.docmd("updatefilm", param));

        }



        [Authorize]
        [HttpPost]
        public JsonResult getlastrecordid()
        {
            int uid = int.Parse(User.Identity.Name.Split(',')[0]);
            param = new NpgsqlParameter[3];
            param[0] = new NpgsqlParameter("tablee", "films");
            param[1] = new NpgsqlParameter("field", "fid");
            param[2] = new NpgsqlParameter("uid", uid);
            DataTable dt = new DataTable();
            dt = dbhelper.getdata("lastrecordbyuid", param, dt);
            return Json(dt.Rows[0][0]);

        }



        [Authorize]
        [HttpPost]
        public JsonResult Addroles(Int64 frpid, Int64 fid,string roleid,string all)
        {
            string result = "";
            try
            {
                DataTable dt = new DataTable();
                param = new NpgsqlParameter[4];
                param[0] = new NpgsqlParameter("fidd", fid);
                param[1] = new NpgsqlParameter("frpidd", frpid);
                param[2] = new NpgsqlParameter("roleidd", roleid);
                param[3] = new NpgsqlParameter("applyall", all);
                dt = dbhelper.getdata("addpersontomovie", param,dt);
                result = dt.Rows[0][0].ToString();
                
             }catch(Exception ex)
            {
                result = ex.Message;
            }
            return Json(result);

        }




        public PartialViewResult Listpersonroles(Int64 fid)
        {
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[1];

            param[0] = new NpgsqlParameter("fidd", NpgsqlTypes.NpgsqlDbType.Bigint);
             param[0].Value = fid;
            dt = dbhelper.getdata("getpersoninmovies", param, dt);
            List<personinmovemodel> pim = new List<personinmovemodel>();

            pim = dbhelper.ConvertDataTable<personinmovemodel>(dt);
           
            return PartialView("Listpersonroles", pim);
        }



        [Authorize]
        [HttpPost]
        public JsonResult DeletePersonRoleInMovies(Int64 id)
        {
            string result = "";
            try
            {
                DataTable dt = new DataTable();
                param = new NpgsqlParameter[1];
                param[0] = new NpgsqlParameter("idd", id);
              
                dt = dbhelper.getdata("delete_person_role_in_movies", param, dt);
                result = dt.Rows[0][0].ToString();

            }
            catch (Exception ex)
            {
                result = ex.Message;
            }
            return Json(result);

        }



       public ActionResult OverView()
        {
           

            return View();
        }

        
        public PartialViewResult ListMovies(Int64? parentid)
        {
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[1];

            param[0] = new NpgsqlParameter("parent", NpgsqlTypes.NpgsqlDbType.Bigint);
            param[0].Value = parentid;
            dt = dbhelper.getdata("getfilmoverview", param, dt);
            List<Filmmodel> pim = new List<Filmmodel>();

            pim = dbhelper.ConvertDataTable<Filmmodel>(dt);
            pim = pim.OrderByDescending(x => x.rating).ToList();
            return PartialView("ListMovies", pim);
        }

        public PartialViewResult ListMovies2(string key)
        {
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[1];

            param[0] = new NpgsqlParameter("keyword",key);
           
            dt = dbhelper.getdata("searchbykeyword", param, dt);
            List<Filmmodel> pim = new List<Filmmodel>();

            pim = dbhelper.ConvertDataTable<Filmmodel>(dt);

            return PartialView("ListMovies", pim);
        }



        public ActionResult detail(Int64? id)
        {

            if (id == null) return RedirectToAction("Index", "Default");

            DataTable dt = new DataTable();
            param = new NpgsqlParameter[1];
            Filmmodel model = new Filmmodel();
            param[0] = new NpgsqlParameter("id", NpgsqlTypes.NpgsqlDbType.Bigint);
            param[0].Value = id;
            dt = dbhelper.getdata("getfildetail", param, dt);

            if (dt.Rows.Count > 0)
            {
                model.fid=Int64.Parse( dt.Rows[0]["fid"].ToString());
                model.fname = dt.Rows[0]["fname"].ToString();
                model.about = dt.Rows[0]["about"].ToString();
                model.pic = dt.Rows[0]["pic"].ToString();
                model.rdate = int.Parse(dt.Rows[0]["rdate"].ToString());
                model.rating =int.Parse( dt.Rows[0]["rating"].ToString());
                dt.Dispose();
                dt = new DataTable();
                param = new NpgsqlParameter[1];
                List<catorrole> model2 = new List<catorrole>();
                param[0] = new NpgsqlParameter("idd", NpgsqlTypes.NpgsqlDbType.Bigint);
                param[0].Value = id;
                dt = dbhelper.getdata("getfilmcatbyid", param, dt);
                model2 = dbhelper.ConvertDataTable<catorrole>(dt);
                model.cats = model2;

                dt.Dispose();
                dt = new DataTable();
                param = new NpgsqlParameter[1];
                List<personinmovemodel> prinmov = new List<personinmovemodel>();
                param[0] = new NpgsqlParameter("fidd", NpgsqlTypes.NpgsqlDbType.Bigint);
                param[0].Value = id;
                dt = dbhelper.getdata("getpersoninmovies", param, dt);
                prinmov = dbhelper.ConvertDataTable<personinmovemodel>(dt);
                model.perinmovie = prinmov;



            }
            else
            {
                return RedirectToAction("OverView");
            }


            //pim = dbhelper.ConvertDataTable<Filmmodel>(dt);

            return View(model);
        }


        //watched
        public ActionResult watched()
        {


            return View();
        }


        public PartialViewResult Listwatched()
        {
            int uid = int.Parse(User.Identity.Name.Split(',')[0]);
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[1];

            param[0] = new NpgsqlParameter("uidd", uid);
           
            dt = dbhelper.getdata("watched", param, dt);
            List<Filmmodel> pim = new List<Filmmodel>();

            pim = dbhelper.ConvertDataTable<Filmmodel>(dt);

            return PartialView("ListMovies", pim);
        }


    }
}