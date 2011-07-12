--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: pool; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pool (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    url character varying(255) NOT NULL,
    enabled boolean NOT NULL
);


--
-- Name: pool_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pool_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: pool_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pool_id_seq OWNED BY pool.id;


--
-- Name: submitted_work; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE submitted_work (
    id integer NOT NULL,
    worker_id integer NOT NULL,
    pool_id integer NOT NULL,
    result boolean NOT NULL,
    "time" timestamp with time zone,
    reason character varying(255),
    work bytea,
    retries integer
);


--
-- Name: submitted_work_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE submitted_work_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: submitted_work_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE submitted_work_id_seq OWNED BY submitted_work.id;


--
-- Name: work_data; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE work_data (
    worker_id integer NOT NULL,
    pool_id integer NOT NULL,
    data bytea NOT NULL,
    time_requested timestamp with time zone NOT NULL,
    id integer NOT NULL
);


--
-- Name: work_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE work_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: work_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE work_data_id_seq OWNED BY work_data.id;


--
-- Name: worker; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE worker (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    password character varying(255) NOT NULL
);


--
-- Name: worker_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE worker_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: worker_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE worker_id_seq OWNED BY worker.id;


--
-- Name: worker_pool; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE worker_pool (
    pool_id integer NOT NULL,
    worker_id integer NOT NULL,
    pool_username character varying(255) NOT NULL,
    pool_password character varying(255) NOT NULL,
    priority integer NOT NULL,
    enabled boolean NOT NULL
);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE pool ALTER COLUMN id SET DEFAULT nextval('pool_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE submitted_work ALTER COLUMN id SET DEFAULT nextval('submitted_work_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE work_data ALTER COLUMN id SET DEFAULT nextval('work_data_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE worker ALTER COLUMN id SET DEFAULT nextval('worker_id_seq'::regclass);


--
-- Name: pool_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pool
    ADD CONSTRAINT pool_pkey PRIMARY KEY (id);


--
-- Name: submitted_work_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY submitted_work
    ADD CONSTRAINT submitted_work_pkey PRIMARY KEY (id);


--
-- Name: work_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY work_data
    ADD CONSTRAINT work_data_pkey PRIMARY KEY (worker_id, data);


--
-- Name: worker_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY worker
    ADD CONSTRAINT worker_name_key UNIQUE (name);


--
-- Name: worker_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY worker
    ADD CONSTRAINT worker_pkey PRIMARY KEY (id);


--
-- Name: worker_pool_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY worker_pool
    ADD CONSTRAINT worker_pool_pkey PRIMARY KEY (pool_id, worker_id);


--
-- Name: dashboard_status_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX dashboard_status_index ON submitted_work USING btree (worker_id, result, "time");


--
-- Name: submitted_work_timeidx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX submitted_work_timeidx ON submitted_work USING btree ("time");


--
-- Name: worker_time; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX worker_time ON work_data USING btree (worker_id, data);


--
-- Name: submitted_work_pool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submitted_work
    ADD CONSTRAINT submitted_work_pool_id_fkey FOREIGN KEY (pool_id) REFERENCES pool(id);


--
-- Name: submitted_work_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submitted_work
    ADD CONSTRAINT submitted_work_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES worker(id);


--
-- Name: work_data_pool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY work_data
    ADD CONSTRAINT work_data_pool_id_fkey FOREIGN KEY (pool_id) REFERENCES pool(id);


--
-- Name: work_data_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY work_data
    ADD CONSTRAINT work_data_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES worker(id);


--
-- Name: worker_pool_pool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY worker_pool
    ADD CONSTRAINT worker_pool_pool_id_fkey FOREIGN KEY (pool_id) REFERENCES pool(id);


--
-- Name: worker_pool_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY worker_pool
    ADD CONSTRAINT worker_pool_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES worker(id);


--
-- PostgreSQL database dump complete
--

