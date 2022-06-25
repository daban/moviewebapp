using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;
using Npgsql;
using System.Configuration;
using Amdproject.Models;
using System.Data;
using System.ComponentModel;

namespace Amdproject.Models
{
    public class models
    {
    }

    public class users
    {
        [Required]
        public string username { get; set; }

        [Required]
        [DataType(DataType.Password)]
        public string Password { get; set; }
    }


    public class Filmmodel
    {

        public Int64 fid { get; set; }

        [Required]
        public string fname { get; set; }

        [Required]
        [DataType(DataType.Date)]
        public int rdate { get; set; }

        public string about { get; set; }

        public string pic { get; set; }

        //public  Int64? parentId { get; set; }
        [Required]
        public Int64 parentId { get; set; }

        public int uid { get; set; }



        public  int rating { get; set; }

        public  List<catorrole> cats { get; set; }
        //public virtual ICollection<Filmmodel> Childs { get; set; }

        public List<personinmovemodel> perinmovie { get; set; }

    }


    public class catorrole
    {
        public Int64 id { get; set; }
        public string name { get; set; }
    }


    public class cast
    {
        public string name { get; set; }
        public string role { get; set; }
    }


    public class gendermodel
    {
        public string gender { get; set; }
    }
    public class filmrelatedpesonmodel
    {
        public Int64? id { get; set; }
        [Required]
        public string frpname { get; set; }


        [DataType(DataType.Date)]
        [DisplayFormat(DataFormatString = "{0:yyyy-MM-dd}", ApplyFormatInEditMode = true)]
        [DisplayName("Date of Birth")]
        public DateTime dob { get; set; }


        [DisplayName("Picture")]
        public string pic { get; set; }
        public string Gender { get; set; }
        [DisplayName("User Id")]
        public int uid { get; set; }


    }


    public class personinmovemodel
    {
        public   Int64 id { get; set; }
        public string personname { get; set; }

        public string filmname { get; set; }

        public string rolename { get; set; }
    }
}