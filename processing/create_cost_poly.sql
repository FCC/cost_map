--create_cost_poly
--mike byrne
--july 12, 2012
--create the cost landscape polygons
--with 4 categories of cost
--has st_transform and st_simplify in it
--code structure for myvalue
--1 - un-populated
--2 - served by cable
--3 - above 600 and telco served
--4 - above 600 and telco unserved
--5 - 300 to 600 and telco served
--6 - 300 to 600 and telco unserved
--7 - 150 to 300 and telco served
--8 - 150 to 300 and telco unserved
--9 - 75 to 150 and telco served
--10 - 75 to 150 and telco unserved
--11 - less than 75 and telco served
--12 - less than 75 and telco unserved
--13 - water

drop table analysis.cost_fttp_poly_5;
create table analysis.cost_fttp_poly_5
(
  geom geometry,
  state_fips character varying(2),
  myvalue character varying(2),
  gid serial not null,
  CONSTRAINT analysis_cost_fttp_poly_5_pkey PRIMARY KEY (gid),
  CONSTRAINT enforce_dims_geom CHECK (st_ndims(geom) = 2)
)
WITH (
  OIDS=true
);
ALTER TABLE analysis.cost_fttp_poly_5 OWNER TO postgres;
COMMENT on TABLE analysis.cost_fttp_poly_5 is 'created on 07/15/12 with 5 categories for my value; --1 - un-populated--2 - served by cable--3 - above 600 and telco served--4 - above 600 and telco unserved--5 - 300 to 600 and telco served--6 - 300 to 600 and telco unserved--7 - 150 to 300 and telco served--8 - 150 to 300 and telco unserved--9 - 75 to 150 and telco served--10 - 75 to 150 and telco unserved--11 - less than 75 and telco served--12 - less than 75 and telco unserved--13 - water';

-- Index: analysis_cost_fttp_poly_5_gid
-- DROP INDEX analysis_cost_fttp_poly_5_gid;
CREATE INDEX analysis_cost_fttp_poly_5_gid
  ON analysis.cost_fttp_poly_5
  USING btree
  (gid);
-- Index: analysis.analysis_cost_fttp_poly_5_geom_gist
-- DROP INDEX analysis_cost_fttp_poly_5_geom_gist;
CREATE INDEX analysis_cost_fttp_poly_5_geom_gist
  ON analysis.cost_fttp_poly_5
  USING gist
  (geom);

 
