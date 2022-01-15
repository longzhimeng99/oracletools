#/bin/bash

# Oracle daily management tools -- by Firsouler


# -- oratf version info
if [ "$1" = "ver" ]; then
echo -e "
#  This tool was written by Firsouler, if you have any questions, please contact us.
#  Copyright © 2011. Firoulser Email:longzhimeng99@sina.com
#  2022-01-11 : oratf 1.0   Initial version
#  2022-01-14 : oratf 1.1   add support pdb mode
#  2022-01-15 : oratf 1.2   add support cdb mode,check all pdb info

"
exit 0
fi

# set login DB user
DBUSER='/ as sysdba'
# Initialize connection pdb parameters
conn_pdb="set lines 200"

# get DB version
dbver=`sqlplus -s /nolog <<EOF
connect $DBUSER
set echo off underline off
set feedback off
set heading off
select substr(version,1,2) from product_component_version where PRODUCT like '%Database%' and rownum<=1;
EOF
`
# Get if it's cdb mode
mcdb=`sqlplus -s /nolog <<EOF
connect $DBUSER
set echo off underline off
set feedback off
set heading off
select cdb from v\\$database;
EOF
`

# If the file exists, it takes effect. You can connect to pdb mode
if [ -f "/tmp/.oratf_source89" ];then
source /tmp/.oratf_source89
fi

# If pdb is available, set pdb mode
if [ "$1" = "pdb" ];then
  if [ $dbver -lt 12 ]; then
      echo  " Current database version is too low. You can [./oratf dbver] check"
      exit 0
  fi
  if [ $mcdb = "NO" ]; then
    echo  " Current database is not CDB mode. Please check again"
    exit 0
  fi
  if [[ "$2" = "setname" && "$3" = "" ]];then
    echo "Please set pdb name"
    exit 0
  #enter pdbname
  elif [ -n "$3" ]; then
   pdbname=$3
   echo -e "#For temporary connection to pdb mode" >> /tmp/.oratf_source89
   echo -e "export conn_pdb=\"alter session set container=$pdbname;\"" >> /tmp/.oratf_source89
   source /tmp/.oratf_source89
   echo "Currently connected to pdb: $pdbname"
   # get pdb info
   sqlplus -s /nolog <<EOF
set feedback off
connect $DBUSER
$conn_pdb
show pdbs
EOF
  exit 0
  fi
  # Cancel pdb setting
  if  [ "$2" = "unset" ];then
    if [ -f "/tmp/.oratf_source89" ];then
     rm /tmp/.oratf_source89
     echo "The pdb setting has been removed!"
    else
    echo "The pdb setting has been removed!"
    fi
  exit 0
  fi
  
  # Tip Message
  echo -e "You can run [./oratf pdb setname pdbname ]  Specify pdb.
  And check end,you must run [./oratf pdb unset ]  cancel pdb settings."

# When parameter pdb, all pdb will be displayed by default
sqlplus -s /nolog <<EOF
set feedback off
connect $DBUSER
$conn_pdb
set lines 200 pages 999
col name for a20
col open_mode for a16
col RESTRICTED for a10
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
select con_id,name,open_mode,RESTRICTED,to_char(open_time,'yyyy/mm/dd hh24:mi:ss') open_time,
to_char(creation_time,'yyyy/mm/dd hh24:mi:ss') creation_time from v\$pdbs;
EOF
  exit 0
fi

# Parameter Description
command_help()
{
echo -e "

   --> Oracle default uses [/ as sysdba],if you want change, please modify [DBUSER] <--

Command Reference : oratf key_value [parameter1] [parameter2]

   Keys List:
     - alert [days] [Search content]                  Display alertlog,default 1 day and display all content
     - asm                                            Display asm diskgroup usage info
     - arch                                           Display arch info
     - archsize                                       Display arch size
     - awr [begin snap] [end snap]                    Exp awr report
     - awrsql [begin time] [end time]                 Display sql consumption resources in time period
     - ash [begin time] [end time]                    Exp ash report
     - cdb [parameter]                                Display cdb all pdb info, For detailed information, execute [./oratf cdb]
     - dbf [tbs]                                      Default display all datafiles ,[tbs] specify tablespace
     - dbinfo                                         Dsiplay Oracle database base info
     - dbver                                          Display Oracle DB version info
     - dbtime [day]                                   Display DB time, Default display 1 days
     - event                                          Display current wait event info
     - event_ash [mins]                               Display wait event history, default last 30min
     - event_sql                                      Display wait event Related sql info
     - ipconunt [begin time] [end time] [ipaddr]      Statistics of ip connections during the time period,ipaddr can specify              
     - obj_lock                                       Display object lock
     - osstat                                         Display os cpu/memory info
     - param [parameter name]                         Display DB parameter info
     - pdb [setname] [pdbname]                        Specify pdb, check related content
     - pga                                            Display pga advice info
     - pgause                                         Display size used by pga
     - pgasql [size] mb                               Display use pga much sql,default greater than [100]M
     - profile                                        Display db profiles resource info
     - psu                                            Display DB psu info
     - rman                                           Display rman backup jobs info
     - rowlock                                        Display row lock info
     - sga                                            Display sga advice info
     - sgac                                           Display sga component info
     - sidsql                                         Usage sid check sql info
     - sqlid [sqlid]                                  Display check sqlid info
     - sql_explain                                    Display sql exec plan
     - sqlid_plan [sqlid]                             Display sql Execution Plan in awr
     - sqltype   [mins]                               Show sql operation type , default within 30 minutes
     - tbs                                            Tablespace usage info
     - tbsize [owner] [tbname]                        Check table size
     - tbinfo [owner] [tbname]                        Check table size
     - trans                                          Display current run transactions
     - topsql [sort by type]                          Dsiplay v$sqlare top 20 sql,Default ELAPSED_TIME sort
     - ver                                            Display oratf tools version info
     - user                                           Display DB User info
     - usersize                                       Display DB User size
     

notice : The currently connected db instance is `echo -e "\033[31m $ORACLE_SID \033[0m"`
If your DB is cdb mode, you can use pdb mode [./oratf pdb ] Or use [./oratf cdb] to check all pdb.
"
}

###### Specific commands  

