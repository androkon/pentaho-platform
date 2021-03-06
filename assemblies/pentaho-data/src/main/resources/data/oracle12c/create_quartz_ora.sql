--THIS USER IS SPECIFIC TO THE DATABASE WHERE THIS SCRIPT IS TO BE RUN AND
--IT SHOULD BE A USER WITH DBA PRIVS.
--AND ALSO @pentaho should be replaced with the correct instance name
--
--NOTE: run create_repository_ora.sql before running this script, which
--      creates the pentaho_tablespace

-- conn admin/password@pentaho

alter session set "_ORACLE_SCRIPT"=true;

drop user quartz cascade;

create tablespace pentaho_tablespace
  logging
  datafile 'ptho_ts.dbf' 
  size 32m 
  autoextend on 
  next 32m maxsize 2048m
  extent management local;

create user quartz identified by "password" default tablespace pentaho_tablespace quota unlimited on pentaho_tablespace temporary tablespace temp quota 5M on system;

grant create session, create procedure, create table to quartz;

--CREATE QUARTZ TABLES

CONN quartz/password

CREATE TABLE QRTZ5_JOB_DETAILS 
  (
    JOB_NAME  VARCHAR2(200) NOT NULL,
    JOB_GROUP VARCHAR2(200) NOT NULL,
    DESCRIPTION VARCHAR2(250) NULL,
    JOB_CLASS_NAME   VARCHAR2(250) NOT NULL, 
    IS_DURABLE VARCHAR2(1) NOT NULL,
    IS_VOLATILE VARCHAR2(1) NOT NULL,
    IS_STATEFUL VARCHAR2(1) NOT NULL,
    REQUESTS_RECOVERY VARCHAR2(1) NOT NULL,
    JOB_DATA BLOB NULL,
    PRIMARY KEY (JOB_NAME,JOB_GROUP)
);

CREATE TABLE QRTZ5_JOB_LISTENERS
  (
    JOB_NAME  VARCHAR2(200) NOT NULL, 
    JOB_GROUP VARCHAR2(200) NOT NULL,
    JOB_LISTENER VARCHAR2(200) NOT NULL,
    PRIMARY KEY (JOB_NAME,JOB_GROUP,JOB_LISTENER),
    FOREIGN KEY (JOB_NAME,JOB_GROUP) 
        REFERENCES QRTZ5_JOB_DETAILS(JOB_NAME,JOB_GROUP)
);

CREATE TABLE QRTZ5_TRIGGERS
  (
    TRIGGER_NAME VARCHAR2(200) NOT NULL,
    TRIGGER_GROUP VARCHAR2(200) NOT NULL,
    JOB_NAME  VARCHAR2(200) NOT NULL, 
    JOB_GROUP VARCHAR2(200) NOT NULL,
    IS_VOLATILE VARCHAR2(1) NOT NULL,
    DESCRIPTION VARCHAR2(250) NULL,
    NEXT_FIRE_TIME NUMBER(38) NULL,
    PREV_FIRE_TIME NUMBER(38) NULL,
    PRIORITY NUMBER(38) NULL,
    TRIGGER_STATE varchar2(16) NOT NULL,
    TRIGGER_TYPE varchar2(8) NOT NULL,
    START_TIME NUMBER(38) NOT NULL,
    END_TIME NUMBER(38) NULL,
    CALENDAR_NAME VARCHAR2(200) NULL,
    MISFIRE_INSTR NUMBER(38) NULL,
    JOB_DATA BLOB NULL,
    PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (JOB_NAME,JOB_GROUP) 
        REFERENCES QRTZ5_JOB_DETAILS(JOB_NAME,JOB_GROUP)
);

CREATE TABLE QRTZ5_SIMPLE_TRIGGERS
  (
    TRIGGER_NAME VARCHAR2(200) NOT NULL,
    TRIGGER_GROUP VARCHAR2(200) NOT NULL,
    REPEAT_COUNT NUMBER(38) NOT NULL,
    REPEAT_INTERVAL NUMBER(38) NOT NULL,
    TIMES_TRIGGERED NUMBER(38) NOT NULL,
    PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP)
        REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ5_CRON_TRIGGERS
  (
    TRIGGER_NAME VARCHAR2(200) NOT NULL,
    TRIGGER_GROUP VARCHAR2(200) NOT NULL,
    CRON_EXPRESSION VARCHAR2(120) NOT NULL,
    TIME_ZONE_ID varchar2(80),
    PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP)
        REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ5_BLOB_TRIGGERS
  (
    TRIGGER_NAME VARCHAR2(200) NOT NULL,
    TRIGGER_GROUP VARCHAR2(200) NOT NULL,
    BLOB_DATA BLOB NULL,
    PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP) 
        REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ5_TRIGGER_LISTENERS
  (
    TRIGGER_NAME  VARCHAR2(200) NOT NULL, 
    TRIGGER_GROUP VARCHAR2(200) NOT NULL,
    TRIGGER_LISTENER VARCHAR2(200) NOT NULL,
    PRIMARY KEY(TRIGGER_NAME,TRIGGER_GROUP,TRIGGER_LISTENER),
    FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP)
        REFERENCES QRTZ5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ5_CALENDARS
  (
    CALENDAR_NAME  VARCHAR2(200) NOT NULL, 
    CALENDAR BLOB NOT NULL,
    PRIMARY KEY (CALENDAR_NAME)
);

