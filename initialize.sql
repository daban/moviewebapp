create database amdds owner postgres



CREATE TABLE public.users (
	id int4 NOT NULL,
	username text NOT NULL,
	pass text NOT NULL,
	CONSTRAINT users_pkey PRIMARY KEY (id),
	CONSTRAINT users_username_key UNIQUE (username)
);



CREATE TABLE public.roles (
	id int4 NOT NULL ,
	rname varchar NOT NULL,
	CONSTRAINT roles_pkey PRIMARY KEY (id)
);

CREATE TABLE public.genre (
	id int4 NOT NULL ,
	gname varchar NOT NULL,
	CONSTRAINT genre_pkey PRIMARY KEY (id)
);



CREATE TABLE public.films (
	fid int8 NOT NULL,
	fname text NOT NULL,
	rdate int4 NOT NULL,
	pic text NULL DEFAULT 'https://dkhlak.com/wp-content/uploads/2017/12/23812-f3.jpg'::text,
	about text NULL,
	parentid int8 NOT NULL,
	uid int4 NOT NULL,
	rating int4 NULL DEFAULT 0,
	CONSTRAINT films_fname_rdate_parentid_key UNIQUE (fname, rdate, parentid),  
	CONSTRAINT films_pkey PRIMARY KEY (fid)
);



CREATE TABLE public.filmgenre (
	filmid int8 NOT NULL,
	genreid int4 NOT NULL,
	CONSTRAINT filmgenre_pkey PRIMARY KEY (filmid, genreid)
);



ALTER TABLE public.filmgenre ADD CONSTRAINT filmgenre_filmid_fkey FOREIGN KEY (filmid) REFERENCES public.films(fid) ON DELETE CASCADE;





CREATE TYPE gen AS ENUM (
	'Male',
	'Female');


CREATE TABLE public.filmrelatedpersons (
	id int8 NOT NULL,
	frpname text NOT NULL,
	dob date NULL,
	pic text NULL,
	gender gen,
	uid int4 NOT NULL DEFAULT 1,
	CONSTRAINT filmrelatedpersons_frpname_key UNIQUE (frpname), 
	CONSTRAINT filmrelatedpersons_pkey PRIMARY KEY (id)
);




CREATE TABLE public.personinmovie (
	id int8 NOT NULL,
	fid int8 NOT NULL,
	frpid int8 NOT NULL,
	roleid int4 NULL,                                      
	CONSTRAINT personinmovie_fid_frpid_roleid_key UNIQUE (fid, frpid, roleid),
	CONSTRAINT personinmovie_pkey PRIMARY KEY (id)
);


CREATE TABLE public.ratingtbl (
	uid int4 NOT NULL,
	fid int8 NOT NULL,
	rating int4 NULL,
	CONSTRAINT ratingtbl_pkey PRIMARY KEY (uid, fid)
);









CREATE OR REPLACE VIEW public.avgrating
AS SELECT ratingtbl.fid,
    avg(ratingtbl.rating) AS rating
   FROM ratingtbl
  GROUP BY ratingtbl.fid;




CREATE OR REPLACE VIEW public.getfilmdetail
AS SELECT t1.fid,
    t1.fname,
    t1.rdate,
    t1.pic,
    t1.about,
    t1.parentid,
    t1.uid,
    t3.id,
    t3.gname
   FROM films t1,
    filmgenre t2,
    genre t3
  WHERE t1.fid = t2.filmid AND t2.genreid = t3.id;