--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_01;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '01' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '01' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '01' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '01' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '01' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '01' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '01' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '01' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '01' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '01' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '01' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_02;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '02' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '02' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '02' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '02' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '02' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '02' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '02' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '02' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '02' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '02' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '02' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_04;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '04' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '04' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '04' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '04' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '04' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '04' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '04' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '04' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '04' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '04' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '04' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_05;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '05' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '05' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '05' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '05' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '05' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '05' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '05' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '05' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '05' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '05' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '05' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_06;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '06' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '06' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '06' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '06' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '06' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '06' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '06' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '06' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '06' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '06' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '06' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_08;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '08' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '08' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '08' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '08' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '08' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '08' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '08' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '08' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '08' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '08' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '08' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_09;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '09' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '09' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '09' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '09' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '09' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '09' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '09' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '09' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '09' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '09' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '09' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_10;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '10' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '10' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '10' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '10' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '10' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '10' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '10' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '10' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '10' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '10' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '10' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_11;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '11' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '11' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '11' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '11' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '11' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '11' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '11' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '11' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '11' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '11' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '11' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_12;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '12' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '12' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '12' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '12' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '12' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '12' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '12' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '12' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '12' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '12' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '12' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_13;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '13' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '13' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '13' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '13' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '13' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '13' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '13' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '13' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '13' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '13' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '13' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_15;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '15' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '15' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '15' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '15' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '15' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '15' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '15' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '15' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '15' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '15' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '15' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_16;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '16' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '16' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '16' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '16' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '16' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '16' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '16' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '16' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '16' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '16' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '16' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_17;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '17' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '17' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '17' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '17' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '17' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '17' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '17' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '17' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '17' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '17' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '17' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_18;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '18' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '18' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '18' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '18' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '18' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '18' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '18' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '18' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '18' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '18' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '18' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_19;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '19' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '19' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '19' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '19' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '19' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '19' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '19' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '19' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '19' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '19' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '19' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_20;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '20' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '20' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '20' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '20' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '20' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '20' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '20' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '20' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '20' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '20' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '20' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_21;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '21' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '21' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '21' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '21' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '21' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '21' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '21' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '21' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '21' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '21' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '21' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_22;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '22' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '22' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '22' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '22' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '22' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '22' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '22' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '22' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '22' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '22' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '22' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_23;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '23' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '23' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '23' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '23' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '23' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '23' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '23' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '23' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '23' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '23' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '23' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_24;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '24' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '24' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '24' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '24' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '24' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '24' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '24' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '24' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '24' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '24' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '24' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_25;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '25' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '25' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '25' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '25' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '25' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '25' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '25' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '25' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '25' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '25' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '25' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_26;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '26' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '26' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '26' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '26' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '26' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '26' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '26' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '26' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '26' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '26' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '26' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_27;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '27' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '27' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '27' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '27' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '27' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '27' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '27' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '27' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '27' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '27' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '27' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_28;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '28' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '28' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '28' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '28' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '28' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '28' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '28' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '28' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '28' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '28' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '28' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_29;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '29' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '29' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '29' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '29' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '29' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '29' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '29' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '29' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '29' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '29' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '29' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_30;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '30' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '30' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '30' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '30' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '30' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '30' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '30' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '30' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '30' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '30' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '30' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_31;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '31' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '31' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '31' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '31' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '31' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '31' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '31' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '31' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '31' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '31' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '31' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_32;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '32' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '32' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '32' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '32' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '32' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '32' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '32' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '32' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '32' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '32' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '32' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_33;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '33' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '33' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '33' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '33' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '33' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '33' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '33' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '33' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '33' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '33' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '33' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_34;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '34' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '34' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '34' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '34' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '34' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '34' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '34' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '34' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '34' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '34' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '34' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_35;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '35' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '35' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '35' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '35' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '35' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '35' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '35' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '35' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '35' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '35' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '35' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_36;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '36' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '36' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '36' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '36' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '36' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '36' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '36' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '36' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '36' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '36' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '36' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_37;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '37' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '37' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '37' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '37' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '37' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '37' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '37' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '37' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '37' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '37' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '37' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_38;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '38' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '38' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '38' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '38' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '38' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '38' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '38' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '38' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '38' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '38' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '38' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_39;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '39' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '39' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '39' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '39' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '39' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '39' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '39' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '39' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '39' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '39' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '39' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_40;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '40' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '40' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '40' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '40' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '40' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '40' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '40' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '40' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '40' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '40' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '40' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_41;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '41' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '41' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '41' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '41' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '41' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '41' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '41' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '41' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '41' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '41' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '41' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_42;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '42' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '42' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '42' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '42' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '42' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '42' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '42' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '42' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '42' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '42' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '42' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_44;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '44' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '44' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '44' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '44' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '44' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '44' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '44' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '44' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '44' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '44' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '44' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_45;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '45' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '45' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '45' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '45' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '45' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '45' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '45' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '45' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '45' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '45' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '45' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_46;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '46' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '46' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '46' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '46' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '46' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '46' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '46' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '46' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '46' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '46' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '46' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_47;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '47' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '47' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '47' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '47' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '47' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '47' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '47' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '47' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '47' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '47' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '47' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_48;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '48' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '48' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '48' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '48' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '48' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '48' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '48' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '48' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '48' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '48' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '48' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_49;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '49' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '49' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '49' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '49' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '49' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '49' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '49' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '49' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '49' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '49' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '49' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_50;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '50' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '50' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '50' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '50' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '50' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '50' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '50' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '50' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '50' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '50' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '50' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_51;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '51' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '51' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '51' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '51' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '51' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '51' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '51' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '51' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '51' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '51' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '51' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_53;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '53' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '53' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '53' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '53' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '53' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '53' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '53' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '53' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '53' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '53' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '53' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_54;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '54' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '54' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '54' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '54' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '54' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '54' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '54' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '54' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '54' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '54' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '54' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_55;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '55' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '55' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '55' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '55' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '55' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '55' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '55' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '55' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '55' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '55' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '55' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_56;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '56' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '56' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '56' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '56' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '56' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '56' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '56' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '56' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '56' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '56' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '56' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_60;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '60' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '60' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '60' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '60' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '60' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '60' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '60' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '60' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '60' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '60' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '60' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_66;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '66' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '66' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '66' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '66' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '66' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '66' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '66' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '66' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '66' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '66' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '66' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_69;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '69' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '69' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '69' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '69' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '69' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '69' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '69' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '69' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '69' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '69' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '69' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_72;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '72' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '72' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '72' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '72' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '72' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '72' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '72' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '72' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '72' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '72' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '72' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************

--*******************************************
drop table analysis.working;
create table analysis.working as
  select * from census2009.block_78;
alter table analysis.working
  add column myvalue numeric;
update analysis.working
  set myvalue = '0';
update analysis.working
  set myvalue = '2'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '78' and
    cableserved = 'Served';
update analysis.working
  set myvalue = '3'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '78' and
    costperactivesub > 600 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '4'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '78' and
    costperactivesub > 600 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '5'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '78' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '6'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '78' and
    costperactivesub <= 600 and costperactivesub > 300 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '7'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '78' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '8'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '78' and
    costperactivesub <=300 and costperactivesub > 150 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '9'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '78' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '10'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '78' and
    costperactivesub <=150 and costperactivesub > 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '11'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '78' and
    costperactivesub <= 75 and
    telcolserved = 'Served' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '12'
  from analysis.cq_fttp
  where working.geoid09=cq_fttp.fullfipsid and
    substr(fullfipsid,1,2) = '78' and
    costperactivesub <= 75 and
    telcolserved = 'Unserved' and cableserved = 'Unserved';
update analysis.working
  set myvalue = '1'
  where myvalue = '0';
update analysis.working
  set myvalue = '13'
  where awater > aland;
--dissolve into
insert into analysis.cost_fttp_poly_5
  select st_simplify(st_union(st_transform(geom, 900913)),5) as geom,
    statefp00 as state_fips, myvalue
  from analysis.working
  group by myvalue, state_fips;
--*******************************************