# -- oracle version info
if [ "$1" = "dbver" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
select BANNER from v\$version;
EOF
exit 0
fi

# -- oracle dbinfo
if [ "$1" = "dbinfo" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | '
set lines 200 pages 99
col PLATFORM_NAME for a20
col FORCE_LOG for a9
prompt
prompt db info :
select name,
to_char(created,'yyyy-mm-dd') db_created,
LOG_MODE,
OPEN_MODE,
FORCE_LOGGING FORCE_LOG,
PLATFORM_NAME,
supplemental_log_data_min,supplemental_log_data_all,flashback_on,
(select round(sum(bytes/1024/1024/1024),2) from dba_segments) as db_size_GB 
from v\$database;
prompt
prompt instance info :
col host_name for a15
select INSTANCE_NUMBER,instance_name,host_name,to_char(startup_time,'yyyy/mm/dd hh24:mi:ss') startup_time from gv\$instance;
EOF
exit 0
fi

# -- oracle sga advice
if [ "$1" = "sga" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | '
set lines 200
set pages 999
select * from v\$sga_target_advice;
EOF
exit 0
fi

# -- oracle sga components info
if [ "$1" = "sgac" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | '
set lines 200
set pages 999
select component,round(current_size/1024/1024,2) current_size_mb,round(min_size/1024/1024,2) min_size_mb
,round(max_size/1024/1024,2) max_size_mb from v\$sga_dynamic_components order by 2 desc;
EOF
exit 0
fi

# -- oracle pga advice
if [ "$1" = "pga" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | '
set lines 200
set pages 999
select * from v\$pga_target_advice;
EOF
exit 0
fi

# -- oracle parameter
if [ "$1" = "parm" ]; then
   parm=$2
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | '
set lines 200
set pages 999
show parameter $parm;
EOF
exit 0
fi

# -- oracle pga useage
if [ "$1" = "pgause" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | '
set lines 200
set pages 999
select trunc(sum(PGA_ALLOC_MEM)/1024/1024/1024,2) as use_gb,count(*) from v\$process;
EOF
exit 0
fi

# -- Use pga much sql 
if [ "$1" = "pgasql" ]; then
  if [ "$2" = "" ];then
    sizes=100
  else
    sizes=$2
  fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | '
set lines 200
set pages 999
col MACHINE for a10
col PROGRAM for a28
col USERNAME for a15
select s.inst_id,s.sid, s.serial#, s.username, s.machine, s.program,s.process, s.sql_id,
round(p.pga_alloc_mem/1048576,2) size_m, p.spid from gv\$session s, gv\$process p where s.paddr=p.addr and s.inst_id=p.inst_id
and p.pga_alloc_mem>$sizes*1024*1024 order by 8 desc;
EOF
exit 0
fi

# -- oracle current wait event
if [ "$1" = "event" ]; then
  while :
  do
  clear
  echo "Wait event to refresh once every 5 seconds. Please enter [Ctrl + C]:"
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | ' 
set lines 200
col event for a40
select inst_id,SQL_ID,event,count(1) from gv\$session where wait_class#<> 6 
group by inst_id,SQL_ID,event order by 1,3;
EOF
sleep 5
done
exit 0
fi

# -- oracle current wait event
if [ "$1" = "event_ash" ]; then
  if [ "$2" = "" ]; then
    echo -e "
    Default last 30min, you can enter other integer value"
    mins=30
  else
    mins=$2
  fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | ' 
set lines 200 pages 999
col event for a40
prompt
prompt You can exec './oratf event_sql' view sql info
SELECT NVL(a.event, 'ON CPU') AS event,
       COUNT(*) AS total_wait_time
FROM   v\$active_session_history a
WHERE  a.sample_time > SYSDATE - $mins/(24*60)
GROUP BY a.event
ORDER BY total_wait_time DESC;
EOF
exit 0
fi

# -- oracle long transaction
if [ "$1" = "trans" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | ' 
set lines 999
col PHY_IO for 99999999
col NAME for a20
col MACHINE for a15
col username for a15
col PROGRAM for a28
col spid for a12
select gt.inst_id,gs.sid,gs.serial#,gp.spid,gs.USERNAME,gs.MACHINE,gs.PROGRAM,gt.status,gt.start_time,gt.LOG_IO,gt.PHY_IO
from gv\$transaction gt,gv\$session gs ,gv\$process gp 
where gs.saddr=SES_ADDR and gs.paddr=gp.addr order by START_TIME;
EOF
exit 0
fi

# -- oracle object lock info
if [ "$1" = "obj_lock" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | ' 
set lines 999 pages 999
col username for a15
col owner for a15
col object_name for a20
col machine for a20
col program for a30
col LOCK_LEVEL for a10
SELECT /*+ rule */ s.inst_id,s.username,
decode(l.type,'TM','TABLE LOCK',
'TX','ROW LOCK',
NULL) LOCK_LEVEL,
o.owner,o.object_name,o.object_type,s.sid,s.serial#,s.machine,s.program
FROM gv\$session s,gv\$lock l,dba_objects o WHERE l.sid = s.sid and s.inst_id=l.inst_id
AND l.id1 = o.object_id(+) AND s.username is NOT Null;
EOF
exit 0
fi

# -- oracle asm diskkgroup
if [ "$1" = "asm" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | ' 
col name format a15
set lines 200
with  temp_asm as (select name,trunc(free_mb/1024,2) free_gb,
trunc(total_mb/1024,2) total_gb,
trunc(REQUIRED_MIRROR_FREE_MB/1024,2) req_free_gb,
trunc(USABLE_FILE_MB/1024,2) uf_gb,type,state from v\$asm_diskgroup)
select * from (
select t.*,
trunc((total_gb-free_gb)/total_gb*100,2) as used_percent 
from temp_asm t
where type='EXTERN' 
union all
select t.*,
trunc(((total_gb-free_gb)/2)/((total_gb-req_free_gb)/2)*100,2) as used_percent 
from temp_asm t 
where type='NORMAL' 
union all
select t.*,
trunc(((total_gb-free_gb)/3)/((total_gb-req_free_gb)/3)*100,2) as used_percent 
from temp_asm t 
where type='HIGH')
order by used_percent desc;
EOF
exit 0
fi

# tablespace usage info
if [ "$1" = "tbs" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | ' 
col tablespace_name for a30
set linesize 150 pagesize 500
select f.tablespace_name tablespace_name,
round((d.sumbytes/1024/1024/1024),2) total_without_extend_GB,
round(((d.sumbytes+d.extend_bytes)/1024/1024/1024),2) total_with_extend_GB,
round((f.sumbytes+d.Extend_bytes)/1024/1024/1024,2) free_with_extend_GB,
round((d.sumbytes-f.sumbytes)/1024/1024/1024,2) used_GB,
round((d.sumbytes-f.sumbytes)*100/(d.sumbytes+d.extend_bytes),2) used_percent_with_extend
from (select tablespace_name,sum(bytes) sumbytes from dba_free_space group by tablespace_name) f, 
(select tablespace_name,sum(aa.bytes) sumbytes,sum(aa.extend_bytes) extend_bytes from
 (select  nvl(case  when autoextensible ='YES' then (case when (maxbytes-bytes)>=0 then (maxbytes-bytes) end) end,0) Extend_bytes
,tablespace_name,bytes  from dba_data_files) aa group by tablespace_name) d
where f.tablespace_name= d.tablespace_name 
order by  used_percent_with_extend desc;
EOF
exit 0
fi

# -- datafile info
if [ "$1" = "dbf" ]; then
   if [ "$2" = "" ]; then
      tbs=""
   else
      tbs=$2
   fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
set lines 200 pages 999
col file_name format a55
col tablespace_name for a25
col fid for 9999
select d.file_id fid,d.tablespace_name,d.file_name,round(d.bytes/1024/1024/1024,2) as "bytes(Gb)",
d.status,d.autoextensible,f.creation_time  
from dba_data_files d,v\$datafile f where d.file_id=f.file# 
and d.tablespace_name like upper('%$tbs%')  order by f.creation_time;
EOF
exit 0
fi

# -- oracle user info
if [ "$1" = "user" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | ' 
set pagesize 999
set linesize 150
col username for a25
col ACCOUNT_STATUS for a20
col DEFAULT_TABLESPACE for a20
col PROFILE for a20
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
select username,ACCOUNT_STATUS,DEFAULT_TABLESPACE,PROFILE,CREATED,EXPIRY_DATE
 from dba_users order by created;
EOF
exit 0
fi

# -- oracle user size info
if [ "$1" = "usersize" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set colsep ' | '
select * from (select owner,segment_type,segment_type_gb,
sum(segment_type_gb) over (partition by t.owner) as user_sizeGB from
(select s.owner,segment_type,
round(sum(s.bytes/1024/1024/1024),2) segment_type_gb
from dba_segments s group by s.owner,s.segment_type) t 
order by 4 desc)
pivot
(sum(segment_type_gb) for segment_type in ('TABLE' as TABLES,'INDEX' as INDEXS,'LOBSEGMENT' as LOBSEGMENTS,
'LOB PARTITION' as LOB_PARTITIONS,'TABLE PARTITION' as TABLE_PARTITIONS,
'TABLE SUBPARTITION' as TABLE_SUBPARTITIONS,
'INDEX PARTITION' as INDEX_PARTITIONS,'LOBINDEX' as LOBINDEXS,'ROLLBACK' as ROLLBACKS)) pt 
order by USER_SIZEGB desc;
EOF
exit 0
fi

# -- Table size
if [ "$1" = "tbsize" ]; then
   if [[ "$2" = "" || "$3" = "" ]]; then
       echo -e "Please enter user name and table name
         eg: ./oratf tbsize scott emp"
       exit 0
   else
     ownername=$2
     tbname=$3
   fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
SELECT
 (SELECT round(SUM(S.BYTES/1024/1024),2)
  FROM DBA_SEGMENTS S
  WHERE S.OWNER = UPPER('$ownername') AND
       (S.SEGMENT_NAME = UPPER('$tbname'))) +
 (SELECT nvl(round(SUM(S.BYTES/1024/1024),2),0) 
  FROM DBA_SEGMENTS S, DBA_LOBS L
  WHERE S.OWNER = UPPER('$ownername') AND
       (L.SEGMENT_NAME = S.SEGMENT_NAME AND L.TABLE_NAME = UPPER('$tbname') AND L.OWNER = UPPER('$ownername'))) +
 (SELECT  nvl(round(SUM(S.BYTES/1024/1024),2),0)
  FROM DBA_SEGMENTS S, DBA_INDEXES I
  WHERE S.OWNER = UPPER('$ownername') AND
       (I.INDEX_NAME = S.SEGMENT_NAME AND I.TABLE_NAME = UPPER('$tbname') AND INDEX_TYPE = 'LOB' AND I.OWNER = UPPER('$ownername')))
  "TOTAL TABLE SIZE(MB)"
FROM DUAL;
EOF
exit 0
fi

# -- Table info
if [ "$1" = "tbinfo" ]; then
   if [[ "$2" = "" || "$3" = "" ]]; then
       echo -e "Please enter user name and table name
         eg: ./oratf tbinfo scott emp"
       exit 0
   else
     ownername=$2
     tbname=$3
   fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
--set colsep ' | '
prompt
prompt table base info:
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
col TABLE_NAME for a20
col TABLESPACE_NAME for a20
select o.OBJECT_ID OBJ_ID,o.DATA_OBJECT_ID DATA_OBJ_ID,t.table_name,o.OBJECT_TYPE,t.TABLESPACE_NAME,t.PCT_FREE,
t.LOGGING,t.LAST_ANALYZED,o.CREATED,o.LAST_DDL_TIME
from dba_tables t,dba_objects o where t.table_name=o.object_name
and t.owner=o.owner and t.table_name=upper('$tbname') and t.owner=upper('$ownername');

prompt
prompt table cloumn info :
col data_type for a24
select owner,table_name,column_name,data_type from dba_tab_columns t 
where  t.table_name=upper('$tbname') and t.owner=upper('$ownername');

prompt
prompt table index info:
col DEGREE for a2
select i.table_name,i.index_name,i.INDEX_TYPE,i.LOGGING,i.BLEVEL,i.LAST_ANALYZED,i.DEGREE,o.CREATED 
from dba_indexes i,dba_objects o 
where i.index_name=o.object_name and i.owner=o.owner 
and  i.table_name=upper('$tbname') and i.table_owner=upper('$ownername');

prompt
prompt table index cloumn info :
col COLUMN_NAME for a15
select table_name,index_name,COLUMN_NAME from dba_ind_columns i 
where  i.table_name=upper('$tbname') and i.table_owner=upper('$ownername')
order by index_name;
EOF
exit 0
fi

# -- dbtime
if [ "$1" = "dbtime" ]; then
   echo ""
   echo "Default display 1 day dbtime info"
   if [ "$2" = "" ]; then
     days=1
   else
     days=$2
   fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set colsep ' | '
     select snap_id,snap_time,
            to_char(round(DB_time/1000000/60,2),'fm999999900.009') as  DB_time,
            to_char(round(TIME_Elapsed/60,2), 'fm999999900.009') AS  Elapsed_Time
            from
     (
       select m.snap_id,m.instance_number,  to_char(shot.end_interval_time,'mm-dd hh24:mi') as  snap_time,
       stat_name,
       nvl(value-lag(value) over (partition by stat_name,shot.startup_time order by  m.snap_id),0) value,
       nvl(EXTRACT(DAY     FROM  shot.end_interval_time -  lag(end_interval_time)  over (partition by stat_name  order by m.snap_id ) ) * 86400 +  
       EXTRACT(hour    FROM  shot.end_interval_time -  lag(end_interval_time)  over (partition by stat_name  order by m.snap_id ) ) * 3600 +
       EXTRACT(MINUTE  FROM  shot.end_interval_time -  lag(end_interval_time)  over (partition by stat_name  order by m.snap_id ) ) * 60 +
       EXTRACT(SECOND  FROM  shot.end_interval_time -  lag(end_interval_time)  over (partition by stat_name  order by m.snap_id ) ) ,3600 )as TIME_Elapsed
       from dba_hist_sys_time_model m ,dba_hist_snapshot  shot ,v\$instance inst
       where m.snap_id=shot.snap_id
       and m.instance_number=inst.instance_number
       and m.instance_number=shot.instance_number
       and stat_name in ('DB time','DB CPU')
	   and shot.end_interval_time >= sysdate - $days
     )
     pivot (
          sum(value) for stat_name in ('DB time' AS DB_time,'DB CPU' as DB_CPU)
          )
     order by snap_id;
EOF
exit 0
fi

# -- row lock info
if [ "$1" = "rowlock" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
col lock_tree for a15
with lk as (select blocking_instance||'.'||blocking_session blocker, inst_id||'.'||sid waiter   
               from gv\$session   
                where blocking_instance is not null   
                  and blocking_session is not null) 
    select lpad('  ',2*(level-1))||waiter lock_tree from 
     (select * from lk 
      union all
      select distinct 'root', blocker from lk 
      where blocker not in (select waiter from lk)) 
   connect by prior waiter=blocker start with blocker='root';
EOF
exit 0
fi

# -- sidsql info
if [ "$1" = "sidsql" ]; then
  if [ "$2" = "" ];then
    echo "Please enter session sid"
    exit 0
  else
    ssid=$2
  fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
col sql_text for a60
col machine for a20
col username for a15
col elapsed_mins for 99999
col MODULE for a15
col time_remaining for 99999
col inst_sid for a10
SELECT  a.inst_id||'.'||a.sid as inst_sid,
        b.sql_id,
         b.sql_text, --content of SQL
         a.machine, --which machine run this code
         a.username, a.module, -- the method to run this SQL
         round(c.sofar/totalwork * 100,2) c_percent, --conplete percent
         round(c.elapsed_seconds/60,2) elapsed_mins, --run time
         round(c.time_remaining/60,2) remain_mins, --remain to run time
		 to_char(a.SQL_EXEC_START,'yyyy/mm/dd hh24:mi:ss') SQL_EXEC_START
FROM gv\$session a,gv\$sqlarea b, gv\$session_longops c
WHERE a.sql_hash_value = b.hash_value AND a.SID = c.SID
              AND a.serial# = c.serial# and a.inst_id=b.inst_id and b.inst_id=c.inst_id
AND a.sid=$ssid;
EOF
exit 0
fi

# -- sqlid sqltext info
if [ "$1" = "sqlid" ]; then
  if [ "$2" = "" ];then
    echo "Please enter sqlid"
    exit 0
  else
    sqlid=$2
  fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
col sql_text for a50
col machine for a20
col username for a15
col elapsed_mins for 99999
col MODULE for a15
col time_remaining for 99999
col inst_sid for a10
SELECT  a.inst_id||'.'||a.sid as inst_sid,
         b.sql_id,
         a.machine, --which machine run this code
         a.username, a.module, -- the method to run this SQL
         to_char(a.SQL_EXEC_START,'yyyy/mm/dd hh24:mi:ss') SQL_EXEC_START,
         substr(b.sql_text,1,50)  sql_text   --content of SQL
FROM gv\$session a,gv\$sqlarea b
WHERE a.sql_hash_value = b.hash_value 
and a.inst_id=b.inst_id
AND b.sql_id='$sqlid';
EOF
exit 0
fi

# -- wait event  sql info
if [ "$1" = "event_sql" ]; then
set -f
echo "Note: No result within 6 seconds of consumption time, please use sqlid to check"
read -p "please enter event name :" eventval
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep '|'
set pagesize 999
set linesize 200
col sql_text for a50
col machine for a20
col username for a15
col elapsed_mins for 99999
col MODULE for a15
col time_remaining for 99999
col inst_sid for a10
SELECT  a.inst_id||'.'||a.sid as inst_sid,
         b.sql_id,
         a.machine, --which machine run this code
         a.username, a.module, -- the method to run this SQL
         round(c.sofar/totalwork * 100,2) c_percent,                    --conplete percent
         round(c.elapsed_seconds/60,2) elapsed_mins,                    --run time
         round(c.time_remaining/60,2) remain_mins,                      --remain to run time
		 to_char(a.SQL_EXEC_START,'yyyy/mm/dd hh24:mi:ss') SQL_EXEC_START,
      substr(b.sql_text,1,50)  sql_text                                  --content of SQL
FROM gv\$session a,gv\$sqlarea b, gv\$session_longops c
WHERE a.sql_hash_value = b.hash_value AND a.SID = c.SID
              AND a.serial# = c.serial# and a.inst_id=b.inst_id and b.inst_id=c.inst_id
AND a.event like '%$eventval%';
EOF
set -f
exit 0
fi

# -- top sql 
if [ "$1" = "topsql" ]; then
  if [ "$2" = "" ];then
    echo -e "
    Default elapsed_time sort,select view for v\$sqlare.
    You can choose [2:disk_reads,3:buffer_gets,5:executions,7:cpu_time,9:version_count], other invalid
    "
    vtype=elapsed_time
  else
    vtype=$2
  fi

sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | '
set pagesize 999
set lines  360
col sql_text for a50
col username for a14
col sharemem_mb for 99999
col execs for 99999
col ver_count for 9999
col LAST_ATIME for a14
select * from
(select b.username, 
       a.disk_reads,
       a.buffer_gets,
       to_char(a.LAST_ACTIVE_TIME,'mm-dd hh24:mi:ss') LAST_ATIME,
       --a.sorts,
       a.executions execs,
       --a.rows_processed ,
       --100 - round(100 *a.disk_reads/greatest(a.buffer_gets,1),2) hit_ratio,
       --a.first_load_time ,
       round(sharable_mem/1024/1024,2) sharemem_mb,
       --persistent_mem ,
       --runtime_mem,
       round(cpu_time/1000000,1) cpu_time_S,
       round(elapsed_time/1000000,1) elap_time_S,
	   VERSION_COUNT ver_count,
	        sql_id, 
       substr(sql_text,1,100) sql_text
       --address,
       --hash_value
from
   sys.v\$sqlarea a,
   sys.all_users b
where
   a.parsing_user_id=b.user_id
order by $vtype desc)
where rownum < 21;
EOF
exit 0
fi

# -- sql explain info
if [ "$1" = "sql_explain" ]; then
set -f
read -p "please input sql [ `echo -e "\033[31m Note \033[0m"` ';' End ]:" sqlval
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
col PLAN_TABLE_OUTPUT for a120
explain plan for $sqlval
select * from table(dbms_xplan.display(null,null,'ALL'));
EOF
set +f
exit 0
fi

# -- sqlid exec plan,for awr
if [ "$1" = "sqlid_plan" ]; then
 if [ "$2" = "" ];then
    echo "Please enter sqlid"
    exit 0
  else
    sqlid=$2
  fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set lines 200 pages 999
select * from table(dbms_xplan.display_awr('$sqlid')); 
EOF
exit 0
fi

# -- sqltype exec info
if [ "$1" = "sqltype" ]; then
  if [ "$2" = "" ];then
    mins=30
  else
    mins=$2
  fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | '
set pagesize 999
set linesize 200
prompt
prompt ** Display within $mins minutes sql operation  type: **
select sql_opname,count(*) op_count from v\$active_session_history where 
SAMPLE_TIME> sysdate -$mins/(24*60) 
and sql_opname is not null
group by sql_opname order by 2 desc;
EOF
exit 0
fi

# exp awr
if [ "$1" = "awr" ]; then
   if [[ "$2" = ""  || "$3" = "" ]]; then
     echo -e "Please enter begin snap_id and end snap_id:
        You can find the snap_id  by [ ./oratf dbtime ]"
     exit 0
   else
     bsnap=$2
     esnap=$3
   fi

#get dbid
MYDBID=`sqlplus -s /nolog <<EOF
set echo off underline off
set feedback off
set heading off
connect $DBUSER;
select dbid from v\\$database;
exit
EOF
`
#get inst_id
INSTID=`sqlplus -s /nolog << EOF
connect $DBUSER
set echo off underline off
set feedback off
set heading off
select instance_number from v\\$instance;
EOF
`

sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set heading off
COLUMN instance_name new_value _instname NOPRINT
select instance_name  from v\$instance;
spool awr\_&_instname\_$bsnap\_$esnap.html
select output from table(dbms_workload_repository.awr_report_html($MYDBID,$INSTID,$bsnap,$esnap));
spool off
EOF
exit 0
fi

# exp ash
if [ "$1" = "ash" ]; then
   if [[ "$2" = ""  || "$3" = "" ]]; then
     echo -e "Please enter begin time and end time, format:yyyymmdd-hh24mi
       eg: ./oratf ash 20220112-1300 20220112-1309
       "
     exit 0
   else
     btime=$2
     etime=$3
   fi

# get dbid
MYDBID=`sqlplus -s /nolog <<EOF
set echo off underline off
set feedback off
set heading off
connect $DBUSER
select dbid from v\\$database;
exit
EOF
`

#get inst_id
INSTID=`sqlplus -s /nolog << EOF
connect $DBUSER
$conn_pdb
set echo off underline off
set feedback off
set heading off
select instance_number from v\\$instance;
EOF
`

sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set heading off
COLUMN instance_name new_value _instname NOPRINT
select instance_name  from v\$instance;
spool ash\_&_instname\_$btime\_$etime.html
select output from table(dbms_workload_repository.ash_report_html($MYDBID,$INSTID,to_date('$btime','yyyymmdd-hh24mi'),to_date('$etime','yyyymmdd-hh24mi')));
spool off
EOF
exit 0
fi

# display awr sql consumption resources in time period
if [ "$1" = "awrsql" ]; then
   if [[ "$2" = ""  || "$3" = "" ]]; then
     echo -e "Please enter begin time and end time, format:yyyymmdd-hh24mi
       eg: ./oratf awrsql 20220112-1300 20220112-1309
       "
     exit 0
   else
     btime=$2
     etime=$3
   fi

sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | '
set pagesize 999
set linesize 200
select s.sql_id
,round(elapsed_time/1000000,1)   elapsed_time
,execs
,round(elapsed_time/1000000/decode(execs,0,null,execs),1) "elpe/execs"
,round(cpu_time/1000000,1)     cpu_time
,round(iowait_time/1000000,1)     iowait_time
,gets
,reads
--,rws
--,clwait_time/1000000     clwait_time
,substr(st.sql_text,1,80) sqt
from
(select * from
( select sql_id
, sum(executions_delta)      execs
, sum(buffer_gets_delta)     gets
, sum(disk_reads_delta)      reads
--, sum(rows_processed_delta)  rws
, sum(cpu_time_delta)        cpu_time
, sum(elapsed_time_delta)         elapsed_time
--, sum(clwait_delta)         clwait_time
, sum(iowait_delta)         iowait_time
from dba_hist_sqlstat sq,dba_hist_snapshot sn
where sq.snap_id=sn.snap_id 
and sn.end_interval_time >=to_date('$btime','yyyymmdd-hh24mi') 
and sn.end_interval_time <=to_date('$etime','yyyymmdd-hh24mi')
group by sql_id
order by sum(elapsed_time_delta) desc)
where rownum <= 40) s, dba_hist_sqltext st
where st.sql_id = s.sql_id
order by elapsed_time desc, sql_id;
EOF
exit 0
fi


# -- oracle db psu info
if [ "$1" = "psu" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set colsep ' | '
col action format a16  
col namespace format a10  
col version format a10  
col comments format a40 
col action_time format a20  
col bundle_series format a15  
alter session set nls_timestamp_format = 'yyyy-mm-dd hh24:mi:ss';  
select * from dba_registry_history;
EOF
exit 0
fi

if [ "$1" = "profile" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set colsep ' | '
select * from dba_profiles order by profile; 
EOF
exit 0
fi


# -- oracle arch info last 15
if [ "$1" = "arch" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set colsep ' | '
set numw 4
col Total for 9999
col Day for a3
col "ID" for 9
SELECT  THREAD# "ID",
				to_char(first_time,'mm-dd') "Date",
       -- to_char(first_time, 'Dy') "Day",
        count(1) "Total",
        SUM(decode(to_char(first_time, 'hh24'),'00',1,0)) "h0",
        SUM(decode(to_char(first_time, 'hh24'),'01',1,0)) "h1",
        SUM(decode(to_char(first_time, 'hh24'),'02',1,0)) "h2",
        SUM(decode(to_char(first_time, 'hh24'),'03',1,0)) "h3",
        SUM(decode(to_char(first_time, 'hh24'),'04',1,0)) "h4",
        SUM(decode(to_char(first_time, 'hh24'),'05',1,0)) "h5",
        SUM(decode(to_char(first_time, 'hh24'),'06',1,0)) "h6",
        SUM(decode(to_char(first_time, 'hh24'),'07',1,0)) "h7",
        SUM(decode(to_char(first_time, 'hh24'),'08',1,0)) "h8",
        SUM(decode(to_char(first_time, 'hh24'),'09',1,0)) "h9",
        SUM(decode(to_char(first_time, 'hh24'),'10',1,0)) "h10",
        SUM(decode(to_char(first_time, 'hh24'),'11',1,0)) "h11",
        SUM(decode(to_char(first_time, 'hh24'),'12',1,0)) "h12",
        SUM(decode(to_char(first_time, 'hh24'),'13',1,0)) "h13",
        SUM(decode(to_char(first_time, 'hh24'),'14',1,0)) "h14",
        SUM(decode(to_char(first_time, 'hh24'),'15',1,0)) "h15",
        SUM(decode(to_char(first_time, 'hh24'),'16',1,0)) "h16",
        SUM(decode(to_char(first_time, 'hh24'),'17',1,0)) "h17",
        SUM(decode(to_char(first_time, 'hh24'),'18',1,0)) "h18",
        SUM(decode(to_char(first_time, 'hh24'),'19',1,0)) "h19",
        SUM(decode(to_char(first_time, 'hh24'),'20',1,0)) "h20",
        SUM(decode(to_char(first_time, 'hh24'),'21',1,0)) "h21",
        SUM(decode(to_char(first_time, 'hh24'),'22',1,0)) "h22",
        SUM(decode(to_char(first_time, 'hh24'),'23',1,0)) "h23"
FROM    V\$log_history where to_date(first_time)>to_date(sysdate-15)
group by THREAD#,to_char(first_time,'mm-dd'), to_char(first_time, 'Dy')
Order by 1,2;
set numw 20
EOF
exit 0
fi

# -- oracle arch size
if [ "$1" = "archsize" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set colsep ' | '
select trunc(completion_time) as "Date",count(*) as "Count",
(trunc(sum(blocks * block_size)/1024/1024/1024,2)) as "GB"
from v\$archived_log where  STANDBY_DEST  ='NO' 
and to_date(first_time)>to_date(sysdate-20) group by trunc(completion_time) 
order by trunc(completion_time) desc;
EOF
exit 0
fi

# -- oracle rman backup info
if [ "$1" = "rman" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set colsep ' | '
col TIME_TAKEN_DISPLAY format a17
col status format a10
COL hours    FORMAT 999.999
COL out_size FORMAT a10
col type format a10
select session_key,AUTOBACKUP_DONE,OUTPUT_DEVICE_TYPE type, INPUT_TYPE,status,
round(ELAPSED_SECONDS/3600,2) hours,TO_CHAR(START_TIME,'yyyy-mm-dd hh24:mi') start_time,
to_char(END_TIME,'yyyy-mm-dd hh24:mi') end_time ,OUTPUT_BYTES_DISPLAY out_size
from v\$RMAN_BACKUP_JOB_DETAILS
where end_time>sysdate-30 order by start_time;
EOF
exit 0
fi

# oracle osstat info
if [ "$1" = "osstat" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
col STAT_NAME for a24
col value for a10
set colsep '  |  '
SELECT STAT_NAME,
  DECODE(STAT_NAME,'PHYSICAL_MEMORY_BYTES',(ROUND(VALUE/1024/1024/1024,2))||'GB',
  'FREE_MEMORY_BYTES',(ROUND(VALUE/1024/1024/1024,2))||' GB',
  'LOAD',round(VALUE,2),VALUE) VALUE
FROM v\$osstat
WHERE
stat_name IN ('FREE_MEMORY_BYTES', 'LOAD','NUM_CPUS',
'NUM_CPU_CORES','NUM_CPU_SOCKETS','PHYSICAL_MEMORY_BYTES');
EOF
exit 0
fi

# oracle alertlog info
if [ "$1" = "alert" ]; then
  if [ "$2" = "" ]; then
      ldays=1
  elif [[ ! "$2" =~ ^[0-9]+$ ]];then
      echo -e "$2 error number
          eg: ./oratf alert 10 [Search content]"
      exit 0
  else
      ldays=$2
  fi
  if [ -n "$3" ]; then
      lerror=$3
    else
      lerror=""
  fi   
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 9999
set linesize 200
col MESSAGE_TEXT for a96
col MESSAGE_TYPE for a14
break on alert_time
select 
to_char(ORIGINATING_TIMESTAMP,'yyyy/mm/dd hh24:mi:ss') alert_time,
MESSAGE_TEXT 
from v\$diag_alert_ext a where
a.COMPONENT_ID like '%rdbms%'
and ORIGINATING_TIMESTAMP>sysdate-$ldays
and message_text like upper('%$lerror%')
order by ORIGINATING_TIMESTAMP;
EOF
exit 0
fi

# Statistics of ip connections during the time period
if [ "$1" = "ipcount" ]; then
   if [[ "$2" = ""  || "$3" = "" ]]; then
     echo -e "Please enter begin time and end time, format:yyyymmdd-hh24
       eg: ./oratf ipcount 20220112-13 20220112-13
       "
     exit 0
   else
     btime=$2
     etime=$3
   fi
   if [ "$4" = "" ]; then
   echo -e "
   Based on results.You can add the ipaddr to the end of the command,Displays hourly distribution
     eg : ./oratf ipcount 20220112-00 20220113-00 192.168.1.21"

sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set heading on
set lines 200 pages 9999
col ip_addr for a20
select IP_ADDR,count(*) from (select 
to_char(ORIGINATING_TIMESTAMP,'yyyy/mm/dd hh24') alert_time,
regexp_substr(MESSAGE_TEXT,'[1-9]*[.][1-9]*[.][0-9]*[.][1-9]*') IP_ADDR 
from v\$diag_alert_ext a where
a.COMPONENT_ID like '%tnslsnr%'
and ORIGINATING_TIMESTAMP>=to_date('$btime','yyyymmdd-hh24')
and ORIGINATING_TIMESTAMP<=to_date('$etime','yyyymmdd-hh24')
and message_text like '%establish%')
group by IP_ADDR ORDER BY 2 desc;
EOF
    exit 0
  else
    ipaddr=$4
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set heading on
set lines 200 pages 9999
col ip_addr for a20
select alert_time,count(*) from (select 
to_char(ORIGINATING_TIMESTAMP,'yyyy/mm/dd hh24') alert_time,
regexp_substr(MESSAGE_TEXT,'[1-9]*[.][1-9]*[.][0-9]*[.][1-9]*') IP_ADDR 
from v\$diag_alert_ext a where
a.COMPONENT_ID like '%tnslsnr%'
and ORIGINATING_TIMESTAMP>=to_date('$btime','yyyymmdd-hh24')
and ORIGINATING_TIMESTAMP<=to_date('$etime','yyyymmdd-hh24')
and message_text like '%establish%')
where IP_ADDR='$ipaddr'
group by alert_time ORDER BY 1;
EOF
  exit 0
  fi
     exit 0
fi

#### CDB mode  sql(display all pdb info)  view(cdb_*)###############

#CDB parameters list
command_cdb_help()
{
echo -e "

   --> Oracle default uses [/ as sysdba],if you want change, please modify [DBUSER] <--

Command Reference : oratf cdb key_value [parameter1] [parameter2]

   Keys List:
     - cdb dbf [tbs]                                      Default display all datafiles ,[tbs] specify tablespace
	   - cdb event                                          Display current wait event info
     - cdb event_ash [mins]                               Display wait event history, default last 30min
     - cdb event_sql                                      Display wait event Related sql info
     - cdb pdbsize                                        Display DB User size
     - cdb pgasql [size] mb                               Display use pga much sql,default greater than [100]M
     - cdb profile                                        Display db profiles resource info
     - cdb ru                                             Display cdb ru info
     - cdb size                                           Display cdb total size
     - cdb sqltype   [mins]                               Show sql operation type , default within 30 minutes
     - cdb tbs                                            Tablespace usage info
     - cdb trans                                          Display current run transactions
     - cdb topsql [sort by type]                          Dsiplay v$sqlare top 20 sql,Default ELAPSED_TIME sort
     - cdb user                                           Display DB User info
 

notice : The currently connected db instance is `echo -e "\033[31m $ORACLE_SID \033[0m"`
The cdb mode is check all pdb(cdb_*), Use of resources may increase.
If you want to check a specific pdb, use pdb mode [./oratf pdb ] Or use [./oratf] to check the cdb database.
"
}


# CDB specific commands
if [ "$1" = "cdb" ]; then
   # If DB version is lower than 12,CANCEL
   if [ $dbver -lt 12 ]; then
      echo  " Current database version is too low.  You can [./oratf dbver] check"
      exit 0
   fi
  # if it is not  cdb mode,CANCEL
  if [ $mcdb = "NO" ]; then
    echo  " Current database is not CDB mode. Please check again"
    exit 0
  fi
   # -- cdb size
   if [ "$2" = "size" ]; then
sqlplus -s /nolog << EOF
connect $DBUSER
set colsep ' | '
set lines 200 pages 99
col PLATFORM_NAME for a20
col FORCE_LOG for a9
col pdbname for a16
select * from (
select c.name pdbname,round(sum(d.bytes/1024/1024/1024),2) size_gb from cdb_segments d,v\$containers c where d.con_id=c.con_id group by c.name order by 2 desc)
union all
select '-------' as  pdbname, 0 as size_gb from dual union all
select 'Total' as pdbname,round(sum(bytes/1024/1024/1024),2) size_gb from cdb_segments;
prompt You can run [./oratf cdb pdbsize] check pdb segment_type size
prompt
EOF
  exit 0
   fi
  # tablespace usage info
  if [ "$2" = "tbs" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
set colsep ' | ' 
col tablespace_name for a30
set linesize 150 pagesize 500
col pdbname for a16
break on pdbname
select c.name pdbname,f.tablespace_name tablespace_name,
round((d.sumbytes/1024/1024/1024),2) total_without_extend_GB,
round(((d.sumbytes+d.extend_bytes)/1024/1024/1024),2) total_with_extend_GB,
round((f.sumbytes+d.Extend_bytes)/1024/1024/1024,2) free_with_extend_GB,
round((d.sumbytes-f.sumbytes)/1024/1024/1024,2) used_GB,
round((d.sumbytes-f.sumbytes)*100/(d.sumbytes+d.extend_bytes),2) used_percent
from (select con_id,tablespace_name,sum(bytes) sumbytes from cdb_free_space group by con_id,tablespace_name) f, 
(select con_id,tablespace_name,sum(aa.bytes) sumbytes,sum(aa.extend_bytes) extend_bytes from
 (select  con_id,nvl(case  when autoextensible ='YES' then (case when (maxbytes-bytes)>=0 then (maxbytes-bytes) end) end,0) Extend_bytes
,tablespace_name,bytes  from cdb_data_files) aa group by con_id,tablespace_name) d,v\$containers c
where  (f.con_id=d.con_id and f.tablespace_name=d.tablespace_name) and f.con_id=c.con_id
order by  name,used_percent desc;
EOF
    exit 0
  fi

  # -- datafile info
  if [ "$2" = "dbf" ]; then
     if [ "$3" = "" ]; then
        pdbname=""
     else
        pdbname=$3
     fi
sqlplus -s /nolog << EOF
connect $DBUSER
set feedback off
set colsep '|'
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
set lines 200 pages 999
col file_name format a55
col tablespace_name for a25
col pdbname for a16
col fid for 9999
select p.name pdbname,d.file_id fid,d.tablespace_name,d.file_name,round(d.bytes/1024/1024/1024,2) as "bytes(Gb)",
d.status,d.autoextensible,f.creation_time  
from cdb_data_files d,v\$datafile f ,v\$pdbs p where d.file_id=f.file#  and d.con_id=p.con_id
and p.name like upper('%$pdbname%')  order by f.creation_time;
EOF
  exit 0
  fi 

  # -- cdb+pdb current wait event
  if [ "$2" = "event" ]; then
  while :
  do
  clear
  echo "Wait event to refresh once every 5 seconds. Termination please enter [Ctrl + C]:"
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | ' 
set lines 200
col event for a40
set lines 200
col event for a40
col pdbname for a20
select s.inst_id,p.name pdbname,s.SQL_ID,s.event,count(1) from gv\$session s,v\$containers p where s.con_id=p.con_id and wait_class#<> 6 
group by s.inst_id,p.name,s.SQL_ID,s.event order by 5 desc;
EOF
  sleep 5
done
  exit 0
  fi 

# -- oracle wait event for ash
 if [ "$2" = "event_ash" ]; then
  if [ "$3" = "" ]; then
    echo -e "
    Default last 30min, you can enter other integer value"
    mins=30
  else
    mins=$3
  fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | ' 
set lines 200 pages 999
col event for a40
col pdbname for a20
prompt
prompt You can exec './oratf cdb event_sql' view sql info.
SELECT c.name pdbname,NVL(a.event, 'ON CPU') AS event,
       COUNT(*) AS total_wait_time
FROM   v\$active_session_history a,v\$containers c
WHERE  a.con_id=c.con_id 
and a.sample_time > SYSDATE - $mins/(24*60)
GROUP BY c.name,a.event
ORDER BY total_wait_time DESC;
EOF
 exit 0
 fi

# -- sqlid sqltext info
 if [ "$2" = "sqlid" ]; then
  if [ "$3" = "" ];then
    echo "Please enter sqlid"
    exit 0
  else
    sqlid=$3
  fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
set pagesize 999
set linesize 200
col sql_text for a50
col machine for a20
col username for a15
col elapsed_mins for 99999
col MODULE for a15
col time_remaining for 99999
col inst_sid for a10
col pdbname for a16
SELECT  c.name pdbname,a.inst_id||'.'||a.sid as inst_sid,
         b.sql_id,
         a.machine, --which machine run this code
         a.username, a.module, -- the method to run this SQL
		     to_char(a.SQL_EXEC_START,'yyyy/mm/dd hh24:mi:ss') SQL_EXEC_START,
         substr(b.sql_text,1,50)  sql_text   --content of SQL
FROM gv\$session a,gv\$sqlarea b, v\$containers c
WHERE a.sql_hash_value = b.hash_value 
and a.inst_id=b.inst_id  and a.con_id=c.con_id
AND b.sql_id='$sqlid';
EOF
exit 0
 fi

  # -- wait event  sql info
  if [ "$2" = "event_sql" ]; then
  set -f
  echo "Note: No results within 6 seconds of consumption time, please use sqlid method"
read -p "please enter event name :" eventval
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
set colsep '|'
set pagesize 999
set linesize 200
col sql_text for a50
col machine for a20
col username for a15
col elapsed_mins for 99999
col MODULE for a15
col time_remaining for 99999
col inst_sid for a10
col pdbname for a16
SELECT  p.name pdbname,a.inst_id||'.'||a.sid as inst_sid,
         b.sql_id,
         a.machine, --which machine run this code
         a.username, a.module, -- the method to run this SQL
         round(c.sofar/totalwork * 100,2) c_percent,                    --conplete percent
         round(c.elapsed_seconds/60,2) elapsed_mins,                    --run time
         round(c.time_remaining/60,2) remain_mins,                      --remain to run time
		 to_char(a.SQL_EXEC_START,'yyyy/mm/dd hh24:mi:ss') SQL_EXEC_START,
      substr(b.sql_text,1,50)  sql_text                                  --content of SQL
FROM gv\$session a,gv\$sqlarea b, gv\$session_longops c,v\$containers p
WHERE a.sql_hash_value = b.hash_value AND a.SID = c.SID
              AND a.serial# = c.serial# and a.inst_id=b.inst_id and b.inst_id=c.inst_id and a.con_id=p.con_id
AND a.event like '%$eventval%';
EOF
    set -f
    exit 0
  fi
  
  # -- top sql 
if [ "$2" = "topsql" ]; then
  if [ "$3" = "" ];then
    echo -e "
    Default elapsed_time sort,select view for v\$sqlare.
    You can choose [2:disk_reads,3:buffer_gets,5:executions,7:cpu_time,9:version_count], other invalid
    "
    vtype=elapsed_time
  else
    vtype=$3
  fi

sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
set colsep ' | '
set pagesize 999
set lines  360
col sql_text for a50
col username for a14
col sharemem_mb for 99999
col execs for 99999
col ver_count for 9999
col LAST_ATIME for a14
col pdbname for a16
select * from
(select a.inst_id,c.name pdbname,b.username, 
       a.disk_reads,
       a.buffer_gets,
       to_char(a.LAST_ACTIVE_TIME,'mm-dd hh24:mi:ss') LAST_ATIME,
       --a.sorts,
       a.executions execs,
       --a.rows_processed ,
       --100 - round(100 *a.disk_reads/greatest(a.buffer_gets,1),2) hit_ratio,
       --a.first_load_time ,
       round(sharable_mem/1024/1024,2) sharemem_mb,
       --persistent_mem ,
       --runtime_mem,
       round(cpu_time/1000000,1) cpu_time_S,
       round(elapsed_time/1000000,1) elap_time_S,
	   VERSION_COUNT ver_count,
	        sql_id, 
       substr(sql_text,1,100) sql_text
       --address,
       --hash_value
from
   sys.gv\$sqlarea a,
   sys.cdb_users b,
   v\$containers c
where
   a.parsing_user_id=b.user_id and a.con_id=c.con_id
order by $vtype desc)
where rownum < 21;
EOF
exit 0
fi

  # -- oracle pdb size info
  if [ "$2" = "pdbsize" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set colsep ' | '
col pdbname for a16
select * from (select pdbname,segment_type,segment_type_gb,
sum(segment_type_gb) over (partition by t.pdbname) as PDB_sizeGB from
(select c.name pdbname,segment_type,
round(sum(s.bytes/1024/1024/1024),2) segment_type_gb
from cdb_segments s,v\$containers c where s.con_id=c.con_id group by c.name,s.segment_type) t 
order by 4 desc)
pivot
(sum(segment_type_gb) for segment_type in ('TABLE' as TABLES,'INDEX' as INDEXS,'LOBSEGMENT' as LOBSEGMENTS,
'LOB PARTITION' as LOB_PARTITIONS,'TABLE PARTITION' as TABLE_PARTITIONS,
'TABLE SUBPARTITION' as TABLE_SUBPARTITIONS,
'INDEX PARTITION' as INDEX_PARTITIONS,'LOBINDEX' as LOBINDEXS,'ROLLBACK' as ROLLBACKS)) pt 
order by PDB_SIZEGB desc;
EOF
    exit 0
  fi

  # -- Use pga much sql 
  if [ "$2" = "pgasql" ]; then
    if [ "$3" = "" ];then
    sizes=100
    else
    sizes=$3
    fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
set colsep ' | '
set lines 200
set pages 999
col MACHINE for a10
col PROGRAM for a28
col USERNAME for a15
col pdbname for a16
select c.name pdbname,s.inst_id,s.sid, s.serial#, s.username, s.machine, s.program,s.process, s.sql_id,
round(p.pga_alloc_mem/1048576,2) size_m, p.spid from gv\$session s, gv\$process p,v\$containers c where s.paddr=p.addr and s.inst_id=p.inst_id
and s.con_id=c.con_id
and p.pga_alloc_mem>$sizes*1024*1024 order by 8 desc;
EOF
    exit 0
  fi
  
  # -- sqltype exec info
  if [ "$2" = "sqltype" ]; then
    if [ "$3" = "" ];then
      mins=30
    else
      mins=$3
    fi
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
set colsep ' | '
set pagesize 999
set linesize 200
col pdbname for a16
prompt
prompt ** Display within $mins minutes sql operation  type: **
select a.inst_id,c.name pdbname,a.sql_opname,count(*) op_count from gv\$active_session_history a,v\$containers c
where  a.con_id=c.con_id and
SAMPLE_TIME> sysdate -$mins/(24*60) 
and sql_opname is not null
group by a.inst_id,c.name,a.sql_opname order by 2,4 desc;
EOF
    exit 0
  fi
  
  # -- oracle cdb long transaction
  if [ "$2" = "trans" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
set colsep ' | ' 
set lines 999
col PHY_IO for 99999999
col NAME for a20
col MACHINE for a15
col username for a15
col PROGRAM for a28
col pdbname for a16
col spid for a10
select gt.inst_id,c.name pdbname,gs.sid,gs.serial#,gp.spid,gs.USERNAME,gs.MACHINE,gs.PROGRAM,gt.status,
gt.start_time,gt.LOG_IO,gt.PHY_IO
from gv\$transaction gt,gv\$session gs ,gv\$process gp,v\$containers c
where gs.saddr=SES_ADDR and gs.paddr=gp.addr  and gt.con_id=c.con_id order by START_TIME;
EOF
    exit 0
  fi

  # -- oracle cdb ru
  if [ "$2" = "ru" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
set colsep ' | ' 
set lines 999
set pages 999
select patch_id,patch_type,action,status,to_char(ACTION_TIME,'yyyy/mm/dd hh24:mi') ACTION_TIME,SOURCE_VERSION,target_version
from dba_registry_sqlpatch order by 1;
EOF
    exit 0
  fi

  ## cdb_profiles
  if [ "$2" = "profile" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set pagesize 999
set linesize 200
set colsep ' | '
col pdbname for a16
col limit for a30
col profile for a25
select c.name pdbname,p.* from cdb_profiles p,v\$containers c where p.con_id=c.con_id order by p.con_id,p.profile; 
EOF
    exit 0
  fi

  # -- oracle user info
  if [ "$2" = "user" ]; then
sqlplus -s /nolog << EOF
set feedback off
connect $DBUSER
$conn_pdb
set colsep ' | ' 
set pagesize 999
set linesize 200
col username for a25
col ACCOUNT_STATUS for a20
col DEFAULT_TABLESPACE for a20
col PROFILE for a20
col pdbname for a16
break on pdbname
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
with  temp as (select c.name pdbname,username,ACCOUNT_STATUS,DEFAULT_TABLESPACE,PROFILE,CREATED,EXPIRY_DATE
 from cdb_users u,v\$containers c where u.con_id=c.con_id order by c.name,u.created desc)
 select * from temp where pdbname='CDB\$ROOT' union all
 select * from temp where username not in (select username from temp where pdbname='CDB\$ROOT');
EOF
    exit 0
  fi   

  # enter other key , hint
  if [[ "$2" = "" || "$2" = "help" ]]; then
       command_cdb_help
        exit 0
  else
       echo  -e "Parameter '$2' is not exist,please check the parameter again. 
        # or run ' oratf cdb help '"
       exit 0
  fi
 exit 0
fi   



#  if oracle_sid
instname=`echo $ORACLE_SID`
if [ $instname = "" ]; then
echo "Please set ORACLE_SID"
exit 0
fi



echo "Oracle daily management tools -- by Firsouler"

if [[ "$1" = "" || "$1" = "help" ]]; then
command_help
else
echo  -e "Parameter '$1' is not exist,please check the parameter again. 
 # or run ' oratf help '"
fi