CREATE OR REPLACE FUNCTION public.getmax(tablee text, field text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare 
id text=0;
  BEGIN
 
EXECUTE ' select COALESCE(max(' || field || '),0)+1 as id from ' || tablee || ' 'into id;
return id;
  END;
$function$
;


CREATE OR REPLACE FUNCTION public.addfrp(namee text, dobb date, piccs text, genderr text, uidd integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
idd int8=getmax('filmrelatedpersons','id')::int8;
picc text='https://www.swindon-car-repairs.co.uk/wp-content/uploads/2016/04/unkown.jpeg';
begin
if piccs is not null then
picc=piccs;
end if;
INSERT INTO public.filmrelatedpersons
(id, frpname, dob, pic, gender,uid)
VALUES(idd, namee, DOBB::date, piccs, genderr::gen,uidd);

return 'ok';
end;
$function$
;


CREATE OR REPLACE FUNCTION public.addgenretofilms(filmid bigint, genreid integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
  BEGIN
  
INSERT INTO filmgenre
(filmid, genreid)
VALUES(filmid, genreid);
return 'ok';
  END;
$function$
;



CREATE OR REPLACE FUNCTION public.addnewfilm(fname text, rdate integer, pic text, about text, parentid bigint, uid integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
fidd int8=getmax('films','fid')::int8;
picc text='https://dkhlak.com/wp-content/uploads/2017/12/23812-f3.jpg';
begin
if pic is not null then
picc=pic;
end if;
if about is null then
about=' ';
end if;
INSERT INTO public.films 
(fid,fname,rdate,pic,about,parentid,uid)
VALUES(fidd,fname,rdate, picc::text,about, parentid , uid);
return 'ok';
end;
$function$
;




CREATE OR REPLACE FUNCTION public.addpersontomovie(fidd bigint, frpidd bigint, roleidd text, applyall text)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
childs films;
count int=0;
idd int8=0;
existedbefore int=0;
arr int[];
begin
SELECT regexp_split_to_array(roleidd, ',')::int[] into arr;
FOR i IN 1 .. array_upper(arr, 1)
 loop
select count(*) from personinmovie where fid=fidd and frpid=frpidd and roleid=arr[i]::int into count;
if(count=0)then
idd=getmax('personinmovie','id')::int8;
INSERT INTO public.personinmovie
(id, fid, frpid, roleid)
VALUES(idd, fidd, frpidd, arr[i]::int);

if(applyall='yes')then

FOR childs IN
        SELECT * FROM films p where p.parentid =fidd
    LOOP
select count(*) from personinmovie where fid=childs.fid and frpid=frpidd and roleid=arr[i]::int into count;
if(count=0)then
idd=getmax('personinmovie','id')::int8;
INSERT INTO public.personinmovie
(id, fid, frpid, roleid)
VALUES(idd, childs.fid, frpidd, arr[i]::int);
end if;
END LOOP;	


end if;


count=0;
else
existedbefore=1;
count=0;
end if;
END LOOP;
if(existedbefore=0)then
return 'ok';
else
return 'persone with some of selected role already exist';
end if;
end;
$function$
;



CREATE OR REPLACE FUNCTION public.checkperson_in_movie_delete()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare 
temprow personinmovie;
begin 
	
FOR temprow IN
        SELECT * FROM personinmovie p where frpid=old.id
    LOOP
       delete from films where fid=temprow.fid;
    END LOOP;	

return old;
end;
$function$
;



CREATE OR REPLACE FUNCTION public.checkusername(name character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
  DECLARE
result INT = 0;
BEGIN
  select count(*) from users where lower(username)=lower(name) into result;
 if(result=0)then
 return 'name is available';
else
return 'name is taken';
end if;
END;
$function$
;


CREATE OR REPLACE FUNCTION public.delete_person_role_in_movies(idd bigint)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
count int=0;
begin 
select count(*) from personinmovie where id=idd into count;
if(count=1)then
delete from personinmovie where id=idd;
return 'ok';
else
return 'there is no such record';
end if;
END;
$function$
;



CREATE OR REPLACE FUNCTION public.deletefilmtriggerfunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin 
delete from films where parentid=old.fid;
delete from filmgenre where filmid=old.fid;
delete from personinmovie where fid=old.fid;
delete from ratingtbl where fid=old.fid;
return old;
end;
$function$
;


CREATE OR REPLACE FUNCTION public.deletefrpersons(idd bigint)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
begin
delete from filmrelatedpersons  where id=idd;
return 'ok';
END;
$function$
;



CREATE OR REPLACE FUNCTION public.deletemovie(id bigint)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
BEGIN
delete from films where fid=id;
return 'ok';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.deletemovie(id bigint, uidd integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
ownerr int=0;
BEGIN
select uid from films where fid=id into ownerr;
if(ownerr=uidd)then  
delete from films where fid=id;
return 'ok';
else
return 'you can not delete this movie because you are not the owner of this record';
end if;
END;
$function$
;


CREATE OR REPLACE FUNCTION public.deleterate(uidd integer, fidd bigint)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
count int=0;
begin 
select count(*) from ratingtbl where fid=fidd and uid=uidd into count;
if(count>0)then
delete from ratingtbl  where fid=fidd and uid=uidd;
return 'rating deleted';
else
return 'you have not rated this movie yet';
end if;
END;
$function$
;


CREATE OR REPLACE FUNCTION public.deleteuser(uid integer, passwordd text)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
count int=0;
begin
select count(*) from users where id=uid and pass=passwordd into count;
if(count>0) then
delete from users  where id=uid;
return 'ok';
else
return 'You need to provide correct password for this account to delete it ';
end if;
END;
$function$
;


CREATE OR REPLACE FUNCTION public.deleteusertriggerfunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin 
delete from films where uid=old.id;

return old;
end;
$function$
;


CREATE OR REPLACE FUNCTION public.detect_cycle()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin 
	if exists(
	with recursive search_movie(parentid,path,cycle)as(
	select new.parentid,ARRAY[new.fid,new.parentid],(new.fid=new.parentid)
	from films where fid=new.parentid
	union all
	select films.parentid,path || films.parentid,films.parentid=any(path)
	from search_movie join films on fid=search_movie.parentid where not cycle)
	select 1 from search_movie where cycle limit 1
	)then 
	return null;
end if;
return new;
end;
$function$
;


CREATE OR REPLACE FUNCTION public.frpoverview(offsett bigint, limitt integer)
 RETURNS TABLE(id bigint, frpname text, dob date, pic text, gender text)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select f.id,f.frpname ,f.dob ,f.pic ,f.gender::text from filmrelatedpersons f order by f.id desc limit limitt offset offsett;
	
END
$function$
;


CREATE OR REPLACE FUNCTION public.frpsearchbykeyword(keyword text)
 RETURNS TABLE(id bigint, frpname text, dob date, pic text, gender text)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select f.id,f.frpname ,f.dob ,f.pic ,f.gender::text from filmrelatedpersons f WHERE lower(f.frpname) LIKE '%' || lower(keyword) || '%' order by f.id desc;
	
END
$function$
;


CREATE OR REPLACE FUNCTION public.getfildetail(id bigint)
 RETURNS TABLE(fid bigint, fname text, rdate integer, pic text, about text, rating integer)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select u.fid,u.fname,u.rdate,u.pic,u.about,u.rating from films u where u.fid=id;
	
END
$function$
;



CREATE OR REPLACE FUNCTION public.getfilmcatbyid(idd bigint)
 RETURNS TABLE(id integer, name character varying)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select g.id,g.gname as name from getfilmdetail g where g.fid=idd;
	
END
$function$
;


CREATE OR REPLACE FUNCTION public.getfilmid(fnamee text, rdatee integer, parentidd bigint)
 RETURNS TABLE(fid bigint)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select films.fid from films where fname=fnamee and rdate=rdatee and parentid=parentidd;
	
END
$function$
;



CREATE OR REPLACE FUNCTION public.getfilmoverview()
 RETURNS TABLE(fid bigint, fname text, rdate integer, pic text, about text, rating integer, parentid bigint)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select u.fid,u.fname,u.rdate,u.pic,u.about,u.rating,u.parentid from films u  order by fid desc;
	
END
$function$
;

CREATE OR REPLACE FUNCTION public.getfilmoverview(parent bigint)
 RETURNS TABLE(fid bigint, fname text, rdate integer, pic text, about text, rating integer)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select u.fid,u.fname,u.rdate,u.pic,u.about,u.rating from films u where u.parentid=parent order by fid desc;
	
END
$function$
;

CREATE OR REPLACE FUNCTION public.getfrpnames()
 RETURNS TABLE(id bigint, name text)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select f.id,f.frpname as name from filmrelatedpersons f;

END
$function$
;

CREATE OR REPLACE FUNCTION public.getgenre(cond integer)
 RETURNS TABLE(id integer, name character varying)
 LANGUAGE plpgsql
AS $function$
begin
	if cond is null then
	 RETURN QUERY
	 select u.id,u.gname as name from genre u;
	else
	RETURN QUERY
	 select t.id,t.gname as name from genre t where t.id=cond;
	end if;
END
$function$
;


CREATE OR REPLACE FUNCTION public.getfilms(cond bigint)
 RETURNS TABLE(fid bigint, fname text, rdate integer, pic text, about text, parentid bigint, uid integer, rating integer)
 LANGUAGE plpgsql
AS $function$
begin
	if cond is null then
	 RETURN QUERY
	 select * from films order by fname,rdate;
	else
	RETURN QUERY
	 select * from films t where t.fid=cond order by fname,rdate;
	end if;
END
$function$
;



CREATE OR REPLACE FUNCTION public.getfrpdetail(idd bigint)
 RETURNS TABLE(id bigint, frpname text, dob date, pic text, gender text, uid integer)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select u.id,u.frpname,u.dob,u.pic,u.gender::text,u.uid from filmrelatedpersons u where u.id=idd;
	
END
$function$
;


CREATE OR REPLACE FUNCTION public.getpersoninmovies(fidd bigint)
 RETURNS TABLE(id bigint, filmid bigint, personname text, filmname text, rolename character varying)
 LANGUAGE plpgsql
AS $function$
begin
	if fidd is null then
	 RETURN QUERY
	 select t4.id,t1.fid as filmid,t3.frpname as personname,t1.fname as filmname,t2.rname as rolename from films t1,roles t2,filmrelatedpersons t3,personinmovie t4
where t1.fid =t4.fid  and t2.id =t4.roleid and t3.id =t4.frpid;
	else
	RETURN QUERY
	select t4.id,t1.fid as filmid,t3.frpname as personname,t1.fname as filmname,t2.rname as rolename from films t1,roles t2,filmrelatedpersons t3,personinmovie t4
where t1.fid =t4.fid  and t2.id =t4.roleid and t3.id =t4.frpid  and t1.fid=fidd;
	end if;
end
$function$
;



CREATE OR REPLACE FUNCTION public.getroles(cond integer)
 RETURNS TABLE(id integer, name character varying)
 LANGUAGE plpgsql
AS $function$
begin
	if cond is null then
	 RETURN QUERY
	 select u.id,u.rname as name from roles u;
	else
	RETURN QUERY
	 select t.id,t.rname as name from roles t where t.id=cond;
	end if;
END
$function$
;


CREATE OR REPLACE FUNCTION public.lastrecordbyuid(tablee text, field text, uid integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare 
id text=0;
  BEGIN
 
EXECUTE 'select max(' || field || ') as id from ' || tablee || ' where uid=' ||uid ||' ' into id;
return id;
  END;
$function$
;


CREATE OR REPLACE FUNCTION public.login(name character varying, password character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
count integer=0;
begin
select count(*) from users where lower(username)=lower(name) and pass=password into count;
if count > 0 then
return (select id||','||username from users where lower(username)=lower(name) and pass=password);
else 
return -1;
end if;
end;
$function$
;


CREATE OR REPLACE FUNCTION public.partialload(offsett bigint, limitt integer)
 RETURNS TABLE(fid bigint, fname text, rdate integer, pic text, about text, rating integer)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select u.fid,u.fname,u.rdate,u.pic,u.about,u.rating from films u where parentid=0  order by fid desc limit limitt offset offsett;
	
END
$function$
;



CREATE OR REPLACE FUNCTION public.rate(uidd integer, fidd bigint, ratingg integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
count int=0;
begin 
	select count(*) from ratingtbl where fid=fidd and uid=uidd into count;
if(count>0)then
update ratingtbl  set rating=ratingg  where fid=fidd and uid=uidd;
return 'rating updated';
else
INSERT INTO public.ratingtbl
(uid, fid, rating)
VALUES(uidd, fidd, ratingg);
return 'ok';
end if;
END;
$function$
;


CREATE OR REPLACE FUNCTION public.ratingtrigfunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
 declare 
  count int=0;
 ratingg int=0;
BEGIN
        --
        -- Create a row in emp_audit to reflect the operation performed on emp,
        -- make use of the special variable TG_OP to work out the operation.
        --
        IF (TG_OP = 'INSERT') THEN
            update films  set rating =(select rating from avgrating t where t.fid=new.fid) where fid=new.fid;
            RETURN new;
        else
        
    select count(*) from avgrating t where t.fid=old.fid into count;
    if count>0 then
    select rating from avgrating t where t.fid=old.fid into ratingg;
    else ratingg=0;
    end if;
    update films  set rating=ratingg where fid=old.fid;
 RETURN old;
END IF;
END;
$function$
;



CREATE OR REPLACE FUNCTION public.register(name character varying, pass character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
 declare 
 uid int=getmax('users','id')::int;
BEGIN

insert into users(id,username,pass) values(uid,name,pass);
return 'succesfull';
  END;
$function$
;


CREATE OR REPLACE FUNCTION public.searchbykeyword(keyword text)
 RETURNS TABLE(fid bigint, fname text, rdate integer, pic text, about text, rating integer)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select u.fid,u.fname,u.rdate,u.pic,u.about,u.rating from films u  WHERE lower(u.fname) LIKE '%' || lower(keyword) || '%' or cast(u.rdate as varchar)=keyword  order by u.fid desc;
	
END
$function$
;



CREATE OR REPLACE FUNCTION public.suggestion(uidd integer, offsett bigint, limitt integer)
 RETURNS TABLE(fid bigint, fname text, rdate integer, pic text, about text, rating integer)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select u.fid,u.fname,u.rdate,u.pic,u.about,u.rating from  films u where u.fid not in(select r.fid from ratingtbl r where r.uid=uidd) order by u.fid desc limit limitt offset offsett;
	
END
$function$
;



CREATE OR REPLACE FUNCTION public.updatefilm(fidd bigint, fnamee text, rdatee integer, piccs text, aboutt text, parentidd bigint, genree text)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
arr int[];
picc text='https://dkhlak.com/wp-content/uploads/2017/12/23812-f3.jpg';
begin
if piccs is not null then
picc=piccs;
end if;
if aboutt is  null then
aboutt=' ';
end if;
update films set fname=fnamee,rdate=rdatee,pic=piccs,about=aboutt,parentid=parentidd where fid=fidd;
delete from filmgenre where filmid=fidd;

SELECT regexp_split_to_array(genree, ',')::int[] into arr;
FOR i IN 1 .. array_upper(arr, 1)
   LOOP
PERFORM  addgenretofilms(fidd,arr[i]);
   END LOOP;
return 'ok';
end;
$function$
;




CREATE OR REPLACE FUNCTION public.updatefrpesons(idd bigint, frpnamee text, dobb date, piccs text, genderr text)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
count int=0;
picc text='https://dkhlak.com/wp-content/uploads/2017/12/23812-f3.jpg';
begin
if piccs is not null then
picc=piccs;
end if;
select count(*) from filmrelatedpersons where frpname=frpnamee into count;
if(count>0) then
return 'that name is already exist';
else
update filmrelatedpersons set frpname=frpnamee,dob=dobb,pic=piccs,gender=genderr where id=idd;
return 'ok';
end if;
end;
$function$
;



CREATE OR REPLACE FUNCTION public.updateuser(name character varying, password character varying, newpass character varying, userid integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
count integer=0;
begin
select count(*) from users where id=userid and pass=password into count;
if count > 0 then
update users set username=name,pass=newpass where id=userid;
return 'ok';
else 
return -1;
end if;
end;
$function$
;




CREATE OR REPLACE FUNCTION public.watched(uidd integer)
 RETURNS TABLE(fid bigint, fname text, rdate integer, pic text, about text, rating integer)
 LANGUAGE plpgsql
AS $function$
begin
	
	 RETURN QUERY
	 select u.fid,u.fname,u.rdate,u.pic,u.about,u.rating from  films u where u.fid  in(select r.fid from ratingtbl r where r.uid=uidd) order by u.fid desc ;
	
END
$function$
;











create trigger deleteusertrigger after
delete
    on
    public.users for each row execute function deleteusertriggerfunc();


create trigger ratetrig after
insert
    or
delete
    or
update
    on
    public.ratingtbl for each row
    when ((pg_trigger_depth() = 0)) execute function ratingtrigfunc();


create trigger deletefilmtrigger after
delete
    on
    public.films for each row execute function deletefilmtriggerfunc();


create trigger prevent_cycle before
update
    on
    public.films for each row execute function detect_cycle();


create trigger deletepersontrig after
delete
    on
    public.filmrelatedpersons for each row execute function checkperson_in_movie_delete();


INSERT INTO public.users (id,username,pass) VALUES
	 (1,'daban','321'),
	 (2,'sozan','123'),
	 (3,'user3','123'),
	 (4,'user4','123'),
	 (5,'user5','123');

INSERT INTO public.genre (id,gname) VALUES
	 (1,'Drama'),
	 (2,'Action'),
	 (3,'Thriller'),
	 (4,'Comedy'),
	 (5,'Biography'),
	 (6,'Crime'),
	 (7,'Romance'),
	 (8,'Sport'),
	 (9,'Musical'),
	 (10,'War');
INSERT INTO public.genre (id,gname) VALUES
	 (11,'Horror'),
	 (12,'Documentary'),
	 (13,'Adventure'),
	 (14,'true story'),
	 (15,'fantasy'),
	 (16,'Science fiction'),
	 (17,'Mystery');


INSERT INTO public.roles (id,rname) VALUES
	 (1,'Producer'),
	 (2,'Director'),
	 (3,'Writer'),
	 (4,'Actor'),
	 (5,'SetManager'),
	 (6,'actress');


INSERT INTO public.films (fid,fname,rdate,pic,about,parentid,uid,rating) VALUES
	 (7,'the curious case of benjamin button',2008,'https://thequarantinecritics.files.wordpress.com/2020/05/benjamin-button.jpg','As a child, Daisy meets Benjamin Button who suffers from a rare ageing ailment that makes him age backwards. They keep in touch as she gets older and he turns younger.',0,1,5),
	 (1,'About time',2013,'https://i.ytimg.com/vi/7OIFdWk83no/maxresdefault.jpg','romantic comedy-drama film written and directed by Richard Curtis, and starring Domhnall Gleeson, Rachel McAdams, and Bill Nighy. The film is about a young man with the ability to time travel who tries to change his past in hopes of improving his future.',0,1,4),
	 (8,'Due date',2010,'https://m.media-amazon.com/images/M/MV5BMTU5MTgxODM3Nl5BMl5BanBnXkFtZTcwMjMxNDEwNA@@._V1_.jpg','Peter Highman must reach Los Angeles to make it in time for his child''s birth. However, he is forced to travel with Ethan, an aspiring actor, who frequently lands him in trouble.',0,1,4),
	 (9,'A Beautiful Mind',2001,'https://c8.alamy.com/comp/T2YD2B/russell-crowe-poster-a-beautiful-mind-2001-T2YD2B.jpg','ohn Nash, a brilliant but asocial mathematical genius, finds his life changing for the worse after he accepts an assignment from William Parcher.',0,1,5),
	 (10,'The Exorcism of Emily Rose',2005,'https://m.media-amazon.com/images/M/MV5BMTcxMDQzMDA1OV5BMl5BanBnXkFtZTYwNDQxMDc2._V1_.jpg','Reverend Moore performs an exorcism on a girl believed to be possessed by demons. The prosecutor argues that the girl suffered from schizophrenia, but Moore''s defence lawyer has a different opinion.',0,1,4),
	 (12,'Interstellar',2014,'https://m.media-amazon.com/images/M/MV5BZjdkOTU3MDktN2IxOS00OGEyLWFmMjktY2FiMmZkNWIyODZiXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_.jpg','When Earth becomes uninhabitable in the future, a farmer and ex-NASA pilot, Joseph Cooper, is tasked to pilot a spacecraft, along with a team of researchers, to find a new planet for humans.',0,1,5),
	 (6,'shashank redemption',1994,'https://m.media-amazon.com/images/M/MV5BNTYxOTYyMzE3NV5BMl5BanBnXkFtZTcwOTMxNDY3Mw@@._V1_.jpg','Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.',0,1,5),
	 (5,'Live Free or Die Hard',2007,'https://m.media-amazon.com/images/M/MV5BNDQxMDE1OTg4NV5BMl5BanBnXkFtZTcwMTMzOTQzMw@@._V1_.jpg','merican action-thriller film and the fourth installment in the Die Hard film series. It was directed by Len Wiseman',2,1,3),
	 (13,'Burnt',2015,'https://i2.wp.com/macguff.in/wp-content/uploads/2015/11/Burnt-Movie-Still-2.jpg','Adam Jones is a talented chef who fell from grace as a result of his arrogance. Determined to resurrect his career, he moves to London and starts working in a prestigious restaurant.',0,1,4),
	 (11,'silver linings playbook',2012,'https://i2.wp.com/the-art-of-autism.com/wp-content/uploads/2020/05/Silver-Linings-Playbook-poster.jpg?fit=950%2C594&ssl=1','After a stint in a mental institution, former teacher Pat Solitano moves back in with his parents and tries to reconcile with his ex-wife. After a stint in a mental institution, former teacher Pat Solitano moves back in with his parents and tries to reconcile with his ex-wife',0,1,4);
INSERT INTO public.films (fid,fname,rdate,pic,about,parentid,uid,rating) VALUES
	 (17,'The Gentlemen',2019,'https://saportareport.s3.amazonaws.com/wp-content/uploads/2020/01/27145322/gentlemen-poster-1.jpg','When cannabis mogul Mickey Pearson plans to sell his profitable marijuana empire following his retirement, it stimulates an array of wrongdoings in the name of greed.',0,3,4),
	 (18,'Ghosts of Girlfriends Past',2009,'https://m.media-amazon.com/images/M/MV5BMTA0Njk2NTIyMTVeQTJeQWpwZ15BbWU3MDU0MzUyMzI@._V1_.jpg','Connor, a womaniser, tries to brainwash his younger brother to not get married. However, he ends up being haunted by the ghosts of his ex-girlfriends who teach him a harsh lesson.',0,3,4),
	 (2,'Die Hard',1988,'https://dyn.media.titanbooks.com/ucCksQbH5p8HNpMIyITqHwA2e_I=/fit-in/600x600/https://media.titanbooks.com/catalog/products/DieHard_UVH.jpg','Die Hard is a 1988 American action film directed by John McTiernan and written by Jeb Stuart and Steven E. de Souza. It is based on the 1979 novel Nothing ...',0,1,4),
	 (3,'Die Hard 2',1990,'https://pisces.bbystatic.com/image2/BestBuy_US/images/products/0996/0996471_sa.jpg','American action-thriller film and the second installment in the Die Hard film series. The film was released on July 4, 1990',2,1,4),
	 (4,'Die Hard with a Vengeance',1995,'https://cdn.hmv.com/r/w-640/hmv/files/14/14146552-b3f9-4d41-8948-db5bf0aa107d.jpg','John McClane and a Harlem store owner are targeted by German terrorist Simon in New York City, where he plans to rob the Federal Reserve Building. John McClane and a Harlem store owner are targeted by German terrorist Simon in New York City, where he plans to rob the Federal Reserve Building.',2,1,4),
	 (16,'The Hangover Part III',2013,'http://oyster.ignimgs.com/wordpress/stg.ign.com/2013/05/hangover3_052213_1600.jpg',' After the bachelor party in Las Vegas two years ago, Phil, Stu, Alan, and Doug head to Thailand for Stu''s wedding. However, things go awry when Stu''s soon-to-be brother-in-law goes missing.',14,3,4),
	 (15,'The Hangover Part II',2011,'https://images.jdmagicbox.com/comp/jd_social/news/2018jul28/image-167643-kcjy8c6p4m.jpg',' The Wolfpack decides to help Alan after he faces a major crisis in his life. However, when one of them is kidnapped by a gangster in exchange for Chow, a prisoner on the run, they must find him.',14,3,4),
	 (14,'the hangover',2009,'https://www.puremovies.co.uk/wp-content/uploads/2009/12/the-hangover-puremovies.jpg',' The Hangover is a trilogy of American comedy films created by Jon Lucas and Scott Moore, and directed by Todd Phillips. All three films follow the misadventures of a quartet of friends who go on their road trip to attend a bachelor party. ',0,3,5);




INSERT INTO public.filmgenre (filmid,genreid) VALUES
	 (10,11),
	 (10,12),
	 (1,10),
	 (1,13),
	 (13,1),
	 (13,7),
	 (12,1),
	 (12,13),
	 (12,16),
	 (12,17);
INSERT INTO public.filmgenre (filmid,genreid) VALUES
	 (11,1),
	 (11,4),
	 (11,7),
	 (9,1),
	 (9,7),
	 (9,14),
	 (7,1),
	 (7,7),
	 (7,13),
	 (2,2);
INSERT INTO public.filmgenre (filmid,genreid) VALUES
	 (2,3),
	 (6,1),
	 (6,6),
	 (5,2),
	 (5,3),
	 (4,2),
	 (4,3),
	 (3,2),
	 (3,3),
	 (8,4);
INSERT INTO public.filmgenre (filmid,genreid) VALUES
	 (8,13),
	 (15,3),
	 (15,4),
	 (14,3),
	 (14,4),
	 (14,17),
	 (16,2),
	 (16,3),
	 (16,4),
	 (17,2);
INSERT INTO public.filmgenre (filmid,genreid) VALUES
	 (17,3),
	 (17,4),
	 (17,6),
	 (18,1),
	 (18,4),
	 (18,7);


INSERT INTO public.filmrelatedpersons (id,frpname,dob,pic,gender,uid) VALUES
	 (1,'Bruce Willis','1955-03-19','https://img.etimg.com/thumb/msid-46671519,width-650,imgsize-159300,,resizemode-4,quality-100/.jpg','Male'::gen,1),
	 (2,'Russell Crowe','1964-04-07','https://www.biography.com/.image/ar_1:1%2Cc_fill%2Ccs_srgb%2Cfl_progressive%2Cq_auto:good%2Cw_1200/MTE5NTU2MzE2MTkzMjYxMDY3/russell-crowe-9262435-1-402.jpg','Male'::gen,1),
	 (3,'Timothy Francis Robbins','1968-10-16','https://i.pinimg.com/originals/b7/66/30/b76630ec6474b1e89909aa4f1ffbeb04.jpg','Male'::gen,1),
	 (4,'Morgan Freeman','1937-06-01','https://media.vanityfair.com/photos/5b06ef6a016c7568e478cabf/9:16/w_747,h_1328,c_limit/Morgan-Freeman-Sexual-Harassment.jpg','Male'::gen,1),
	 (5,'Bradley Cooper','1975-01-05','https://compote.slate.com/images/c5f3ec65-a31b-46e5-84ec-1d85824f6076.jpg','Male'::gen,1),
	 (6,'Jennifer Lawrence','1990-08-15','https://cdn.headlinesoftoday.com/wp-content/uploads/2020/07/Jennifer-Lawrence-1024x1024.jpg','Female'::gen,1),
	 (7,'Brad Pitt','1963-12-18','https://cdn.gettotext.com/wp-content/uploads/2021/12/Brad-Pitt-Dating-Problems.jpg','Male'::gen,1),
	 (8,'Cate Blanchett','1969-07-14','https://gregreport.com/wp-content/uploads/2020/07/cate-blanchett-lingerie.jpg','Female'::gen,1),
	 (9,'Jennifer Connelly','1970-12-12','https://www1.pictures.stylebistro.com/mp/cb442NHjyDyl.jpg','Female'::gen,1),
	 (10,'Rachel McAdams','1978-11-17','https://www.alohacriticon.com/wp-content/uploads/2016/10/rachel-mcadams-foto.jpg','Female'::gen,1);
INSERT INTO public.filmrelatedpersons (id,frpname,dob,pic,gender,uid) VALUES
	 (11,'Anne Hathaway','1982-11-12','https://cdn.artphotolimited.com/images/58bd704f04799b000f623d31/700x700/anne-hathaway.jpg','Female'::gen,1),
	 (13,'Robert Downey Jr.','1965-04-04','https://upload.wikimedia.org/wikipedia/commons/a/a2/Robert_Downey%2C_Jr._SDCC_2014_%28cropped%29.jpg','Male'::gen,1),
	 (14,'Daniel Brühl','1978-06-16','https://www.berlinale.de/media/nrwd/bilder/2015/starportraits2015/2015-02-04-9759-0198-daniel-bru%CC%88hl_IMG_x900.jpg','Male'::gen,1),
	 (12,'Zach Galifianakis','1969-10-01','https://www.themoviedb.org/t/p/original/qsDfoUlRnXHUiqZeBPWHzmgmKGX.jpg','Male'::gen,1),
	 (15,'Matthew McConaughey','1969-11-04','https://parade.com/wp-content/uploads/2020/10/Matthew-McConaughey-FTR-1024x640.jpg','Male'::gen,1),
	 (16,'Bill Nighy','1949-12-12','https://blossomeye.com/wp-content/uploads/2021/03/Bill-Nighys-Bio-Age-Dating-House-Net-Worth-Life-Height-Awards.jpg','Male'::gen,1),
	 (17,'Domhnall Gleeson','1983-05-12','https://pbs.twimg.com/profile_images/1208145068110045185/UOjS0UZ5_400x400.jpg','Male'::gen,1);




INSERT INTO public.personinmovie (id,fid,frpid,roleid) VALUES
	 (2,4,1,5),
	 (3,3,1,3),
	 (4,5,1,8),
	 (5,13,5,4),
	 (6,13,14,2),
	 (7,12,15,3),
	 (8,12,11,2),
	 (9,11,6,3),
	 (10,11,5,4),
	 (11,11,5,6);
INSERT INTO public.personinmovie (id,fid,frpid,roleid) VALUES
	 (12,9,2,8),
	 (13,8,12,4),
	 (14,8,13,4),
	 (16,6,3,5),
	 (17,6,4,3),
	 (19,7,8,1),
	 (21,1,10,1),
	 (22,1,10,2),
	 (23,1,16,3),
	 (24,1,17,3);
INSERT INTO public.personinmovie (id,fid,frpid,roleid) VALUES
	 (25,9,2,4),
	 (26,9,9,6),
	 (27,7,7,4),
	 (28,6,3,4),
	 (29,2,1,4),
	 (30,5,1,4),
	 (31,4,1,4),
	 (32,3,1,4),
	 (33,4,1,3),
	 (34,14,5,4);
INSERT INTO public.personinmovie (id,fid,frpid,roleid) VALUES
	 (35,15,5,4),
	 (36,16,5,4),
	 (37,14,12,4),
	 (38,15,12,4),
	 (39,16,12,4),
	 (40,14,12,3),
	 (41,17,15,2),
	 (42,17,15,4),
	 (43,18,15,4);


INSERT INTO public.ratingtbl (uid,fid,rating) VALUES
	 (1,11,4),
	 (1,10,3),
	 (1,9,5),
	 (1,8,4),
	 (1,7,5),
	 (1,6,5),
	 (1,5,3),
	 (1,12,5),
	 (1,1,4),
	 (1,4,3);
INSERT INTO public.ratingtbl (uid,fid,rating) VALUES
	 (1,3,3),
	 (1,2,3),
	 (1,13,3),
	 (2,13,4),
	 (2,9,5),
	 (2,2,4),
	 (2,1,4),
	 (2,7,5),
	 (2,10,3),
	 (3,3,4);
INSERT INTO public.ratingtbl (uid,fid,rating) VALUES
	 (3,10,5),
	 (3,6,4),
	 (3,11,3),
	 (1,18,3),
	 (1,17,4),
	 (1,16,4),
	 (1,15,4),
	 (1,14,5),
	 (3,14,4),
	 (3,17,3);
INSERT INTO public.ratingtbl (uid,fid,rating) VALUES
	 (4,1,5),
	 (4,8,3),
	 (4,9,4),
	 (4,10,3),
	 (4,18,4),
	 (4,4,4);

