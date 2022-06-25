using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Npgsql;
using System.Configuration;
using Amdproject.Models;
using System.Data;
using System.Web.Security;

namespace Amdproject.Controllers
{
   
    public class UserController : Controller
    {
        NpgsqlParameter[] param; 
        NpgsqlConnection conn = new NpgsqlConnection(ConfigurationManager.ConnectionStrings["conn"].ConnectionString);

        [Authorize]
        public ActionResult profile()
        {
           
            return View();
        }

        [Authorize]
        [HttpPost]
        
        public ActionResult profile(users model,FormCollection fr) 
        {
            try
            {
               
                string old, newpass,name;
                old = fr["old"].ToString();
                newpass = fr["new"].ToString();
                name = fr["name"].ToString();
                int id =int.Parse( User.Identity.Name.ToString().Split(',')[0]);
                param = new NpgsqlParameter[4];
                param[0] = new NpgsqlParameter("name", name);
                param[1] = new NpgsqlParameter("password",old );
                param[2] = new NpgsqlParameter("newpass", newpass);
                param[3] = new NpgsqlParameter("userid", id);
                DataTable dt = new DataTable();
                dt=  dbhelper.getdata("updateuser", param,dt);

               
                if (dt.Rows[0][0].ToString() == "ok")
                {



                   
                    FormsAuthentication.SignOut();
                  
                    FormsAuthentication.RedirectToLoginPage();
                    return RedirectToAction("login", "User");
                   
                }
                else
                {
                    ViewBag.error = "password must be incorrect";
                    return View(model);
                }

            }
            catch (Exception ex)
            {
                ViewBag.error = ex.Message;
                return View(model);
            }
          
        }



        public ActionResult Register()
        {
            if (Request.IsAuthenticated)
            {
                return RedirectToAction("Index", "Default");
            }
            return View();
        }

      

        [HttpPost]
        public ActionResult Register(users newuser)
        {

            try
            {
                if (ModelState.IsValid)
                {
                    param = new NpgsqlParameter[2];
                    param[0] = new NpgsqlParameter("name", newuser.username);
                    param[1] = new NpgsqlParameter("pass", newuser.Password);
                    dbhelper.docmd("register", param);
                    return RedirectToAction("Login");
                }
                return View(newuser);
            }
            catch (Exception ex)
            {
                ViewBag.error = ex.Message;
                return View(newuser);
            }

        }

        public ActionResult Login()
        {
            if (Request.IsAuthenticated)
            {
                return RedirectToAction("Index","Default");
            }
            return View();
        }
        [HttpPost]
        public ActionResult Login(users login)
        {

           

            try
            {
                
                if (ModelState.IsValid)
                {
                    DataTable dt = new DataTable();
                    param = new NpgsqlParameter[2];
                    param[0] = new NpgsqlParameter("name", login.username);
                    param[1] = new NpgsqlParameter("password", login.Password);
                    dt = dbhelper.getdata("login", param, dt);
                    if (dt.Rows[0][0].ToString() != "-1")
                    {
                        FormsAuthentication.SetAuthCookie(dt.Rows[0][0].ToString(), true);
                      
                        return RedirectToAction("Index", "Default");
                    }
                    ViewBag.error = "Username Or Password is incorrect";
                }
               
                return View(login);
            }
            catch (Exception ex)
            {
                ViewBag.error = ex.Message;
                return View(login);
            }
        }



        [AllowAnonymous]
        [HttpPost]
        public JsonResult checkforusername(string username)
        {
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[1];
           param[0] = new NpgsqlParameter("name", username);
            dt = dbhelper.getdata("checkusername", param, dt);
            return Json(dt.Rows[0][0].ToString());

        }


       
        [HttpPost]
        [Authorize]
        public ActionResult Signout()
        {
           
            FormsAuthentication.SignOut();
          
            return RedirectToAction("Login","User");


        }


        [Authorize]
        [HttpPost]
        public JsonResult Delete(string pass)
        {

            int uid = int.Parse(User.Identity.Name.Split(',')[0]);
            DataTable dt = new DataTable();
            param = new NpgsqlParameter[2];
            param[0] = new NpgsqlParameter("uid", uid);
            param[1] = new NpgsqlParameter("passwordd", pass);
            dt = dbhelper.getdata("deleteuser", param,dt);
            if(dt.Rows[0][0].ToString()=="ok")
            FormsAuthentication.SignOut();

            return Json(dt.Rows[0][0].ToString());

        }




    }
}