CREATE TABLE QRTZ5_PAUSED_TRIGGER_GRPS
  (
    TRIGGER_GROUP  VARCHAR2(200) NOT NULL, 
    PRIMARY KEY (TRIGGER_GROUP)
);

CREATE TABLE QRTZ5_FIRED_TRIGGERS
  (
    ENTRY_ID varchar2(95) NOT NULL,
    TRIGGER_NAME VARCHAR2(200) NOT NULL,
    TRIGGER_GROUP VARCHAR2(200) NOT NULL,
    IS_VOLATILE varchar2(1) NOT NULL,
    INSTANCE_NAME VARCHAR2(200) NOT NULL,
    FIRED_TIME NUMBER(38) NOT NULL,
    PRIORITY NUMBER(38) NOT NULL,
    STATE varchar2(16) NOT NULL,
    JOB_NAME VARCHAR2(200) NULL,
    JOB_GROUP VARCHAR2(200) NULL,
    IS_STATEFUL varchar2(1) NULL,
    REQUESTS_RECOVERY varchar2(1) NULL,
    PRIMARY KEY (ENTRY_ID)
);

CREATE TABLE QRTZ5_SCHEDULER_STATE
  (
    INSTANCE_NAME VARCHAR2(200) NOT NULL,
    LAST_CHECKIN_TIME NUMBER(38) NOT NULL,
    CHECKIN_INTERVAL NUMBER(38) NOT NULL,
    PRIMARY KEY (INSTANCE_NAME)
);

CREATE TABLE QRTZ5_LOCKS
  (
    LOCK_NAME  varchar2(40) NOT NULL,
    PRIMARY KEY (LOCK_NAME)
);


INSERT INTO QRTZ5_LOCKS values('TRIGGER_ACCESS');
INSERT INTO QRTZ5_LOCKS values('JOB_ACCESS');
INSERT INTO QRTZ5_LOCKS values('CALENDAR_ACCESS');
INSERT INTO QRTZ5_LOCKS values('STATE_ACCESS');
INSERT INTO QRTZ5_LOCKS values('MISFIRE_ACCESS');
create index idx_QRTZ5_j_req_recovery on QRTZ5_job_details(REQUESTS_RECOVERY);
create index idx_QRTZ5_t_next_fire_time on QRTZ5_triggers(NEXT_FIRE_TIME);
create index idx_QRTZ5_t_state on QRTZ5_triggers(TRIGGER_STATE);
create index idx_QRTZ5_t_nft_st on QRTZ5_triggers(NEXT_FIRE_TIME,TRIGGER_STATE);
create index idx_QRTZ5_t_volatile on QRTZ5_triggers(IS_VOLATILE);
create index idx_QRTZ5_ft_trig_name on QRTZ5_fired_triggers(TRIGGER_NAME);
create index idx_QRTZ5_ft_trig_group on QRTZ5_fired_triggers(TRIGGER_GROUP);
create index idx_QRTZ5_ft_trig_nm_gp on QRTZ5_fired_triggers(TRIGGER_NAME,TRIGGER_GROUP);
create index idx_QRTZ5_ft_trig_volatile on QRTZ5_fired_triggers(IS_VOLATILE);
create index idx_QRTZ5_ft_trig_inst_name on QRTZ5_fired_triggers(INSTANCE_NAME);
create index idx_QRTZ5_ft_job_name on QRTZ5_fired_triggers(JOB_NAME);
create index idx_QRTZ5_ft_job_group on QRTZ5_fired_triggers(JOB_GROUP);
create index idx_QRTZ5_ft_job_stateful on QRTZ5_fired_triggers(IS_STATEFUL);
create index idx_QRTZ5_ft_job_req_recovery on QRTZ5_fired_triggers(REQUESTS_RECOVERY);

commit;
