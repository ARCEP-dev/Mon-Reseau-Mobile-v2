--
-- PostgreSQL database dump
--

\restrict ztDR9eryx7GgGH9dMtPH6Xtx1S3e60yOhaucfAicJwgrCOujm6gafeGY6a6udDm

-- Dumped from database version 15.17 (Debian 15.17-1.pgdg11+1)
-- Dumped by pg_dump version 15.18 (Debian 15.18-0+deb12u1)

-- Started on 2026-07-02 14:22:09 CEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 14 (class 2615 OID 1736585)
-- Name: mrm_private; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA mrm_private;


--
-- TOC entry 15 (class 2615 OID 1658718)
-- Name: mrm_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA mrm_public;


--
-- TOC entry 10 (class 2615 OID 781410)
-- Name: postgisftw; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA postgisftw;


--
-- TOC entry 5 (class 3079 OID 1130919)
-- Name: pg_buffercache; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_buffercache WITH SCHEMA public;


--
-- TOC entry 7397 (class 0 OID 0)
-- Dependencies: 5
-- Name: EXTENSION pg_buffercache; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_buffercache IS 'examine the shared buffer cache';


--
-- TOC entry 2 (class 3079 OID 781411)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 7398 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 3 (class 3079 OID 781492)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 7399 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- TOC entry 4 (class 3079 OID 782574)
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- TOC entry 7400 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- TOC entry 1867 (class 1255 OID 1736586)
-- Name: _debug_hexa(integer, integer, integer); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private._debug_hexa(z integer, x integer, y integer) RETURNS bytea
    LANGUAGE sql
    AS $$

    with bounds as (
			  SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
	mvtgeom AS (
		SELECT 1 as fid, r.geometry--ST_AsMVTGeom(hex.geom, bounds.geom) AS geom
		FROM  
		--(SELECT 1 as gid, ST_Extent(geom) as geom from mrm_last.region ) as r
		mrm_private.qos as r
		INNER JOIN ST_HexagonGrid(30, r.geometry) AS hex ON ST_Intersects(r.geometry, hex.geom)
		INNER JOIN bounds ON ST_Intersects(r.geometry, bounds.geom )
		where id_data_source_desc = 11   
		--group by hex.geom, bounds.geom
	)
	SELECT ST_AsMVT(mvtgeom)
	FROM mvtgeom;
$$;


--
-- TOC entry 1868 (class 1255 OID 1736587)
-- Name: _debug_tiles(integer, integer, integer); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private._debug_tiles(z integer, x integer, y integer) RETURNS bytea
    LANGUAGE sql
    AS $$
    with tile as (
        select z, x, y, public.ST_asmvtgeom(public.ST_TileEnvelope(z,x,y), public.ST_TileEnvelope(z,x,y))
    )
    select public.ST_asmvt(tile) from tile;
$$;


--
-- TOC entry 1869 (class 1255 OID 1736588)
-- Name: arcep_get_code_operateur(text, text); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.arcep_get_code_operateur(params_code text, params_dept text) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	code_operateur_result text;
	schema_function text;
begin
	schema_function := public.parent_schema();
	RAISE NOTICE 'schema_name %', schema_function;
	PERFORM set_config('search_path', schema_function, TRUE); 
	select identifiant from operateurs op where op.code = params_code and 
	case 
		when params_dept = '971' then perimetre_971 = true 
		when params_dept = '972' then perimetre_972 = true
		when params_dept = '973' then perimetre_973 = true
		when params_dept = '974' then perimetre_974 = true
		when params_dept = '976' then perimetre_976 = true
		when params_dept = '977' then perimetre_977 = true
		when params_dept = '978' then perimetre_978 = true
		else perimetre_metro = true
	end
	limit 1 INTO code_operateur_result ;
	return code_operateur_result;
end;
$$;


--
-- TOC entry 1870 (class 1255 OID 1736589)
-- Name: couvertures(integer, integer, integer, integer[], character varying[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.couvertures(z integer, x integer, y integer, liste_operateur integer[], liste_techno character varying[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	if (z <= 7 and array_length(liste_operateur,1) = 1) then
		return (
			SELECT mvt
			from tiles_cache_couverture 
			Where tiles_cache_couverture.x=x 
				AND tiles_cache_couverture.y=y 
				AND tiles_cache_couverture.z=z 
				and operateur = any(liste_operateur)
				and techno = any(liste_techno)
		);
	else
		return (
			WITH
			bounds AS (
			  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
			 (CASE 
				when z >= 12 then 0
				when z = 11 then 0
				when z = 10 then 10
				when z = 9 then 100
				when z = 8 then 300
				when z = 7 then 900
				when z = 6 then 1500
				when z <= 5 then 3000 
				ELSE 1 END
			   ) as simplify_tolerance
			),

			mvtgeom AS (
			  SELECT fid, operateur, date, techno, usage, niveau, dept, filename,
				public.ST_AsMVTGeom(
					  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

			  FROM couverture_theorique t, bounds
			  WHERE public.ST_Intersects(t.geom, bounds.geom )
				and operateur = any(liste_operateur)
				and techno = any(liste_techno) 
				--and niveau <> ''
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		);
	end if;
end;
$$;


--
-- TOC entry 1871 (class 1255 OID 1736590)
-- Name: couvertures_tbc(integer, integer, integer, character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.couvertures_tbc(z integer, x integer, y integer, in_techno character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	RAISE NOTICE 'schema %', schema_function;
	PERFORM set_config('search_path', schema_function, TRUE); 
	if (z <= 9 ) then
		return (
			SELECT mvt
			from tiles_cache_couverture_tbc
			Where tiles_cache_couverture_tbc.x=x 
				AND tiles_cache_couverture_tbc.y=y 
				AND tiles_cache_couverture_tbc.z=z 
				and techno = in_techno
		);
	else
		return (
			WITH
			bounds AS (
			  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
			 (CASE 
				when z >= 12 then 0
				when z = 11 then 0
				when z = 10 then 10
				when z = 9 then 100
				when z = 8 then 300
				when z = 7 then 900
				when z = 6 then 1500
				when z <= 5 then 3000 
				ELSE 1 END
			   ) as simplify_tolerance
			),

			mvtgeom AS (
			  SELECT fid, operateur, dept,
				public.ST_AsMVTGeom(
					  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

			  FROM couverture_theorique t, bounds
			  WHERE public.ST_Intersects(t.geom, bounds.geom )
				and techno = in_techno 
				and niveau = 'TBC'
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		);
	end if;
end;
$$;


--
-- TOC entry 1872 (class 1255 OID 1736591)
-- Name: couvertures_test(integer, integer, integer, integer[], character varying[], integer[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.couvertures_test(z integer, x integer, y integer, liste_operateur integer[], liste_techno character varying[], liste_fid integer[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
    return (
		WITH
		bounds AS (
		  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
		 (CASE 
			when z >= 12 then 0
			when z = 11 then 0
			when z = 10 then 0
			when z = 9 then 100
			when z = 8 then 300
			when z = 7 then 900
			when z = 6 then 1500
			when z <= 5 then 3000 
			ELSE 1 END
		   ) as simplify_tolerance
		),

		mvtgeom AS (
		  SELECT fid, operateur, date, techno, usage, niveau, dept, filename,
			public.ST_AsMVTGeom(
				  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

		  FROM couverture_theorique t, bounds
		  WHERE public.ST_Intersects(t.geom, bounds.geom )
		  	and operateur = any(liste_operateur)
		  	and techno = any(liste_techno)
		  	and fid = any(liste_fid)
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1873 (class 1255 OID 1736592)
-- Name: couvertures_test_ex(integer, integer, integer, integer[], character varying[], integer[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.couvertures_test_ex(z integer, x integer, y integer, liste_operateur integer[], liste_techno character varying[], liste_fid integer[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
    return (
		WITH
		bounds AS (
		  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
		 (CASE 
			when z >= 12 then 0
			when z = 11 then 0
			when z = 10 then 0
			when z = 9 then 100
			when z = 8 then 300
			when z = 7 then 900
			when z = 6 then 1500
			when z <= 5 then 3000 
			ELSE 1 END
		   ) as simplify_tolerance
		),

		mvtgeom AS (
		  SELECT fid, operateur, date, techno, usage, niveau, dept, 
			public.ST_AsMVTGeom(
				  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

		  FROM couverture_theorique t, bounds
		  WHERE public.ST_Intersects(t.geom, bounds.geom )
		  	and operateur = any(liste_operateur)
		  	and techno = any(liste_techno)
		  	and fid != any(liste_fid)
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1874 (class 1255 OID 1736593)
-- Name: couvertures_union(integer, integer, integer, integer[], character varying[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.couvertures_union(z integer, x integer, y integer, liste_operateur integer[], liste_techno character varying[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
    return (
		WITH
		bounds AS (
		  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
		 (CASE 
			when z >= 12 then 0
			when z = 11 then 0
			when z = 10 then 0
			when z = 9 then 0
			when z = 8 then 200
			when z = 7 then 250
			when z = 6 then 300
			when z <= 5 then 400
			ELSE 1 END
		   ) as simplify_tolerance
		),

		mvtgeom AS (
		  SELECT fid, operateur, date, techno, usage, niveau, dept, 
			public.ST_AsMVTGeom(
				  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

		  FROM couverture_theorique_union t, bounds
		  WHERE public.ST_Intersects(t.geom, bounds.geom )
		  	and operateur = any(liste_operateur)
		  	and techno = any(liste_techno)
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1875 (class 1255 OID 1736594)
-- Name: debug_layer(integer, integer, integer); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.debug_layer(z integer, x integer, y integer) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

begin
	return (
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope(z, x, y) AS geom
		),
		mvtgeom AS (
			select t.fid, id_hexa, bitrate_dl, public.ST_AsMVTGeom(geometry_centroid, bounds.geom) as geom 
			FROM mrm_private.qos t
			INNER JOIN mrm_private.hexa_30m h30 ON h30.fid = id_hexa
			INNER JOIN bounds ON public.ST_Intersects(geometry_centroid, bounds.geom )
			WHERE mcc_mnc is not null  AND lower(protocole) = 'download'
			AND id_data_source_desc = 4 AND is_metropole = true 
			AND is_transport = false AND bitrate_dl is not null 
			AND bitrate_dl > 30 and geometry_centroid is not null
		)
		SELECT ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1877 (class 1255 OID 1736595)
-- Name: debug_supports_cluster_techno(integer, integer, integer, integer[], text[], text); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.debug_supports_cluster_techno(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text) RETURNS text
    LANGUAGE plpgsql
    AS $_$

DECLARE 
	querystr text;
	queryFilter text;
	filter_techno_global text;
	bAllOperator boolean;
	filter_techno text;
	schema_function text;
begin

	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	filter_techno_global := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := ' AND s.site_strategique = true ';
    end if ; 
    
	querystr := '
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
		),
		support_filter AS (
			SELECT distinct t.fid
			FROM anfr_sup_support t
			INNER JOIN site s ON s.id_station_anfr = sta_nm_anfr
			INNER JOIN bounds ON public.ST_Intersects(t.geom, public.ST_Buffer(bounds.geom, 100000) )
			WHERE code_op = any($4) ' || filter_techno_global || ' 
		),
		tot_com AS (
			select gid, count(1) as tot_support
			from commune c
			INNER JOIN anfr_sup_support t ON public.ST_contains(c.geom, t.geom )
			INNER JOIN support_filter s ON s.fid = t.fid
			group by gid
			having count(1) > 0
		),
		mvtgeom AS (
		  SELECT c.gid, tot_support, ''com'' as niveau, 
		  c.insee_dep as code_dep, concat($1,''|'',$2,''|'',$3) as tile, 
			public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, $5 as allop
		  FROM commune c
			INNER JOIN bounds ON public.ST_Intersects(c.geom, bounds.geom )
			LEFT JOIN tot_com ON  c.gid = tot_com.gid
			WHERE tot_support is not null
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	';
		
    return querystr;
end;
$_$;


--
-- TOC entry 1878 (class 1255 OID 1736596)
-- Name: fc_qos(integer, integer, integer, text, text, text[], text[], text, character varying, character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_qos(z integer, x integer, y integer, operator text, protocole text, situation text[], strate text[], datasource text, metropole character varying, habitation character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	fieldsquery text;
	fieldsquery_cluster text;
	groupbyquery text;
	wherequery text;
	resultquery bytea;
	casequery text;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
    
    if array_length(situation, 1) is null then 
		return null;
	end if ; 
    
    if array_length(strate, 1) is null then 
		return null;
	end if ; 
    
	wherequery := fc_qos_filterbuilder(operator, protocole, situation, strate, datasource, metropole, habitation);
	
	groupbyquery := '';
	
	if lower(protocole) = 'web' then
		fieldsquery_cluster:= ' , 
			count(case when loaded_in_less_5_secondes then 1 end) as success,
			count(case when 
				loaded_in_less_5_secondes = false 
				and loaded_in_less_10_secondes 
				then 1 end) as success_partial,
			count(case when 
				loaded_in_less_5_secondes = false 
				and loaded_in_less_10_secondes = false 
				then 1 end) as fail, 
				floor(count(1) / 2) as majority ';
		fieldsquery:= ' , loaded_in_less_5_secondes, loaded_in_less_10_secondes ';
		casequery:= ' , 
			case 
				when success > majority then 0 
				when success_partial > majority then 5 
				when success + success_partial > majority then 5
				else 10 
			end as acess_duration ';
	elsif lower(protocole) = 'stream' then
		fieldsquery_cluster:= ' , 
			count(case when quality_perfect = true then 1 end) as parfaite,
			count(case when quality_perfect = false and quality_correct = true then 1 end) as correcte,
			count(case when quality_perfect = false and quality_correct = false then 1 end) as echec, 
			floor(count(1) / 2) as majority ';
		fieldsquery:= ' , quality_perfect, quality_correct ';
		casequery:= ' , 
			case 
				when parfaite > majority then true else false
			end as quality_perfect,
			case 
				when not parfaite > majority and parfaite + correcte > majority then true else false
			end as quality_correct ';
		--groupbyquery := ' , video_en_qualite_parfaite, video_en_qualite_correcte ';
	elsif lower(protocole) = 'upload' then
		fieldsquery_cluster:=  ' , 
			count(case when upload_ok = true then 1 end) as success,
			count(case when upload_ok = false then 1 end) as echec ';
		fieldsquery:=  ' , upload_ok ';
		casequery := ' , case when success > echec then true else false end as upload_ok ';
		wherequery:= wherequery || ' AND upload_ok is not null ';
	elsif lower(protocole) = 'download' then
		fieldsquery_cluster:=  ' , 
			count(case when bitrate_dl < 3 then 1 end) as val0_3,
			count(case when bitrate_dl >= 3 and bitrate_dl < 8 then 1 end) as val3_8,
			count(case when bitrate_dl >= 8 and bitrate_dl < 30 then 1 end) as val8_30,
			count(case when bitrate_dl >= 30 then 1 end) as val30,
			floor(count(1) / 2) as majority';
		fieldsquery:= ' , bitrate_dl ';
		casequery:= ' , 
			case 
				when val30 > majority then 31 
				when val8_30 > majority then 20 
				when val3_8 > majority then 5
				when val0_3 > majority then 1
				when val30 + val8_30 > majority then 20
				when val30 + val3_8 > majority then 5
				when val30 + val8_30 + val3_8 > majority then 5
				when val30 + val0_3 > majority then 1
				when val8_30 + val3_8 > majority then 5
				when val8_30 + val0_3 > majority then 1
				when val3_8 + val0_3 > majority then 1
				when val30 + val8_30 + val3_8 <= majority then 1
			end as bitrate_dl ';
		wherequery:= wherequery || ' AND bitrate_dl is not null ';
	elsif lower(protocole) = 'voix' then
		fieldsquery_cluster:= ' , 
			count(case when min_mos_couple >= 2.1 and real_communiation_time = 120 then 1 end) as success,
			count(case when min_mos_couple < 2.1 and real_communiation_time = 120 then 1 end) as partial_success,
			count(case when real_communiation_time <> 120 then 1 end) as fail, 
			floor(count(1) / 2) as majority';
		fieldsquery:= ' , min_mos_couple, real_communiation_time ';
		casequery:= ' , case 
				when success > majority then 2 
				when partial_success > majority then 1 
				when fail > majority then 0
				when success + partial_success > majority then 1
				when fail + partial_success > majority then 0
				when success = fail and partial_success = 0 then 0
				when success + partial_success = fail then 0
			end as status ';
		wherequery:= wherequery || ' AND real_communiation_time is not null ';
	elsif lower(protocole) = 'sms' then
		fieldsquery_cluster:= ' , 
			count(case when sms_delai <= 10 then 1 end) as nb_pass,
			count(case when sms_delai > 10 then 1 end) as nb_fail ';
		fieldsquery:= ' , sms_delai ';
		casequery:= ' , case when nb_pass > nb_fail then 5 else 15 END  as sms_delai ';
		wherequery:= wherequery || ' AND sms_delai is not null ';
	end if; 
	
	queryst := '
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		selected_obj as (
			SELECT 
			t.id_hexa, 
			t.fid
			'|| fieldsquery ||'
			FROM bounds 
			INNER JOIN hexa_30m h30 ON public.ST_contains(bounds.geom, h30.geometry_centroid) 
			INNER JOIN qos t ON h30.fid = t.id_hexa 
			 '|| wherequery ||'
		),
		 stat_obj as (
			SELECT 
			 	id_hexa, 
				array_agg(fid) AS fids 
			'|| fieldsquery_cluster ||'
			from selected_obj
			GROUP BY id_hexa
			' || groupbyquery || '
		),
		mvtgeom AS (
			select 
			id_hexa as cid, 
			id_hexa as id, 
			public.ST_AsMVTGeom(geometry_centroid, bounds.geom) as geom,
			fids
			'|| casequery ||'
			from stat_obj s, bounds, hexa_30m h30
			WHERE h30.fid = s.id_hexa 
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	';
	EXECUTE queryst INTO resultquery;
	return resultquery;
end;
$$;


--
-- TOC entry 1879 (class 1255 OID 1736598)
-- Name: fc_qos_filterbuilder(text, text, text[], text[], text, character varying, character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_qos_filterbuilder(operator text, protocole text, situation text[], strate text[], datasource text, metropole character varying, habitation character varying) RETURNS text
    LANGUAGE plpgsql
    AS $_$

DECLARE 
	queryst text;
	elt_strate text;
	strin_strate text;
	other_strate text;
    situtation_where text;
	datasourceval integer;
	metropoleval boolean;
	habitationval boolean;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	queryst := ' WHERE mcc_mnc is not null ' ;
	if operator <> 'all' and operator <> '' then
		queryst := queryst || ' AND mcc_mnc = ' || operator::int;
	end if;
	
	if protocole <> '' then 
		if lower(protocole) = 'upload' then
			queryst := queryst || ' AND lower(protocole) in (''upload'', ''ulh'')';
		else
			queryst := queryst || ' AND lower(protocole) = ''' || lower(protocole) || '''';
		end if;
	end if; 
	
	situtation_where := '';
	if ARRAY_LENGTH(situation, 1) < 3 then
    	situtation_where := format(' AND upper(situation) = any(array[''%1$s'']) ', array_to_string(situation, ''',''')) ;
	end if;
	
	queryst := queryst || situtation_where ;
	
	if strate is null then
		queryst := queryst || ' AND lower(zone) = ''99999*''';
	else 
		if ARRAY_LENGTH(strate, 1) < 5 then
			strin_strate := '';
			other_strate := '';
			FOREACH elt_strate IN ARRAY strate LOOP
				if lower(elt_strate) = 'others' then
					other_strate := ' UPPER(public.unaccent(zone)) NOT IN (''ZONES INTERMEDIAIRES'',''ZONES DENSES'',''ZONES TOURISTIQUES'',''ZONES RURALES'')';
				else
					if strin_strate <> '' then
						strin_strate := strin_strate || ''',''';
					end if;
					strin_strate := strin_strate || lower(elt_strate);
				end if;
			END LOOP;
			
			if strin_strate = '' then 
				queryst := queryst || ' AND ' || other_strate ;
			elseif other_strate = '' then 
				queryst := queryst || ' AND lower(public.unaccent(zone)) IN (''' || strin_strate ||''')';
			else
				queryst := queryst || ' AND (lower(public.unaccent(zone)) IN (''' || strin_strate ||''') OR '|| other_strate ||')';
			end if;
			
		end if;	
	end if;
	
	if datasource = '' then 
		datasourceval = 1;
	else 
		datasourceval = datasource::integer;
	end if;
	queryst := queryst || ' AND id_data_source_desc = ' || datasourceval ;
	
	metropoleval = true;
	if metropole <> '1' then 
		metropoleval = false;
	end if;
	queryst := queryst || ' AND is_metropole = ' || metropoleval ;
	
		
	habitationval = true;
	if habitation <> '1' then 
		habitationval = false;
	end if;
	queryst := queryst || ' AND is_transport = ' || not habitationval ;
	
	return queryst;
end;
$_$;


--
-- TOC entry 1880 (class 1255 OID 1736599)
-- Name: fc_qos_filterbuilder(text, text, text, text[], text, character varying, character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_qos_filterbuilder(operator text, protocole text, situation text, strate text[], datasource text, metropole character varying, habitation character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE
queryst text;
elt_strate text;
strin_strate text;
other_strate text;
datasourceval integer;
metropoleval boolean;
habitationval boolean;
schema_function text;
begin
schema_function := public.parent_schema();
PERFORM set_config('search_path', schema_function, TRUE);
queryst := ' WHERE mcc_mnc is not null ' ;
if operator <> 'all' and operator <> '' then
queryst := queryst || ' AND mcc_mnc = ' || operator::int;
end if;

if protocole <> '' then
if lower(protocole) = 'upload' then
queryst := queryst || ' AND lower(protocole) in (''upload'', ''ulh'')';
else
queryst := queryst || ' AND lower(protocole) = ''' || lower(protocole) || '''';
end if;
end if;

if lower(situation) <> 'toutes' and situation <> '' then
queryst := queryst || ' AND lower(situation) = ''' || lower(situation) || '''';
end if;

if strate is null then
queryst := queryst || ' AND lower(zone) = ''99999*''';
else
if ARRAY_LENGTH(strate, 1) < 5 then
strin_strate := '';
other_strate := '';
FOREACH elt_strate IN ARRAY strate LOOP
if lower(elt_strate) = 'others' then
other_strate := ' UPPER(unaccent(zone)) NOT IN (''ZONES INTERMEDIAIRES'',''ZONES DENSES'',''ZONES TOURISTIQUES'',''ZONES RURALES'')';
else
if strin_strate <> '' then
strin_strate := strin_strate || ''',''';
end if;
strin_strate := strin_strate || lower(elt_strate);
end if;
END LOOP;

if strin_strate = '' then
queryst := queryst || ' AND ' || other_strate ;
elseif other_strate = '' then
queryst := queryst || ' AND lower(unaccent(zone)) IN (''' || strin_strate ||''')';
else
queryst := queryst || ' AND (lower(unaccent(zone)) IN (''' || strin_strate ||''') OR '|| other_strate ||')';
end if;

end if;
end if;

if datasource = '' then
datasourceval = 1;
else
datasourceval = datasource::integer;
end if;
queryst := queryst || ' AND id_data_source_desc = ' || datasourceval ;

metropoleval = true;
if metropole <> '1' then
metropoleval = false;
end if;
queryst := queryst || ' AND is_metropole = ' || metropoleval ;


habitationval = true;
if habitation <> '1' then
habitationval = false;
end if;
queryst := queryst || ' AND is_transport = ' || not habitationval ;

return queryst;
end;
$$;


--
-- TOC entry 1881 (class 1255 OID 1736600)
-- Name: fc_qos_transport(integer, integer, integer, text, text, text, text[], text, character varying, character varying, text[], character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_qos_transport(z integer, x integer, y integer, operator text, protocole text, situation text, strate text[], datasource text, metropole character varying, habitation character varying, axis text[] DEFAULT NULL::text[], axis_name character varying DEFAULT NULL::character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	fieldsquery text;
	fieldsquery_cluster text;
	casequery text;
	wherequery text;
	resultquery bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	wherequery := fc_qos_transport_filterbuilder(operator, protocole, situation, strate, datasource, metropole, habitation, axis, axis_name);
	
	wherequery:= wherequery || ' AND public.ST_Intersects(t.geometry, bounds.geom ) ';

	if lower(protocole) = 'web' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' acess_duration, loaded_in_less_10_secondes, loaded_in_less_5_secondes ';
		casequery:= ' , 
			case 
				when loaded_in_less_5_secondes then 0 
			else 
			case 
				when loaded_in_less_5_secondes = false AND 
				loaded_in_less_10_secondes then 5
			else 
			case 
				when loaded_in_less_5_secondes = false 
				and loaded_in_less_10_secondes = false then 10 
				else -1 end
			end 
			end as acess_duration ';
		--wherequery:= wherequery || ' AND acess_duration is not null AND loaded_in_less_10_secondes is not null AND loaded_in_less_5_secondes is not null ';
	end if; 
	if lower(protocole) = 'voix' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' min_mos_couple, real_communiation_time ';
		casequery:= ' , case when min_mos_couple >= 2.1 and real_communiation_time = 120 then 2 
			else 
				case when min_mos_couple < 2.1 and real_communiation_time = 120 then 1
			else 
				0 END END as status ';
		wherequery:= wherequery || ' AND real_communiation_time is not null ';
	end if;
	
	--fieldsquery := fieldsquery || ', public.ST_AsMVTGeom(geometry, bounds.geom) as geom';

	queryst := '
		
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		data_selected as (
			SELECT
			t.fid as id,
			array_agg(t.fid) ids,
			'|| fieldsquery ||', 
			t.geometry as geom
			FROM qos t, bounds
			 '|| wherequery ||'
			AND public.st_contains(bounds.geom, t.geometry)
			group by t.fid
		),
		mvtgeom AS (
			select 
			s.ids, 
			public.ST_AsMVTGeom(s.geom, bounds.geom) as geom
			'|| casequery ||'
			from data_selected s, bounds 
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	';
	
	--RAISE NOTICE 'queryst : %', queryst;
	
	EXECUTE queryst INTO resultquery;
	return resultquery;
end;
$$;


--
-- TOC entry 1882 (class 1255 OID 1736601)
-- Name: fc_qos_transport_debug(integer, integer, integer, text, text, text, text[], text, character varying, character varying, text[], character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_qos_transport_debug(z integer, x integer, y integer, operator text, protocole text, situation text, strate text[], datasource text, metropole character varying, habitation character varying, axis text[] DEFAULT NULL::text[], axis_name character varying DEFAULT NULL::character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	fieldsquery text;
	fieldsquery_cluster text;
	casequery text;
	wherequery text;
	--resultquery bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	wherequery := fc_qos_transport_filterbuilder(operator, protocole, situation, strate, datasource, metropole, habitation, axis, axis_name);
	
	wherequery:= wherequery || ' AND public.ST_Intersects(t.geometry, bounds.geom ) ';

	if lower(protocole) = 'web' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' acess_duration, loaded_in_less_10_secondes, loaded_in_less_5_secondes ';
		casequery:= ' , 
			case 
				when loaded_in_less_5_secondes then 0 
			else 
			case 
				when loaded_in_less_5_secondes = false AND 
				loaded_in_less_10_secondes then 5
			else 
			case 
				when loaded_in_less_5_secondes = false 
				and loaded_in_less_10_secondes = false then 10 
				else -1 end
			end 
			end as acess_duration ';
		--wherequery:= wherequery || ' AND acess_duration is not null AND loaded_in_less_10_secondes is not null AND loaded_in_less_5_secondes is not null ';
	end if; 
	if lower(protocole) = 'voix' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' crspa, real_communiation_time ';
		casequery:= ' , case when crspa then 2 
			else 
				case when crspa = false and real_communiation_time = 120 then 1
			else 
				0 END END as status ';
		wherequery:= wherequery || ' AND crspa is not null AND real_communiation_time is not null ';
	end if;
	
	--fieldsquery := fieldsquery || ', public.ST_AsMVTGeom(geometry, bounds.geom) as geom';

	queryst := '
		
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		data_selected as (
			SELECT
			t.fid as id,
			array_agg(t.fid) ids,
			'|| fieldsquery ||', 
			t.geometry as geom
			FROM mrm_private.qos t, bounds
			 '|| wherequery ||'
			AND public.st_contains(bounds.geom, t.geometry)
			group by t.fid
		),
		mvtgeom AS (
			select 
			s.ids, 
			public.ST_AsMVTGeom(s.geom, bounds.geom) as geom
			'|| casequery ||'
			from data_selected s, bounds 
		)
		SELECT *
		FROM mvtgeom limit 10
	';
	
	--RAISE NOTICE 'queryst : %', queryst;
	
	--EXECUTE queryst INTO resultquery;
	return queryst;
end;
$$;


--
-- TOC entry 1883 (class 1255 OID 1736602)
-- Name: fc_qos_transport_filterbuilder(text, text, text, text[], text, character varying, character varying, text[], character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_qos_transport_filterbuilder(operator text, protocole text, situation text, strate text[], datasource text, metropole character varying, habitation character varying, axis text[] DEFAULT NULL::text[], axis_name character varying DEFAULT NULL::character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	elt_strate text;
	strin_strate text;
	other_strate text;
	datasourceval integer;
	metropoleval boolean;
	habitationval boolean;
	schema_function text;
    elt_axis text;
	strin_axis text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	queryst := ' WHERE mcc_mnc is not null ' ;
	if operator <> 'all' and operator <> '' then
		queryst := queryst || ' AND mcc_mnc = ' || operator::int;
	end if;
	
	if protocole <> '' then 
		if lower(protocole) = 'upload' then
			queryst := queryst || ' AND lower(protocole) in (''upload'', ''ulh'')';
		else
			queryst := queryst || ' AND lower(protocole) = ''' || lower(protocole) || '''';
		end if;
	end if; 
	
	if lower(situation) <> 'toutes' and situation <> '' then 
		queryst := queryst || ' AND lower(situation) = ''' || lower(situation) || '''';
	end if; 
	
	if datasource = '' then 
		datasourceval = 1;
	else 
		datasourceval = datasource::integer;
	end if;
	queryst := queryst || ' AND id_data_source_desc = ' || datasourceval ;
	
	metropoleval = true;
	if metropole <> '1' then 
		metropoleval = false;
	end if;
	queryst := queryst || ' AND is_metropole = ' || metropoleval ;
	
		
	habitationval = true;
	if habitation <> '1' then 
		habitationval = false;
	end if;
	queryst := queryst || ' AND is_transport = ' || not habitationval ;
	
	if axis is not null and ARRAY_LENGTH(axis, 1) >= 1 then
        strin_axis := '';
		FOREACH elt_axis IN ARRAY axis LOOP
			if strin_axis <> '' then
				strin_axis := strin_axis || ',';
			end if;
			strin_axis := strin_axis || '''' || lower(public.unaccent(elt_axis)) || '''';
	  	END LOOP;
		queryst := queryst || ' AND axis IN (' ||  strin_axis || ')';
	end if;

	if axis_name is not null and trim(axis_name) != '' then 
		queryst := queryst || ' AND axis_name_search = ''' || lower(public.unaccent(axis_name)) || '''';
	end if;

	return queryst;
end;
$$;


--
-- TOC entry 1884 (class 1255 OID 1736603)
-- Name: fc_qos_transport_test(integer, integer, integer, text, text, text, text[], text, character varying, character varying, text[], character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_qos_transport_test(z integer, x integer, y integer, operator text, protocole text, situation text, strate text[], datasource text, metropole character varying, habitation character varying, axis text[] DEFAULT NULL::text[], axis_name character varying DEFAULT NULL::character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	fieldsquery text;
	fieldsquery_cluster text;
	casequery text;
	wherequery text;
	resultquery bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	wherequery := fc_qos_transport_filterbuilder(operator, protocole, situation, strate, datasource, metropole, habitation, axis, axis_name);
	
	wherequery:= wherequery || ' AND public.ST_Intersects(t.geometry, bounds.geom ) ';

	if lower(protocole) = 'web' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' acess_duration, loaded_in_less_10_secondes, loaded_in_less_5_secondes ';
		casequery:= ' , 
			case 
				when trunc(acess_duration) > 5 and loaded_in_less_10_secondes then 0 
			else 
			case 
				when trunc(acess_duration) > 10 and loaded_in_less_5_secondes then 5
				else 10 end 
			end as acess_duration ';
		wherequery:= wherequery || ' AND acess_duration is not null AND loaded_in_less_10_secondes is not null AND loaded_in_less_5_secondes is not null ';
	end if; 
	if lower(protocole) = 'voix' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' crspa, real_communiation_time ';
		casequery:= ' , case when crspa then 2 
			else 
				case when crspa = false and real_communiation_time = 120 then 1
			else 
				0 END END as status ';
		wherequery:= wherequery || ' AND crspa is not null AND real_communiation_time is not null ';
	end if;
	
	--fieldsquery := fieldsquery || ', public.ST_AsMVTGeom(geometry, bounds.geom) as geom';

	queryst := '
		
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		data_selected as (
			SELECT
			t.fid as id,
			array_agg(t.fid) ids,
			'|| fieldsquery ||', 
			t.geometry as geom
			FROM mrm_private.qos t, bounds
			 '|| wherequery ||'
			AND public.st_contains(bounds.geom, t.geometry)
			group by t.fid
		),
		mvtgeom AS (
			select 
			s.ids, 
			public.ST_AsMVTGeom(s.geom, bounds.geom) as geom
			'|| casequery ||'
			from data_selected s, bounds 
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	';
	
	--RAISE NOTICE 'queryst : %', queryst;
	
	EXECUTE queryst INTO resultquery;
	return resultquery;
end;
$$;


--
-- TOC entry 1885 (class 1255 OID 1736604)
-- Name: fc_signalement(integer, integer, integer, text, character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_signalement(z integer, x integer, y integer, operator text, metropole character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	wherequery text;
	resultquery bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	wherequery := fc_signalement_filterbuilder(operator, metropole);
	
	queryst := '
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		selected_obj as (
			SELECT 
                hs.fid as id, hs.geometry_intersect,
				public.st_centroid(public.st_transform(hs.geometry_intersect, 4326)) as ct_geom,
				count(1) as total
			FROM bounds 
			INNER JOIN hexa_signalement hs ON public.ST_intersects(bounds.geom, hs.geometry_intersect) 
			INNER JOIN signalement s ON s.id_hexa = hs.fid
			 '|| wherequery ||'
            GROUP BY hs.fid, hs.geometry_intersect, ct_geom
		),
		mvtgeom AS (
			SELECT 
                id, 
                total, 
				public.st_x(ct_geom) as x, 
				public.st_y(ct_geom) as y, 
			public.ST_AsMVTGeom(geometry_intersect, bounds.geom) as geom
			from selected_obj s, bounds
			where s.total > 0 
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	';
	EXECUTE queryst INTO resultquery;
	return resultquery;
end;
$$;


--
-- TOC entry 1886 (class 1255 OID 1736605)
-- Name: fc_signalement_debug(integer, integer, integer, text, character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_signalement_debug(z integer, x integer, y integer, operator text, metropole character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	wherequery text;
	--resultquery bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	wherequery := fc_signalement_filterbuilder(operator, metropole);
	
	queryst := '
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		selected_obj as (
			SELECT 
                hs.fid as id, hs.geometry, count(1) as total ,
				public.st_x(public.st_centroid(public.st_transform(geometry, ''epsg:3857'', 4326))) as x,
				public.st_y(public.st_centroid(public.st_transform(geometry, ''epsg:3857'', 4326))) as y
			FROM bounds 
			INNER JOIN mrm_private.hexa_signalement hs ON public.ST_contains(bounds.geom, st_centroid(hs.geometry)) 
			INNER JOIN mrm_private.signalement s ON s.id_hexa = hs.fid
			 '|| wherequery ||'
            GROUP BY hs.fid, hs.geometry, hs.x, hs.y
		),
		mvtgeom AS (
			SELECT 
                id, 
                total, x, y ,
			public.ST_AsMVTGeom(geometry, bounds.geom) as geom
			from selected_obj s, bounds
		)
		SELECT *
		FROM mvtgeom limit 10
	';
	return queryst;
end;
$$;


--
-- TOC entry 1887 (class 1255 OID 1736606)
-- Name: fc_signalement_filterbuilder(text, character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_signalement_filterbuilder(operator text, metropole character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	metropoleval boolean;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	queryst := ' WHERE operateur is not null ' ;
	if operator <> 'all' and operator <> '' then
		queryst := queryst || ' AND operateur = ' || operator::int;
	end if;
	
	metropoleval = true;
	if metropole <> '1' then 
		metropoleval = false;
	end if;
	queryst := queryst || ' AND is_metropole = ' || metropoleval ;
	
	return queryst;
end;
$$;


--
-- TOC entry 1888 (class 1255 OID 1736607)
-- Name: fc_site(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_site(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 

	filter_techno_global := '';
	filter_techno_site := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := 'true';
	else
		bAllOperator := 'false';
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := filter_techno_global || ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := filter_techno_global || ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := filter_techno_global || ' AND s.site_strategique = true ';
    end if ; 
    
	filter_techno_site := filter_techno_global;
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
    elseif array_length(state, 1) = 2 and 'en_maintenance' = ANY(state) and 'a_venir' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
    elseif array_length(state, 1) = 2 and 'en_service' = ANY(state) and 'a_venir' = ANY(state) then 
		filter_techno_site := ' AND st.id is null ';
    end if ; 
	
	querysite := format('
			SELECT distinct t.fid, 
			case when st.id is not null then true else false end as is_maintenance , 
			false as is_sav 
			FROM anfr_sup_support t
			INNER JOIN site s ON s.sup_id = t.sup_id 
			LEFT JOIN site_state st ON s.id_station_anfr = st.station_anfr
			WHERE code_op = any(array[%2$s]) %1$s', 
			filter_techno_site, 
			array_to_string(liste_operateur, ', ')
			) ;

	querysav := format('
			SELECT distinct t.fid, false as is_maintenance , true as is_sav 
			FROM anfr_sup_support t
			INNER JOIN site_a_venir s ON s.sup_id = t.sup_id 
			WHERE code_op = any(array[%2$s]) %1$s ', 
			filter_techno_global, 
			array_to_string(liste_operateur, ', ')
			) ;

	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 

	if ( z < 9) then
		--Vue par departement
		
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			tot_dept AS (
                select t.id_departement, count(1) as tot_support, 
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from anfr_sup_support t 
				INNER JOIN support_filter sf ON sf.fid = t.fid 
				WHERE 1=1
				group by t.id_departement
			),
			mvtgeom AS (
			  SELECT d.gid, tot_support, ''dept'' as niveau,  
				case when tot_maintenance = 0 and tot_sav = 0 then ''en_service'' 
				else case when tot_maintenance >= tot_sav then ''en_maintenance''
				else ''a_venir'' end end as state,
              d.insee_dep as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, %4$s as allop,
                concat(%1$s,''|'',%2$s,''|'',%3$s) as tile
			  FROM departement d
				INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
				LEFT JOIN tot_dept ON  d.gid = tot_dept.id_departement
				WHERE tot_support is not null
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		', z, x, y, bAllOperator);
		RAISE NOTICE 'Calling query (%)', queryst;
		EXECUTE queryst INTO result;
        return result;
		
	elsif ( z <= 10) then 
		--Vue par commune, On ajoute un buffer pour récupérer les supports autour de la tuile
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			tot_com AS (
				select com_cd_insee as insee_com, count(1) as tot_support, array_agg(t.fid) AS fids,
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from anfr_sup_support t  
				INNER JOIN support_filter sf ON sf.fid = t.fid
				group by t.com_cd_insee
				having count(1) > 0
			),
			mvtgeom AS (
			  SELECT c.gid, tot_support, fids, ''com'' as niveau, 
			  c.insee_dep as code_dep, concat(%1$s,''|'',%2$s,''|'',%3$s) as tile, 
				case when tot_maintenance = 0 and tot_sav = 0 then ''en_service'' 
				else case when tot_maintenance >= tot_sav then ''en_maintenance''
				else ''a_venir'' end end as state,
				public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, %4$s as allop
			  FROM commune c
				INNER JOIN bounds ON public.ST_Intersects(c.geom, bounds.geom )
				LEFT JOIN tot_com ON  c.insee_com = tot_com.insee_com 
				WHERE tot_support is not null
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		', z, x, y, bAllOperator);
		--RAISE NOTICE 'Calling query (%)', query;
		EXECUTE queryst INTO result;
        return result;
		
	elsif ( z <= 15) then 
		
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),	
			clustered_points AS (
                SELECT public.ST_ClusterDBSCAN(t.geom, eps := 
				 (CASE 
					when %1$s = 11 then 500
					when %1$s = 12 then 385
					when %1$s = 13 then 280
					when %1$s = 14 then 150
					when %1$s = 15 then 75
					ELSE 1 END
				   ) , minpoints := 1) over() AS cid, 
				is_maintenance,
				is_sav,
				t.fid, t.geom, t.sup_id
                FROM anfr_sup_support t
                INNER JOIN support_filter s ON s.fid = t.fid 
            ),
			grouped_data as (
				select cid, 
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav,
			  	count(1) as tot_support, 
				array_agg(c.fid) as fids, 
				public.ST_PointOnSurface(public.ST_Collect(c.geom)) as geom, 
				array_agg(c.sup_id) as sup_ids
				from clustered_points c, bounds
				where public.ST_Intersects(c.geom, bounds.geom )
				group by cid 
			),
			mvtgeom AS (
			  SELECT cid, sup_ids,fids, 
				case when tot_maintenance = 0 and tot_sav = 0 then ''en_service'' 
				else case when tot_maintenance >= tot_sav then ''en_maintenance''
				else ''a_venir'' end end as state,
			  tot_support, 
			  ''clust'' as niveau, (
			  	select insee_dep from departement t 
				where public.ST_contains(t.geom, c.geom)
			  ) as code_dep, 
				public.ST_AsMVTGeom(c.geom, bounds.geom) AS geom, %4$s as allop
			  FROM grouped_data c, bounds 
			  WHERE public.ST_Intersects(c.geom, bounds.geom )
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		', z, x, y, bAllOperator);
		--RAISE NOTICE 'Calling query (%)', query;
		EXECUTE queryst INTO result;
        return result;
	else 
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			attr_data AS (
			  SELECT t.fid, t.fid as idsup, ''supp'' as niveau,(
				select insee_dep from departement 
				where gid = t.id_departement
			  ) as code_dep, 
				is_maintenance, 
				is_sav, 
				t.geom AS geom, %4$s as allop
			  FROM anfr_sup_support t
			  INNER JOIN support_filter sf ON sf.fid = t.fid 
			  group by t.fid, is_maintenance, is_sav
			),
			mvtgeom as (
				SELECT  public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom, t.fid, t.idsup, 
				t.niveau, t.code_dep, 
				case when not is_maintenance and not is_sav then ''en_service'' 
				else case when is_maintenance then ''en_maintenance''
				else ''a_venir'' end end as state, 
				t.allop 
				FROM 
				attr_data t , bounds 
				WHERE public.ST_Intersects(t.geom, bounds.geom )
			)
            SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		', z, x, y, bAllOperator);
		EXECUTE queryst INTO result;
        return result;
	end if;
end;
$_$;


--
-- TOC entry 1889 (class 1255 OID 1736609)
-- Name: fc_site_a_venir(integer, integer, integer, integer[], text[], text); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_site_a_venir(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	query text;
	queryFilter text;
	filter_techno_global text;
	bAllOperator boolean;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 

	filter_techno_global := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := filter_techno_global || ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := filter_techno_global || ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := filter_techno_global || ' AND s.site_strategique = true ';
    end if ; 
    
	if ( z < 9) then
		--Vue par departement
		query := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, t.id_departement, false as is_sav 
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site s ON s.sup_id = t.sup_id 
				WHERE code_op = any($4) ' || filter_techno_global || '
                AND t.id_departement is not null
                
				UNION 
                
                SELECT distinct t.fid, t.id_departement, true as is_sav
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site_a_venir s ON s.sup_id = t.sup_id 
				WHERE code_op = any($4) ' || filter_techno_global || '
				AND t.id_departement is not null
			),
			tot_dept AS (
                select t.id_departement, count(1) as tot_support, 
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from mrm_private.anfr_sup_support t 
				INNER JOIN support_filter sf ON sf.fid = t.fid 
				WHERE 1=1
				group by t.id_departement
			),
			mvtgeom AS (
			  SELECT d.gid, tot_support, ''dept'' as niveau, 
				case when tot_sav = 0 then false else true end as is_sav, 
              d.insee_dep as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, '|| bAllOperator ||' as allop,
                concat($1,''|'',$2,''|'',$3) as tile
			  FROM mrm_private.departement d
				INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
				LEFT JOIN tot_dept ON  d.gid = tot_dept.id_departement
				WHERE tot_support is not null
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		';
		--RAISE NOTICE 'Calling query (%)', query;
		EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return result;
		
	elsif ( z <= 10) then 
		--Vue par commune, On ajoute un buffer pour récupérer les supports autour de la tuile
		query := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, t.com_cd_insee, false as is_sav
				FROM anfr_sup_support t
				INNER JOIN site s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, public.ST_Buffer(bounds.geom, 10000) )
				WHERE code_op = any($4) ' || filter_techno_global || ' 
				
				UNION 
                
                SELECT distinct t.fid, t.com_cd_insee, true as is_sav
				FROM mrm_private.anfr_sup_support t
				INNER JOIN site_a_venir s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, public.ST_Buffer(bounds.geom, 10000) )
				WHERE code_op = any($4) ' || filter_techno_global || '
				AND t.id_departement is not null
			),
			tot_com AS (
				select sf.com_cd_insee as insee_com, count(1) as tot_support,	
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from anfr_sup_support t  
				INNER JOIN support_filter sf ON sf.fid = t.fid
				group by sf.com_cd_insee
				having count(1) > 0
			),
			mvtgeom AS (
			  SELECT c.gid, tot_support, ''com'' as niveau, 
			  c.insee_dep as code_dep, concat($1,''|'',$2,''|'',$3) as tile, 
				case when tot_sav = 0 then false else true end as is_sav, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, $5 as allop
			  FROM commune c
				INNER JOIN bounds ON public.ST_Intersects(c.geom, bounds.geom )
				LEFT JOIN tot_com ON  c.insee_com = tot_com.insee_com 
				WHERE tot_support is not null
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		';
		--RAISE NOTICE 'Calling query (%)', query;
		EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return result;
		
	elsif ( z <= 15) then 
		
		query := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, false as is_sav 
				FROM anfr_sup_support t
				INNER JOIN site s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, bounds.geom )
				WHERE code_op = any($4) ' || filter_techno_global || '
				
				UNION 
                
                SELECT distinct t.fid, true as is_sav
				FROM mrm_private.anfr_sup_support t
				INNER JOIN site_a_venir s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, public.ST_Buffer(bounds.geom, 10000) )
				WHERE code_op = any($4) ' || filter_techno_global || '
				AND t.id_departement is not null
				
			),
			clustered_points AS (
                SELECT public.ST_ClusterDBSCAN(t.geom, eps := 
				 (CASE 
					when $1 = 11 then 500
					when $1 = 12 then 385
					when $1 = 13 then 280
					when $1 = 14 then 150
					when $1 = 15 then 75
					ELSE 1 END
				   ) , minpoints := 1) over() AS cid, 
				sum(case when is_sav then 1 else 0 end) as tot_sav,
				t.fid, t.geom, t.sup_id
                FROM anfr_sup_support t
                INNER JOIN support_filter s ON s.fid = t.fid 
				group by t.fid, t.geom, t.sup_id
            ),
			mvtgeom AS (
			  SELECT cid, array_agg(sup_id) as sup_ids,array_agg(fid) as fids,
			  case when sum(tot_sav) = 0 then false else true end as is_sav,
			  concat($1,''|'',$2,''|'',$3) as tile as tile,
			  count(1) as tot_support, 
			  ''clust'' as niveau, (
			  	select insee_dep from departement t 
				where public.ST_contains(t.geom, public.ST_Centroid(public.ST_Collect(c.geom)))
			  ) as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(public.ST_Collect(c.geom)), bounds.geom) AS geom, $5 as allop
			  FROM clustered_points c, bounds 
			  WHERE public.ST_Intersects(c.geom, bounds.geom )
				group by cid, bounds.geom
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		';
		RAISE NOTICE 'Calling query (%)', query;
		EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return result;
	else 
		query := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, false as is_sav 
				FROM anfr_sup_support t
				INNER JOIN site s ON s.sup_id = t.sup_id
				INNER JOIN bounds ON public.ST_Intersects(t.geom, bounds.geom )
				WHERE code_op = any($4) ' || filter_techno_global || '
				
				UNION 
				
				
				SELECT distinct t.fid, true as is_sav 
				FROM anfr_sup_support t
				INNER JOIN site_a_venir s ON s.sup_id = t.sup_id
				INNER JOIN bounds ON public.ST_Intersects(t.geom, bounds.geom )
				WHERE code_op = any($4) ' || filter_techno_global || '
			),
			attr_data AS (
			  SELECT t.fid, t.fid as idsup, ''supp'' as niveau,(
				select insee_dep from departement 
				where gid = t.id_departement
			  ) as code_dep, 
				is_sav, 
				concat($1,''|'',$2,''|'',$3) as tile as tile,
				t.geom AS geom, $5 as allop
			  FROM anfr_sup_support t
			  INNER JOIN support_filter sf ON sf.fid = t.fid 
			  group by t.fid, sf.is_sav
			),
			mvtgeom as (
				SELECT  public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom, t.fid, t.idsup, 
				t.niveau, t.code_dep, t.is_sav, t.allop 
				FROM 
				attr_data t , bounds 
				WHERE public.ST_Intersects(t.geom, bounds.geom )
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		';
		EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return result;
	end if;
end;
$_$;


--
-- TOC entry 1890 (class 1255 OID 1736611)
-- Name: fc_site_a_venir_debug(integer, integer, integer, integer[], text[], text); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_site_a_venir_debug(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text) RETURNS text
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	queryst text;
	queryFilter text;
	filter_techno_global text;
	bAllOperator boolean;
	filter_techno text;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 

	filter_techno_global := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := filter_techno_global || ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := filter_techno_global || ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := filter_techno_global || ' AND s.site_strategique = true ';
    end if ; 
    
	if ( z < 9) then
		--Vue par departement
		queryst := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, t.id_departement, false as is_sav 
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site s ON s.sup_id = t.sup_id 
				WHERE code_op = any(liste_operateur) ' || filter_techno_global || '
                AND t.id_departement is not null
                
				UNION 
                
                SELECT distinct t.fid, t.id_departement, true as is_sav
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site_a_venir s ON s.sup_id = t.sup_id 
				WHERE code_op = any(liste_operateur) ' || filter_techno_global || '
				AND t.id_departement is not null
			),
			tot_dept AS (
                select t.id_departement, count(1) as tot_support, 
				sum(case when id_sav is null then 0 else 1 end) as tot_sav
				from mrm_private.anfr_sup_support t 
				INNER JOIN support_filter sf ON sf.fid = t.fid 
				WHERE 1=1
				group by t.id_departement
			),
			mvtgeom AS (
			  SELECT d.gid, tot_support, ''dept'' as niveau, 
				case when tot_sav = 0 then false else true end as is_sav, 
              d.insee_dep as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, '|| bAllOperator ||' as allop,
                2 as tile
			  FROM mrm_private.departement d
				INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
				LEFT JOIN tot_dept ON  d.gid = tot_dept.id_departement
				WHERE tot_support is not null
			)
			SELECT * 
			FROM mvtgeom limit 10
		';
		--RAISE NOTICE 'Calling query (%)', query;
        return queryst;
		
	elsif ( z <= 10) then 
		--Vue par commune, On ajoute un buffer pour récupérer les supports autour de la tuile
		queryst := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, sav.id as id_sav
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, public.ST_Buffer(bounds.geom, 10000) )
				LEFT JOIN mrm_private.site_a_venir sav ON s.id_station_anfr = sav.station_anfr
				WHERE code_op = any(liste_operateur) ' || filter_techno_global || ' 
			),
			tot_com AS (
				select com_cd_insee as insee_com, count(1) as tot_support, array_agg(t.fid) AS fids,				
				sum(case when id_sav is null then 0 else 1 end) as tot_sav 
				from mrm_private.anfr_sup_support t  
				INNER JOIN mrm_private.support_filter sf ON sf.fid = t.fid
				group by t.com_cd_insee
				having count(1) > 0
			),
			mvtgeom AS (
			  SELECT c.gid, tot_support, fids, ''com'' as niveau, 
			  c.insee_dep as code_dep, 2 as tile, 
				case when tot_sav = 0 then false else true end as is_sav, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, '|| bAllOperator ||' as allop
			  FROM mrm_private.commune c
				INNER JOIN bounds ON public.ST_Intersects(c.geom, bounds.geom )
				LEFT JOIN tot_com ON  c.insee_com = tot_com.insee_com 
				WHERE tot_support is not null
			)
			SELECT * 
			FROM mvtgeom limit 10
		';
		--RAISE NOTICE 'Calling query (%)', query;
        return queryst;
		
	elsif ( z <= 15) then 
		
		queryst := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, sav.id as id_sav 
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, bounds.geom )
				LEFT JOIN mrm_private.site_a_venir sav ON s.id_station_anfr = sav.station_anfr
				WHERE code_op = any(liste_operateur) ' || filter_techno_global || '
			),
			clustered_points AS (
                SELECT public.ST_ClusterDBSCAN(t.geom, eps := 75 , minpoints := 1) over() AS cid, 
				sum(case when id_sav is null then 0 else 1 end) as tot_sav,
				t.fid, t.geom, t.sup_id
                FROM mrm_private.anfr_sup_support t
                INNER JOIN support_filter s ON s.fid = t.fid 
				group by t.fid, t.geom, t.sup_id
            ),
			mvtgeom AS (
			  SELECT cid, array_agg(sup_id) as sup_ids, 
			  array_agg(c.fid) as fids, 
			  case when sum(tot_sav) = 0 then false else true end as is_sav,
			  count(1) as tot_support, 
			  ''clust'' as niveau, (
			  	select insee_dep from mrm_private.departement t 
				where public.ST_contains(t.geom, public.ST_Centroid(public.ST_Collect(c.geom)))
			  ) as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(public.ST_Collect(c.geom)), bounds.geom) AS geom, '|| bAllOperator ||' as allop
			  FROM clustered_points c, bounds 
			  WHERE public.ST_Intersects(c.geom, bounds.geom )
				group by cid, bounds.geom
			)
			SELECT * 
			FROM mvtgeom limit 10
		';
        return queryst;
	else 
		queryst := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, sav.id as id_sav 
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site s ON s.sup_id = t.sup_id
				INNER JOIN bounds ON public.ST_Intersects(t.geom, bounds.geom )
				LEFT JOIN mrm_private.site_a_venir sav ON s.id_station_anfr = sav.station_anfr
				WHERE code_op = any(' || liste_operateur|| ') ' || filter_techno_global || '
			),
			attr_data AS (
			  SELECT t.fid, t.fid as idsup, ''supp'' as niveau,(
				select insee_dep from mrm_private.departement 
				where gid = t.id_departement
			  ) as code_dep, 
				case when id_sav is null then false else true end as is_sav, 
				t.geom AS geom, '|| bAllOperator ||' as allop
			  FROM mrm_private.anfr_sup_support t
			  INNER JOIN support_filter sf ON sf.fid = t.fid 
			  group by t.fid, id_sav
			),
			mvtgeom as (
				SELECT  public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom, t.fid, t.idsup, 
				t.niveau, t.code_dep, t.is_sav, t.allop 
				FROM 
				attr_data t , bounds 
				WHERE public.ST_Intersects(t.geom, bounds.geom )
			)
			SELECT * 
			FROM mvtgeom limit 10
		';
        return queryst;
	end if;
end;
$$;


--
-- TOC entry 1876 (class 1255 OID 1736613)
-- Name: fc_site_debug(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_site_debug(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS text
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	--result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 

	filter_techno_global := '';
	filter_techno_site := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := 'true';
	else
		bAllOperator := 'false';
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := filter_techno_global || ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := filter_techno_global || ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := filter_techno_global || ' AND s.site_strategique = true ';
    end if ; 
    
	filter_techno_site := filter_techno_global;
	
    if array_length(state, 1) = 1 and 'maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
    elseif array_length(state, 1) = 2 and 'maintenance' = ANY(state) and 'sav' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
    elseif array_length(state, 1) = 2 and 'service' = ANY(state) and 'sav' = ANY(state) then 
		filter_techno_site := ' AND st.id is null ';
    end if ; 
	
	querysite := format('
			SELECT distinct t.fid, 
			case when st.id is not null then true else false end as is_maintenance , 
			false as is_sav 
			FROM %1$s.anfr_sup_support t
			INNER JOIN %1$s.site s ON s.sup_id = t.sup_id 
			LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
			WHERE code_op = any(array[%3$s]) %2$s', 
			schema_function, 
			filter_techno_site, 
			array_to_string(liste_operateur, ', ')
			) ;

	querysav := format('
			SELECT distinct t.fid, false as is_maintenance , true as is_sav 
			FROM %1$s.anfr_sup_support t
			INNER JOIN %1$s.site_a_venir s ON s.sup_id = t.sup_id 
			WHERE code_op = any(array[%3$s]) %2$s ', 
			schema_function, 
			filter_techno_global, 
			array_to_string(liste_operateur, ', ')
			) ;

	if array_length(state, 1) = 1 and 'maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'sav' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'sav' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 

	if ( z < 9) then
		--Vue par departement
		
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			tot_dept AS (
                select t.id_departement, count(1) as tot_support, 
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from '||schema_function||'.anfr_sup_support t 
				INNER JOIN support_filter sf ON sf.fid = t.fid 
				WHERE 1=1
				group by t.id_departement
			),
			mvtgeom AS (
			  SELECT d.gid, tot_support, ''dept'' as niveau,  
				case when tot_maintenance = 0 and tot_sav = 0 then ''service'' 
				else case when tot_maintenance >= tot_sav then ''maintenance''
				else ''sav'' end end as state,
              d.insee_dep as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, %4$s as allop,
                concat(%1$s,''|'',%2$s,''|'',%3$s) as tile
			  FROM '||schema_function||'.departement d
				INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
				LEFT JOIN tot_dept ON  d.gid = tot_dept.id_departement
				WHERE tot_support is not null
			)
			SELECT *
			FROM mvtgeom limit 10
		', z, x, y, bAllOperator);
		--RAISE NOTICE 'Calling query (%)', query;
		--EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return queryst;
		
	elsif ( z <= 10) then 
		--Vue par commune, On ajoute un buffer pour récupérer les supports autour de la tuile
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			tot_com AS (
				select com_cd_insee as insee_com, count(1) as tot_support, array_agg(t.fid) AS fids,
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from '||schema_function||'.anfr_sup_support t  
				INNER JOIN support_filter sf ON sf.fid = t.fid
				group by t.com_cd_insee
				having count(1) > 0
			),
			mvtgeom AS (
			  SELECT c.gid, tot_support, fids, ''com'' as niveau, 
			  c.insee_dep as code_dep, concat(%1$s,''|'',%2$s,''|'',%3$s) as tile, 
				case when tot_maintenance = 0 and tot_sav = 0 then ''service'' 
				else case when tot_maintenance >= tot_sav then ''maintenance''
				else ''sav'' end end as state,
				public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, %4$s as allop
			  FROM '||schema_function||'.commune c
				INNER JOIN bounds ON public.ST_Intersects(c.geom, bounds.geom )
				LEFT JOIN tot_com ON  c.insee_com = tot_com.insee_com 
				WHERE tot_support is not null
			)
			SELECT *
			FROM mvtgeom limit 10
		', z, x, y, bAllOperator);
		--RAISE NOTICE 'Calling query (%)', query;
		--EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return queryst;
		
	elsif ( z <= 15) then 
		
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			clustered_points AS (
                SELECT public.ST_ClusterDBSCAN(t.geom, eps := 
				 (CASE 
					when %1$s = 11 then 500
					when %1$s = 12 then 385
					when %1$s = 13 then 280
					when %1$s = 14 then 150
					when %1$s = 15 then 75
					ELSE 1 END
				   ) , minpoints := 1) over() AS cid, 
				is_maintenance,
				is_sav,
				t.fid, t.geom, t.sup_id
                FROM '||schema_function||'.anfr_sup_support t
                INNER JOIN support_filter s ON s.fid = t.fid 
            ),
			grouped_data as (
				select cid, 
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav,
			  	count(1) as tot_support, 
				array_agg(c.fid) as fids, 
				public.ST_PointOnSurface(public.ST_Collect(c.geom)) as geom, 
				array_agg(c.sup_id) as supids
				from clustered_points c, bounds
				where public.ST_Intersects(c.geom, bounds.geom )
				group by cid 
			),
			mvtgeom AS (
						 
			  SELECT cid, array_agg(sup_id) as sup_ids, 
			  array_agg(c.fid) as fids, 
				case when tot_maintenance = 0 and tot_sav = 0 then ''en_service'' 
				else case when tot_maintenance >= tot_sav then ''en_maintenance''
				else ''a_venir'' end end as state,
			  count(1) as tot_support, 
			  ''clust'' as niveau, (
			  	select insee_dep from '||schema_function||'.departement t 
				where public.ST_contains(t.geom, public.ST_Centroid(public.ST_Collect(c.geom)))
			  ) as code_dep, 
				public.ST_AsMVTGeom(c.geom, bounds.geom) AS geom, %4$s as allop
			  FROM clustered_points c, bounds 
			  WHERE public.ST_Intersects(c.geom, bounds.geom )
				group by cid, bounds.geom
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		', z, x, y, bAllOperator);
		--RAISE NOTICE 'Calling query (%)', query;
		--EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return queryst;
	else 
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			attr_data AS (
			  SELECT t.fid, t.fid as idsup, ''supp'' as niveau,(
				select insee_dep from '||schema_function||'.departement 
				where gid = t.id_departement
			  ) as code_dep, 
				is_maintenance, 
				is_sav, 
				t.geom AS geom, %4$s as allop
			  FROM '||schema_function||'.anfr_sup_support t
			  INNER JOIN support_filter sf ON sf.fid = t.fid 
			  group by t.fid, is_maintenance, is_sav
			),
			mvtgeom as (
				SELECT  public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom, t.fid, t.idsup, 
				t.niveau, t.code_dep, 
				case when not is_maintenance and not is_sav then ''service'' 
				else case when is_maintenance then ''maintenance''
				else ''sav'' end end as state, 
				t.allop 
				FROM 
				attr_data t , bounds 
				WHERE public.ST_Intersects(t.geom, bounds.geom )
			)
			SELECT *
			FROM mvtgeom limit 10
		', z, x, y, bAllOperator);
		--EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return queryst;
	end if;
end;
$_$;


--
-- TOC entry 1891 (class 1255 OID 1736615)
-- Name: fc_support_cluster(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_support_cluster(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	
	if array_length(state, 1) is null then 
		return null;
	end if ; 
	
	PERFORM set_config('search_path', schema_function, TRUE); 
	if ( z < 9) then
		return fc_support_cluster_dept(z, x, y, liste_operateur,techonologies, dispositif, state);
	elsif ( z <= 10) then 
		return fc_support_cluster_com(z, x, y, liste_operateur,techonologies, dispositif, state);
	elsif ( z <= 15) then 
		return fc_support_cluster_clu(z, x, y, liste_operateur,techonologies, dispositif, state);
	else 
		return fc_support_cluster_sup(z, x, y, liste_operateur,techonologies, dispositif, state);
	end if;
end;
$$;


--
-- TOC entry 1892 (class 1255 OID 1736616)
-- Name: fc_support_cluster_clu(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_support_cluster_clu(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := mrm_private.fc_support_cluster_filterbuilder(
		liste_operateur, 
		techonologies, 
		dispositif, 
		state
	);
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	filter_techno_site := '';
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_maintenance' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is not null ';
    end if ; 
	
	filter_techno_site := filter_techno_global || filter_techno_site ;
	
	querysite := format('
		select s.sup_id, false as is_sav, 
		case when st.id is not null then true else false end as is_maintenance  
		from %1$s.site s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
		WHERE code_op = any(array[%3$s]) %2$s', 
		schema_function, 
		filter_techno_site, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	querysav := format('
		select s.sup_id, true as is_sav, false as is_maintenance
		from %1$s.site_a_venir s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		WHERE code_op = any(array[%3$s]) %2$s' , 
		schema_function, 
		filter_techno_global, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 
	
	queryst := format('
		WITH bounds AS (
			SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
		),
		list_sup_ids as (
            select sup_id from '||schema_function||'.anfr_sup_support t
            inner join bounds ON public.ST_Intersects(public.st_buffer(bounds.geom, 30), t.geom)
		),
		site_all as (
			'|| queryunion || '
		), 
		support_filter as (
            select distinct t.fid,  
            sum(
                case when is_maintenance then 1 else 0 end
            ) as nb_maintenance,  
            sum(
                case when not is_maintenance and is_sav then 1 else 0 end
            ) as nb_sav, 
            sum(
                case when not is_maintenance and not is_sav then 1 else 0 end
            ) as nb_service
            FROM '||schema_function||'.anfr_sup_support t
            INNER JOIN site_all s ON s.sup_id = t.sup_id 
            group by fid
        ),
        clustered_points AS (
            SELECT public.ST_ClusterDBSCAN(t.geom, eps := 
             (CASE 
                when %1$s = 11 then 500
                when %1$s = 12 then 385
                when %1$s = 13 then 280
                when %1$s = 14 then 150
                when %1$s = 15 then 75
                ELSE 1 END
               ) , minpoints := 1) over() AS cid, 
            case when nb_maintenance > 0 then ''en_maintenance'' 
                else case when nb_sav > 0 then ''a_venir''
                else ''en_service'' end 
            end as state ,
            t.fid, t.geom
            FROM '||schema_function||'.anfr_sup_support t
            INNER JOIN support_filter s ON s.fid = t.fid 
            group by t.fid, t.geom, nb_maintenance, nb_sav, nb_service
        ),
        agg_clu as (
            select cid, public.ST_Centroid(public.ST_Collect(geom)) as geom, 
            array_agg(fid) as fids,
            count(1) as tot_support,
            '||schema_function||'.fc_support_cluster_getmainstate(array_agg(state)) as state
            from clustered_points 
            group by cid
        ),
        mvtgeom AS (
          SELECT 
          fids, 
          state,
          tot_support::integer, 
          ''clust'' as niveau, (
            select insee_dep from '||schema_function||'.departement t 
            where public.ST_contains(t.geom, c.geom)
          ) as code_dep, 
            public.ST_AsMVTGeom(c.geom, bounds.geom) AS geom, %5$s as allop
          FROM agg_clu c, bounds 
          WHERE public.ST_contains(bounds.geom, c.geom)
        )
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom', z, x, y, schema_function, bAllOperator
	); 
	--RAISE NOTICE 'Calling query (%)', queryst;
	EXECUTE queryst INTO result ;
    return result;
	
end;
$_$;


--
-- TOC entry 1893 (class 1255 OID 1736618)
-- Name: fc_support_cluster_com(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_support_cluster_com(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := mrm_private.fc_support_cluster_filterbuilder(
		liste_operateur, 
		techonologies, 
		dispositif, 
		state
	);
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	filter_techno_site := '';
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_maintenance' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is not null ';
    end if ; 
	
	filter_techno_site := filter_techno_global || filter_techno_site ;
	
	querysite := format('
		select s.sup_id, false as is_sav, 
		case when st.id is not null then true else false end as is_maintenance  
		from %1$s.site s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
		WHERE code_op = any(array[%3$s]) %2$s', 
		schema_function, 
		filter_techno_site, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	querysav := format('
		select s.sup_id, true as is_sav, false as is_maintenance
		from %1$s.site_a_venir s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		WHERE code_op = any(array[%3$s]) %2$s' , 
		schema_function, 
		filter_techno_global, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 
	
	queryst := format('
		WITH bounds AS (
			SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
		),
		list_sup_ids as (
			select sup_id from '||schema_function||'.anfr_sup_support 
			where id_departement in (
				select gid from '||schema_function||'.departement d, bounds
				where public.ST_Intersects(d.geom, bounds.geom )
			)
		),
		site_all as (
			'|| queryunion || '
		), 
		support_filter as (
			select distinct t.fid,  
			sum(
				case when is_maintenance then 1 else 0 end
			) as nb_maintenance,  
			sum(
				case when not is_maintenance and is_sav then 1 else 0 end
			) as nb_sav, 
			sum(
				case when not is_maintenance and not is_sav then 1 else 0 end
			) as nb_service
			FROM '||schema_function||'.anfr_sup_support t
			INNER JOIN site_all s ON s.sup_id = t.sup_id 
			group by fid
		),
		tot_com_by_type as (
			select t.com_cd_insee, count(1) as tot_support, 
			sum(nb_maintenance) as nb_maintenance, 
			sum(nb_sav) as nb_sav,
			sum(nb_service) as nb_service,
			array_agg(t.fid ) as fids 
			from '||schema_function||'.anfr_sup_support t 
			INNER JOIN support_filter sf ON sf.fid = t.fid 
			WHERE 1=1
			group by t.com_cd_insee
		),
		agg_com as (
			select 
				com_cd_insee, 
				fids,
				sum(tot_support) as tot_support, 
				case when nb_maintenance > 0 then ''en_maintenance''
					else case when nb_sav > 0 then ''a_venir''
					else ''en_service'' end 
				end as state 
			from tot_com_by_type
			where com_cd_insee is not null
			group by com_cd_insee, fids, nb_maintenance, nb_sav 
		),
		mvtgeom AS (
		  SELECT c.gid, tot_support::integer, ''com'' as niveau, state,
		  c.insee_dep as code_dep, fids,
			public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, %5$s as allop,
			concat(%1$s,''|'',%2$s,''|'',%3$s) as tile
		  FROM '||schema_function||'.commune c
			INNER JOIN bounds ON public.ST_Intersects(public.ST_PointOnSurface(c.geom), bounds.geom )
			LEFT JOIN agg_com ON  c.insee_com = agg_com.com_cd_insee
			WHERE tot_support is not null
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom', z, x, y, schema_function, bAllOperator
	); 
	--RAISE NOTICE 'Calling query %', queryst;
	EXECUTE queryst INTO result ;
    return result;
	
end;
$_$;


--
-- TOC entry 1894 (class 1255 OID 1736620)
-- Name: fc_support_cluster_dept(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_support_cluster_dept(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := mrm_private.fc_support_cluster_filterbuilder(
		liste_operateur, 
		techonologies, 
		dispositif, 
		state
	);
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	filter_techno_site := '';
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_maintenance' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is not null ';
    end if ; 
	
	filter_techno_site := filter_techno_global || filter_techno_site ;
	
	querysite := format('
		select s.sup_id, false as is_sav, 
		case when st.id is not null then true else false end as is_maintenance  
		from %1$s.site s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
		WHERE code_op = any(array[%3$s]) %2$s', 
		schema_function, 
		filter_techno_site, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	querysav := format('
		select s.sup_id, true as is_sav, false as is_maintenance
		from %1$s.site_a_venir s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		WHERE code_op = any(array[%3$s]) %2$s' , 
		schema_function, 
		filter_techno_global, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 
	
	queryst := format('
		WITH bounds AS (
			SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
		),
		list_sup_ids as (
			select sup_id from '||schema_function||'.anfr_sup_support 
			where id_departement in (
				select gid from '||schema_function||'.departement d, bounds
				where public.ST_Intersects(d.geom, bounds.geom )
			)
		),
		site_all as (
			'|| queryunion || '
		), 
		support_filter as (
			select distinct t.fid,  
			sum(
				case when is_maintenance then 1 else 0 end
			) as nb_maintenance,  
			sum(
				case when not is_maintenance and is_sav then 1 else 0 end
			) as nb_sav, 
			sum(
				case when not is_maintenance and not is_sav then 1 else 0 end
			) as nb_service
			FROM '||schema_function||'.anfr_sup_support t
			INNER JOIN site_all s ON s.sup_id = t.sup_id 
			group by fid
		),
		tot_dept_by_type as (
			select t.id_departement, count(1) as tot_support, 
			sum(nb_maintenance) as nb_maintenance, 
			sum(nb_sav) as nb_sav,
			sum(nb_service) as nb_service,
			array_agg(t.fid ) as fids 
			from '||schema_function||'.anfr_sup_support t 
			INNER JOIN support_filter sf ON sf.fid = t.fid 
			WHERE 1=1
			group by t.id_departement
		),
		agg_dept as (
			select 
				id_departement, 
				fids,
				sum(tot_support) as tot_support, 
				case when nb_maintenance > 0 then ''en_maintenance''
					else case when nb_sav > 0 then ''a_venir''
					else ''en_service'' end 
				end as state 
			from tot_dept_by_type
			where id_departement is not null
			group by id_departement, fids, nb_maintenance, nb_sav 
		),
		mvtgeom AS (
		  SELECT d.gid, tot_support::integer, 
		  ''dept'' as niveau, state, fids,
		  d.insee_dep as code_dep, 
			public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, %5$s as allop,
			concat(%1$s,''|'',%2$s,''|'',%3$s) as tile
		  FROM '||schema_function||'.departement d
			INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
			LEFT JOIN agg_dept ON  d.gid = agg_dept.id_departement
			WHERE tot_support is not null
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom', z, x, y, schema_function, bAllOperator
	); 
	--RAISE NOTICE 'Calling query %', queryst;
	EXECUTE queryst INTO result ;
    return result;
	
end;
$_$;


--
-- TOC entry 1895 (class 1255 OID 1736622)
-- Name: fc_support_cluster_dept_debug(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_support_cluster_dept_debug(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS text
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := mrm_private.fc_support_cluster_filterbuilder(
		liste_operateur, 
		techonologies, 
		dispositif, 
		state
	);
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	filter_techno_site := '';
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_maintenance' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is not null ';
    end if ; 
	
	filter_techno_site := filter_techno_global || filter_techno_site ;
	
	querysite := format('
		select s.sup_id, false as is_sav, 
		case when st.id is not null then true else false end as is_maintenance  
		from %1$s.site s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
		WHERE code_op = any(array[%3$s]) %2$s', 
		schema_function, 
		filter_techno_site, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	querysav := format('
		select s.sup_id, true as is_sav, false as is_maintenance
		from %1$s.site_a_venir s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		WHERE code_op = any(array[%3$s]) %2$s' , 
		schema_function, 
		filter_techno_global, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 
	
	queryst := format('
		WITH bounds AS (
			SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
		),
		list_sup_ids as (
			select sup_id from '||schema_function||'.anfr_sup_support 
			where id_departement in (
				select gid from '||schema_function||'.departement d, bounds
				where public.ST_Intersects(d.geom, bounds.geom )
			)
		),
		site_all as (
			'|| queryunion || '
		), 
		support_filter as (
			select distinct t.fid,  
			sum(
				case when is_maintenance then 1 else 0 end
			) as nb_maintenance,  
			sum(
				case when not is_maintenance and is_sav then 1 else 0 end
			) as nb_sav, 
			sum(
				case when not is_maintenance and not is_sav then 1 else 0 end
			) as nb_service
			FROM '||schema_function||'.anfr_sup_support t
			INNER JOIN site_all s ON s.sup_id = t.sup_id 
			group by fid
		),
		tot_dept_by_type as (
			select t.id_departement, count(1) as tot_support, array_agg(t.fid ) as fids,
			case when nb_maintenance > 0 then ''en_maintenance'' 
				else case when nb_sav > 0 then ''a_venir'' 
				else ''en_service'' end 
			end as state 
			from '||schema_function||'.anfr_sup_support t 
			INNER JOIN support_filter sf ON sf.fid = t.fid 
			WHERE 1=1
			group by t.id_departement, sf.nb_maintenance, sf.nb_sav
		),
		agg_dept as (
			select 
				id_departement, 
				fids,
				sum(tot_support) as tot_support, 
			    '||schema_function||'.fc_support_cluster_getmainstate(array_agg(state)) as state
			from tot_dept_by_type 
			where id_departement is not null
			group by id_departement, fids
		),
		mvtgeom AS (
		  SELECT d.gid, tot_support::integer, 
		  ''dept'' as niveau, state, fids,
		  d.insee_dep as code_dep, 
			public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, %5$s as allop,
			concat(%1$s,''|'',%2$s,''|'',%3$s) as tile
		  FROM '||schema_function||'.departement d
			INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
			LEFT JOIN agg_dept ON  d.gid = agg_dept.id_departement
			WHERE tot_support is not null
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom', z, x, y, schema_function, bAllOperator
	); 
	--RAISE NOTICE 'Calling query %', queryst;
	--EXECUTE queryst INTO result ;
    return queryst;
	
end;
$_$;


--
-- TOC entry 1896 (class 1255 OID 1736624)
-- Name: fc_support_cluster_filterbuilder(integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_support_cluster_filterbuilder(liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	filter_techno_global text;
	filter_techno text;
	schema_function text;
	bAllOperator text;
begin

	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := 'true';
	else
		bAllOperator := 'false';
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := filter_techno_global || ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := filter_techno_global || ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := filter_techno_global || ' AND s.site_strategique = true ';
    end if ; 
    return filter_techno_global ;
end;
$$;


--
-- TOC entry 1897 (class 1255 OID 1736625)
-- Name: fc_support_cluster_getmainstate(text[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_support_cluster_getmainstate(state text[]) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	resultstate text;
begin
	resultstate := 'en_service';
	if 'en_maintenance' = ANY(state) then 
		resultstate := 'en_maintenance';
	elseif 'a_venir' = ANY(state) then 
		resultstate := 'a_venir';
	end if;
	return resultstate;
end;
$$;


--
-- TOC entry 1898 (class 1255 OID 1736626)
-- Name: fc_support_cluster_sup(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_support_cluster_sup(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := mrm_private.fc_support_cluster_filterbuilder(
		liste_operateur, 
		techonologies, 
		dispositif, 
		state
	);
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	filter_techno_site := '';
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_maintenance' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is not null ';
    end if ;  
	
	
	filter_techno_site := filter_techno_global || filter_techno_site ;
	
	querysite := format('
		select s.sup_id, false as is_sav, 
		case when st.id is not null then true else false end as is_maintenance  
		from %1$s.site s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
		WHERE code_op = any(array[%3$s]) %2$s', 
		schema_function, 
		filter_techno_site, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	querysav := format('
		select s.sup_id, true as is_sav, false as is_maintenance
		from %1$s.site_a_venir s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		WHERE code_op = any(array[%3$s]) %2$s' , 
		schema_function, 
		filter_techno_global, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 
	
	queryst := format('
		WITH bounds AS (
			SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
		),
		list_sup_ids as (
            select sup_id from '||schema_function||'.anfr_sup_support t
            inner join bounds ON public.ST_Intersects(public.st_buffer(bounds.geom, 30), t.geom)
		),
		site_all as (
			'|| queryunion || '
		), 
		support_filter as (
            select distinct t.fid, geom, t.id_departement,
            sum(
                case when is_maintenance then 1 else 0 end
            ) as nb_maintenance,  
            sum(
                case when not is_maintenance and is_sav then 1 else 0 end
            ) as nb_sav, 
            sum(
                case when not is_maintenance and not is_sav then 1 else 0 end
            ) as nb_service
            FROM %4$s.anfr_sup_support t
            INNER JOIN site_all s ON s.sup_id = t.sup_id 
            group by fid, id_departement
        ),
        support_filter_class as (
			select fid, geom, case when nb_maintenance > 0 then ''en_maintenance'' 
                else case when nb_sav > 0 then ''a_venir''
                else ''en_service'' end 
            end as state,
			''supp'' as niveau,
			(
				select insee_dep from %4$s.departement 
				where gid = t.id_departement
			  ) as code_dep
			from support_filter t
        ),
		mvtgeom AS (
			SELECT  
				fid, state, niveau, code_dep, 
				public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom
				FROM 
				support_filter_class t , bounds 
				WHERE public.ST_Intersects(t.geom, bounds.geom )
        )
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom', z, x, y, schema_function, bAllOperator
	); 
	RAISE NOTICE 'Calling query (%)', queryst;
	EXECUTE queryst INTO result ;
    return result;
	
end;
$_$;


--
-- TOC entry 1899 (class 1255 OID 1736627)
-- Name: fc_zac_poi(integer, integer, integer, text); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.fc_zac_poi(z integer, x integer, y integer, operateur text) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

DECLARE 
	query text;
	subquery text;
	schema_function text;
	result bytea;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 

	if (operateur = 'all') then 
		subquery := 'select id, z.id_point, num_zone_arrete, geom from zac_poi z';
	else
		subquery := 'select id, z.id_point, num_zone_arrete, geom from zac_poi z
inner join zac_poi_operateurs op ON op.id_point = z.id_point
where op.id_operateur = '||operateur ;
	end if;
	
    query := '
        WITH
        bounds AS (
            SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
        ),
        zac_filter AS (' || subquery || '),
        mvtgeom AS (
          SELECT public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom, t.id, t.id_point, t.num_zone_arrete
          FROM zac_filter t, bounds
          WHERE public.ST_Intersects(t.geom, bounds.geom )
        )
        SELECT public.ST_AsMVT(mvtgeom)
        FROM mvtgeom
    ';
    EXECUTE query INTO result USING z, x, y;
    return result;
end;
$_$;


--
-- TOC entry 1901 (class 1255 OID 1736628)
-- Name: generate_couvertures_tbc_tiles(integer, integer, integer, character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.generate_couvertures_tbc_tiles(z integer, x integer, y integer, in_techno character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	return (
		WITH
		bounds AS (
		  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
		 (CASE 
			when z >= 12 then 0
			when z = 11 then 0
			when z = 10 then 10
			when z = 9 then 100
			when z = 8 then 300
			when z = 7 then 900
			when z = 6 then 1500
			when z <= 5 then 3000 
			ELSE 1 END
		   ) as simplify_tolerance
		),

		mvtgeom AS (
		  SELECT fid, operateur, dept,
			public.ST_AsMVTGeom(
				  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

		  FROM couverture_theorique t, bounds
		  WHERE public.ST_Intersects(t.geom, bounds.geom )
			and techno = in_techno 
			and niveau = 'TBC'
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1902 (class 1255 OID 1736629)
-- Name: generate_couvertures_tiles(integer, integer, integer, bigint, character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.generate_couvertures_tiles(z integer, x integer, y integer, liste_operateur bigint, liste_techno character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	return (
		WITH
		bounds AS (
		  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
		 (CASE 
			when z >= 12 then 0
			when z = 11 then 0
			when z = 10 then 10
			when z = 9 then 100
			when z = 8 then 300
			when z = 7 then 900
			when z = 6 then 1500
			when z <= 5 then 3000 
			ELSE 1 END
		   ) as simplify_tolerance
		),

		mvtgeom AS (
		  SELECT fid, operateur, date, techno, usage, niveau, dept, filename,
			public.ST_AsMVTGeom(
				  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

		  FROM couverture_theorique t, bounds
		  WHERE public.ST_Intersects(t.geom, bounds.geom )
			and operateur = liste_operateur
			and techno = liste_techno
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1903 (class 1255 OID 1736630)
-- Name: generate_hexa_layer(); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.generate_hexa_layer() RETURNS TABLE(fid bigint, geom public.geometry)
    LANGUAGE plpgsql
    AS $$
	
DECLARE 
	code_operateur_result text;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE);
	RETURN QUERY (with pts as (
		select geometry from qos
	)
	SELECT row_number() over () as fid, hex.geom
	FROM pts 
	--30 ou 300, à vérifier
	INNER JOIN public.ST_HexagonGrid(300, pts.geometry) AS hex ON public.ST_Intersects(pts.geometry, hex.geom)
	group by hex.geom);
end;
$$;


--
-- TOC entry 1904 (class 1255 OID 1736631)
-- Name: generate_hexa_signalement(integer); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.generate_hexa_signalement(radius integer) RETURNS TABLE(fid bigint, geom public.geometry)
    LANGUAGE plpgsql
    AS $$
	
DECLARE 
	code_operateur_result text;
	schema_function text;
begin
	schema_function := public.parent_schema();
	RAISE NOTICE 'schema_function: %', schema_function;
	PERFORM set_config('search_path', schema_function, TRUE);
	RETURN QUERY (with pts as (
		select geometry from signalement
	)
	SELECT row_number() over () as fid, hex.geom
	FROM pts 
	--30 ou 300, à vérifier
	INNER JOIN public.ST_HexagonGrid(radius, pts.geometry) AS hex ON public.ST_Intersects(pts.geometry, hex.geom)
	group by hex.geom);
	
end;
$$;


--
-- TOC entry 1905 (class 1255 OID 1736632)
-- Name: gettilesintersectinglayer(bigint, character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.gettilesintersectinglayer(liste_operateur bigint, liste_techno character varying) RETURNS TABLE(x integer, y integer, z integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tile_bounds public.GEOMETRY;
	max_zoom INTEGER := 7;
	schema_function text;
BEGIN
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	FOR current_zoom IN 1..max_zoom LOOP
		FOR _x IN 0..(2 ^ current_zoom - 1)
		LOOP
			FOR _y IN 0..(2 ^ current_zoom - 1)
			LOOP
				tile_bounds := public.ST_TileEnvelope(current_zoom, _x, _y);
				IF EXISTS (
					SELECT 1 FROM couverture_theorique
					WHERE public.ST_Intersects(geom, tile_bounds)
					AND operateur = liste_operateur
					AND techno = liste_techno
				)
				THEN
					RAISE NOTICE 'Computing %', current_zoom || ', ' || _x || ', ' || _y;
					z := current_zoom;
					x := _x;
					y := _y;
					RETURN NEXT;
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;
END;
$$;


--
-- TOC entry 1906 (class 1255 OID 1736633)
-- Name: gettilesintersectinglayer_couverture_tbc(character varying); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.gettilesintersectinglayer_couverture_tbc(in_techno character varying) RETURNS TABLE(x integer, y integer, z integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tile_bounds public.GEOMETRY;
	max_zoom INTEGER := 9;
	schema_function text;
BEGIN
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	FOR current_zoom IN 1..max_zoom LOOP
		FOR _x IN 0..(2 ^ current_zoom - 1)
		LOOP
			FOR _y IN 0..(2 ^ current_zoom - 1)
			LOOP
				tile_bounds := public.ST_TileEnvelope(current_zoom, _x, _y);
				IF EXISTS (
					SELECT 1 FROM couverture_theorique
					WHERE public.ST_Intersects(geom, tile_bounds)
					AND techno = in_techno
					AND niveau= 'TBC'
				)
				THEN
					RAISE NOTICE 'Computing %', current_zoom || ', ' || _x || ', ' || _y;
					z := current_zoom;
					x := _x;
					y := _y;
					RETURN NEXT;
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;
END;
$$;


--
-- TOC entry 1907 (class 1255 OID 1736634)
-- Name: lunch_generate_hexa_signalement(integer); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.lunch_generate_hexa_signalement(radius integer) RETURNS void
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();

	PERFORM set_config('search_path', schema_function, TRUE); 
	--Suppression des données
	delete from hexa_signalement;
	--injection du carroyage hexa
	insert into hexa_signalement (fid, geometry) select * from generate_hexa_signalement(radius);
	--Association des hexa aux données
	UPDATE signalement t SET id_hexa = h.fid
	FROM hexa_signalement as h WHERE public.ST_Intersects(t.geometry, h.geometry);
	--découpage des géométries, on optimise un peu le regroupement des departements sinon c'est trop long (+1min)
	WITH departements_regroupes AS (
     SELECT 
        public.ST_Buffer(public.ST_Simplify(public.ST_Union(dep.geom), 100), 50) AS geom_regroupe
    FROM 
        (select departement.geom from departement UNION select departement_stb_stm.geom from departement_stb_stm) as dep
	)

	update hexa_signalement set geometry_intersect = public.ST_Intersection(geometry, geom_regroupe)
	from departements_regroupes;
end;
$$;


--
-- TOC entry 1908 (class 1255 OID 1736635)
-- Name: lunch_generate_tiles_couverture(); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.lunch_generate_tiles_couverture() RETURNS void
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	delete from tiles_cache_couverture;
	with oper as (
		SELECT distinct operateur from couverture_theorique
	),
	techno as (
		SELECT distinct techno from couverture_theorique
	)
	insert into tiles_cache_couverture(
		z, x, y, operateur, techno, mvt)
	select tile.z, tile.x, tile.y, oper.operateur,  techno.techno,
	generate_couvertures_tiles(tile.z, tile.x, tile.y, oper.operateur, techno.techno)
	from techno, oper, GetTilesIntersectingLayer(operateur, techno) as tile;
end;
$$;


--
-- TOC entry 1900 (class 1255 OID 1736636)
-- Name: lunch_generate_tiles_couverture_tbc(); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.lunch_generate_tiles_couverture_tbc() RETURNS void
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	delete from tiles_cache_couverture_tbc;
	
	with liste_techno as (
	select '2G3G' as techno
	UNION
	select '4G' as techno
	)
	insert into tiles_cache_couverture_tbc(
		z, x, y, techno, mvt)
	select tile.z, tile.x, tile.y, liste_techno.techno,
	generate_couvertures_tbc_tiles(tile.z, tile.x, tile.y, liste_techno.techno)
	from liste_techno, gettilesintersectinglayer_couverture_tbc(liste_techno.techno) as tile;
end;
$$;


--
-- TOC entry 1909 (class 1255 OID 1736637)
-- Name: lunch_generate_tiles_hexa(); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.lunch_generate_tiles_hexa() RETURNS void
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	--Suppression des données
	delete from hexa_30m;
	--injection du carroyage hexa
	insert into hexa_30m select * from generate_hexa_layer();
	--Association des hexa aux données
	UPDATE qos SET id_hexa = h.fid
	FROM hexa_30m as h WHERE public.ST_Intersects(qos.geometry, h.geometry);
	--Ajout du centroid
	update hexa_30m set geometry_centroid = public.ST_centroid(geometry);
end;
$$;


--
-- TOC entry 1910 (class 1255 OID 1736638)
-- Name: site_operateur(integer, integer, integer, integer[]); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.site_operateur(z integer, x integer, y integer, liste_operateur integer[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	query text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
    return (
		WITH
		bounds AS (SELECT public.ST_TileEnvelope(z, x, y) AS geom),
		mvtgeom AS (
		  SELECT code_op, nom_op, num_site, id_station_anfr,
		    x, y, latitude, longitude, nom_reg, nom_dep,
		    insee_dep, nom_com, insee_com, site_2g, site_3g,
		    site_4g, site_5g, date_ouverturecommerciale_5g,
		    site_5g_700_m_hz, site_5g_800_m_hz, site_5g_1800_m_hz,
		    site_5g_2100_m_hz, site_5g_3500_m_hz, id_site_partage,
		    mes_4g_trim, site_zb, site_dcc, site_strategique,
		    site_capa_240mbps, annee_donnee, trimestre_donnee,
			public.ST_AsMVTGeom(t.geometry, bounds.geom) AS geom
		  FROM "site" t, bounds
		  WHERE public.ST_Intersects(t.geometry, bounds.geom )
		  	and code_op = any(liste_operateur)
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1911 (class 1255 OID 1736639)
-- Name: supports_istechno(text[], text); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.supports_istechno(techonologies text[], params_techno text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$

DECLARE 
    istechnovalid boolean ;
begin
    SELECT params_techno = any(techonologies) as val INTO istechnovalid ; 
	return istechnovalid ;
end;
$$;


--
-- TOC entry 1912 (class 1255 OID 1736640)
-- Name: tbc_2g3g_gettilesintersectinglayer(); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.tbc_2g3g_gettilesintersectinglayer() RETURNS TABLE(x integer, y integer, z integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tile_bounds GEOMETRY;
	max_zoom INTEGER := 7;
	schema_function text;
BEGIN
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	FOR current_zoom IN 1..max_zoom LOOP
		FOR _x IN 0..(2 ^ current_zoom - 1)
		LOOP
			FOR _y IN 0..(2 ^ current_zoom - 1)
			LOOP
				tile_bounds := public.ST_TileEnvelope(current_zoom, _x, _y);
				IF EXISTS (
					SELECT 1 FROM couverture_theorique
					WHERE public.ST_Intersects(geom, tile_bounds)
					AND techno = '2G3G'
					AND niveau = 'TBC'
				)
				THEN
					RAISE NOTICE 'Computing %', current_zoom || ', ' || _x || ', ' || _y;
					z := current_zoom;
					x := _x;
					y := _y;
					RETURN NEXT;
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;
END;
$$;


--
-- TOC entry 1913 (class 1255 OID 1736641)
-- Name: tbc_2g3g_lunch_generate_tiles_couverture(); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.tbc_2g3g_lunch_generate_tiles_couverture() RETURNS void
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	delete from tbc_2g3g_tiles_cache;
	with oper as (
		SELECT distinct operateur from couverture_theorique
	)
	insert into tbc_2g3g_tiles_cache(
		z, x, y, operateur, mvt)
	select tile.z, tile.x, tile.y, oper.operateur, 
	tbc_2g3g_generate_couvertures_tiles(tile.z, tile.x, tile.y)
	from oper, tbc_2g3g_gettilesintersectinglayer() as tile;
end;
$$;


--
-- TOC entry 1914 (class 1255 OID 1736642)
-- Name: tbc_couvertures(integer, integer, integer); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.tbc_couvertures(z integer, x integer, y integer) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	if (z <= 7 and array_length(liste_operateur,1) = 1) then
		return (
			SELECT operateur, mvt
			from tbc_2g3g_tiles_cache 
			Where tiles_cache.x=x 
				AND tiles_cache.y=y 
				AND tiles_cache.z=z 
		);
	else
		return (
			WITH
			bounds AS (
			  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
			 (CASE 
				when z >= 12 then 0
				when z = 11 then 0
				when z = 10 then 10
				when z = 9 then 100
				when z = 8 then 300
				ELSE 1 END
			   ) as simplify_tolerance
			),

			mvtgeom AS (
			  SELECT operateur, 
				public.ST_AsMVTGeom(
					  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

			  FROM couverture_theorique t, bounds
			  WHERE public.ST_Intersects(t.geom, bounds.geom )
				and techno = '2G3G' 
                and niveau = 'TBC'
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		);
	end if;
end;
$$;


--
-- TOC entry 1915 (class 1255 OID 1736643)
-- Name: test_schema(integer); Type: FUNCTION; Schema: mrm_private; Owner: -
--

CREATE FUNCTION mrm_private.test_schema(radius integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
	
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE);
	return schema_function;
end;
$$;


--
-- TOC entry 1818 (class 1255 OID 1658719)
-- Name: _debug_hexa(integer, integer, integer); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public._debug_hexa(z integer, x integer, y integer) RETURNS bytea
    LANGUAGE sql
    AS $$

    with bounds as (
			  SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
	mvtgeom AS (
		SELECT 1 as fid, r.geometry--ST_AsMVTGeom(hex.geom, bounds.geom) AS geom
		FROM  
		--(SELECT 1 as gid, ST_Extent(geom) as geom from mrm_last.region ) as r
		mrm_private.qos as r
		INNER JOIN ST_HexagonGrid(30, r.geometry) AS hex ON ST_Intersects(r.geometry, hex.geom)
		INNER JOIN bounds ON ST_Intersects(r.geometry, bounds.geom )
		where id_data_source_desc = 11   
		--group by hex.geom, bounds.geom
	)
	SELECT ST_AsMVT(mvtgeom)
	FROM mvtgeom;
$$;


--
-- TOC entry 1819 (class 1255 OID 1658720)
-- Name: _debug_tiles(integer, integer, integer); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public._debug_tiles(z integer, x integer, y integer) RETURNS bytea
    LANGUAGE sql
    AS $$
    with tile as (
        select z, x, y, public.ST_asmvtgeom(public.ST_TileEnvelope(z,x,y), public.ST_TileEnvelope(z,x,y))
    )
    select public.ST_asmvt(tile) from tile;
$$;


--
-- TOC entry 1820 (class 1255 OID 1658721)
-- Name: arcep_get_code_operateur(text, text); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.arcep_get_code_operateur(params_code text, params_dept text) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	code_operateur_result text;
	schema_function text;
begin
	schema_function := public.parent_schema();
	RAISE NOTICE 'schema_name %', schema_function;
	PERFORM set_config('search_path', schema_function, TRUE); 
	select identifiant from operateurs op where op.code = params_code and 
	case 
		when params_dept = '971' then perimetre_971 = true 
		when params_dept = '972' then perimetre_972 = true
		when params_dept = '973' then perimetre_973 = true
		when params_dept = '974' then perimetre_974 = true
		when params_dept = '976' then perimetre_976 = true
		when params_dept = '977' then perimetre_977 = true
		when params_dept = '978' then perimetre_978 = true
		else perimetre_metro = true
	end
	limit 1 INTO code_operateur_result ;
	return code_operateur_result;
end;
$$;


--
-- TOC entry 1821 (class 1255 OID 1658722)
-- Name: couvertures(integer, integer, integer, integer[], character varying[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.couvertures(z integer, x integer, y integer, liste_operateur integer[], liste_techno character varying[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	if (z <= 7 and array_length(liste_operateur,1) = 1) then
		return (
			SELECT mvt
			from tiles_cache_couverture 
			Where tiles_cache_couverture.x=x 
				AND tiles_cache_couverture.y=y 
				AND tiles_cache_couverture.z=z 
				and operateur = any(liste_operateur)
				and techno = any(liste_techno)
		);
	else
		return (
			WITH
			bounds AS (
			  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
			 (CASE 
				when z >= 12 then 0
				when z = 11 then 0
				when z = 10 then 10
				when z = 9 then 100
				when z = 8 then 300
				when z = 7 then 900
				when z = 6 then 1500
				when z <= 5 then 3000 
				ELSE 1 END
			   ) as simplify_tolerance
			),

			mvtgeom AS (
			  SELECT fid, operateur, date, techno, usage, niveau, dept, filename,
				public.ST_AsMVTGeom(
					  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

			  FROM couverture_theorique t, bounds
			  WHERE public.ST_Intersects(t.geom, bounds.geom )
				and operateur = any(liste_operateur)
				and techno = any(liste_techno) 
				--and niveau <> ''
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		);
	end if;
end;
$$;


--
-- TOC entry 1822 (class 1255 OID 1658723)
-- Name: couvertures_tbc(integer, integer, integer, character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.couvertures_tbc(z integer, x integer, y integer, in_techno character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	RAISE NOTICE 'schema %', schema_function;
	PERFORM set_config('search_path', schema_function, TRUE); 
	if (z <= 9 ) then
		return (
			SELECT mvt
			from tiles_cache_couverture_tbc
			Where tiles_cache_couverture_tbc.x=x 
				AND tiles_cache_couverture_tbc.y=y 
				AND tiles_cache_couverture_tbc.z=z 
				and techno = in_techno
		);
	else
		return (
			WITH
			bounds AS (
			  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
			 (CASE 
				when z >= 12 then 0
				when z = 11 then 0
				when z = 10 then 10
				when z = 9 then 100
				when z = 8 then 300
				when z = 7 then 900
				when z = 6 then 1500
				when z <= 5 then 3000 
				ELSE 1 END
			   ) as simplify_tolerance
			),

			mvtgeom AS (
			  SELECT fid, operateur, dept,
				public.ST_AsMVTGeom(
					  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

			  FROM couverture_theorique t, bounds
			  WHERE public.ST_Intersects(t.geom, bounds.geom )
				and techno = in_techno 
				and niveau = 'TBC'
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		);
	end if;
end;
$$;


--
-- TOC entry 1823 (class 1255 OID 1658724)
-- Name: couvertures_test(integer, integer, integer, integer[], character varying[], integer[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.couvertures_test(z integer, x integer, y integer, liste_operateur integer[], liste_techno character varying[], liste_fid integer[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
    return (
		WITH
		bounds AS (
		  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
		 (CASE 
			when z >= 12 then 0
			when z = 11 then 0
			when z = 10 then 0
			when z = 9 then 100
			when z = 8 then 300
			when z = 7 then 900
			when z = 6 then 1500
			when z <= 5 then 3000 
			ELSE 1 END
		   ) as simplify_tolerance
		),

		mvtgeom AS (
		  SELECT fid, operateur, date, techno, usage, niveau, dept, filename,
			public.ST_AsMVTGeom(
				  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

		  FROM couverture_theorique t, bounds
		  WHERE public.ST_Intersects(t.geom, bounds.geom )
		  	and operateur = any(liste_operateur)
		  	and techno = any(liste_techno)
		  	and fid = any(liste_fid)
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1824 (class 1255 OID 1658725)
-- Name: couvertures_test_ex(integer, integer, integer, integer[], character varying[], integer[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.couvertures_test_ex(z integer, x integer, y integer, liste_operateur integer[], liste_techno character varying[], liste_fid integer[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
    return (
		WITH
		bounds AS (
		  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
		 (CASE 
			when z >= 12 then 0
			when z = 11 then 0
			when z = 10 then 0
			when z = 9 then 100
			when z = 8 then 300
			when z = 7 then 900
			when z = 6 then 1500
			when z <= 5 then 3000 
			ELSE 1 END
		   ) as simplify_tolerance
		),

		mvtgeom AS (
		  SELECT fid, operateur, date, techno, usage, niveau, dept, 
			public.ST_AsMVTGeom(
				  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

		  FROM couverture_theorique t, bounds
		  WHERE public.ST_Intersects(t.geom, bounds.geom )
		  	and operateur = any(liste_operateur)
		  	and techno = any(liste_techno)
		  	and fid != any(liste_fid)
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1825 (class 1255 OID 1658726)
-- Name: couvertures_union(integer, integer, integer, integer[], character varying[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.couvertures_union(z integer, x integer, y integer, liste_operateur integer[], liste_techno character varying[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
    return (
		WITH
		bounds AS (
		  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
		 (CASE 
			when z >= 12 then 0
			when z = 11 then 0
			when z = 10 then 0
			when z = 9 then 0
			when z = 8 then 200
			when z = 7 then 250
			when z = 6 then 300
			when z <= 5 then 400
			ELSE 1 END
		   ) as simplify_tolerance
		),

		mvtgeom AS (
		  SELECT fid, operateur, date, techno, usage, niveau, dept, 
			public.ST_AsMVTGeom(
				  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

		  FROM couverture_theorique_union t, bounds
		  WHERE public.ST_Intersects(t.geom, bounds.geom )
		  	and operateur = any(liste_operateur)
		  	and techno = any(liste_techno)
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1826 (class 1255 OID 1658727)
-- Name: debug_layer(integer, integer, integer); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.debug_layer(z integer, x integer, y integer) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

begin
	return (
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope(z, x, y) AS geom
		),
		mvtgeom AS (
			select t.fid, id_hexa, bitrate_dl, public.ST_AsMVTGeom(geometry_centroid, bounds.geom) as geom 
			FROM mrm_private.qos t
			INNER JOIN mrm_private.hexa_30m h30 ON h30.fid = id_hexa
			INNER JOIN bounds ON public.ST_Intersects(geometry_centroid, bounds.geom )
			WHERE mcc_mnc is not null  AND lower(protocole) = 'download'
			AND id_data_source_desc = 4 AND is_metropole = true 
			AND is_transport = false AND bitrate_dl is not null 
			AND bitrate_dl > 30 and geometry_centroid is not null
		)
		SELECT ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1828 (class 1255 OID 1658728)
-- Name: debug_supports_cluster_techno(integer, integer, integer, integer[], text[], text); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.debug_supports_cluster_techno(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text) RETURNS text
    LANGUAGE plpgsql
    AS $_$

DECLARE 
	querystr text;
	queryFilter text;
	filter_techno_global text;
	bAllOperator boolean;
	filter_techno text;
	schema_function text;
begin

	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	filter_techno_global := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := ' AND s.site_strategique = true ';
    end if ; 
    
	querystr := '
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
		),
		support_filter AS (
			SELECT distinct t.fid
			FROM anfr_sup_support t
			INNER JOIN site s ON s.id_station_anfr = sta_nm_anfr
			INNER JOIN bounds ON public.ST_Intersects(t.geom, public.ST_Buffer(bounds.geom, 100000) )
			WHERE code_op = any($4) ' || filter_techno_global || ' 
		),
		tot_com AS (
			select gid, count(1) as tot_support
			from commune c
			INNER JOIN anfr_sup_support t ON public.ST_contains(c.geom, t.geom )
			INNER JOIN support_filter s ON s.fid = t.fid
			group by gid
			having count(1) > 0
		),
		mvtgeom AS (
		  SELECT c.gid, tot_support, ''com'' as niveau, 
		  c.insee_dep as code_dep, concat($1,''|'',$2,''|'',$3) as tile, 
			public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, $5 as allop
		  FROM commune c
			INNER JOIN bounds ON public.ST_Intersects(c.geom, bounds.geom )
			LEFT JOIN tot_com ON  c.gid = tot_com.gid
			WHERE tot_support is not null
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	';
		
    return querystr;
end;
$_$;


--
-- TOC entry 1829 (class 1255 OID 1658729)
-- Name: fc_qos(integer, integer, integer, text, text, text[], text[], text, character varying, character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_qos(z integer, x integer, y integer, operator text, protocole text, situation text[], strate text[], datasource text, metropole character varying, habitation character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	fieldsquery text;
	fieldsquery_cluster text;
	groupbyquery text;
	wherequery text;
	resultquery bytea;
	casequery text;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
    
    if array_length(situation, 1) is null then 
		return null;
	end if ; 
    
    if array_length(strate, 1) is null then 
		return null;
	end if ; 
    
	wherequery := fc_qos_filterbuilder(operator, protocole, situation, strate, datasource, metropole, habitation);
	
	groupbyquery := '';
	
	if lower(protocole) = 'web' then
		fieldsquery_cluster:= ' , 
			count(case when loaded_in_less_5_secondes then 1 end) as success,
			count(case when 
				loaded_in_less_5_secondes = false 
				and loaded_in_less_10_secondes 
				then 1 end) as success_partial,
			count(case when 
				loaded_in_less_5_secondes = false 
				and loaded_in_less_10_secondes = false 
				then 1 end) as fail, 
				floor(count(1) / 2) as majority ';
		fieldsquery:= ' , loaded_in_less_5_secondes, loaded_in_less_10_secondes ';
		casequery:= ' , 
			case 
				when success > majority then 0 
				when success_partial > majority then 5 
				when success + success_partial > majority then 5
				else 10 
			end as acess_duration ';
	elsif lower(protocole) = 'stream' then
		fieldsquery_cluster:= ' , 
			count(case when quality_perfect = true then 1 end) as parfaite,
			count(case when quality_perfect = false and quality_correct = true then 1 end) as correcte,
			count(case when quality_perfect = false and quality_correct = false then 1 end) as echec, 
			floor(count(1) / 2) as majority ';
		fieldsquery:= ' , quality_perfect, quality_correct ';
		casequery:= ' , 
			case 
				when parfaite > majority then true else false
			end as quality_perfect,
			case 
				when not parfaite > majority and parfaite + correcte > majority then true else false
			end as quality_correct ';
		--groupbyquery := ' , video_en_qualite_parfaite, video_en_qualite_correcte ';
	elsif lower(protocole) = 'upload' then
		fieldsquery_cluster:=  ' , 
			count(case when upload_ok = true then 1 end) as success,
			count(case when upload_ok = false then 1 end) as echec ';
		fieldsquery:=  ' , upload_ok ';
		casequery := ' , case when success > echec then true else false end as upload_ok ';
		wherequery:= wherequery || ' AND upload_ok is not null ';
	elsif lower(protocole) = 'download' then
		fieldsquery_cluster:=  ' , 
			count(case when bitrate_dl < 3 then 1 end) as val0_3,
			count(case when bitrate_dl >= 3 and bitrate_dl < 8 then 1 end) as val3_8,
			count(case when bitrate_dl >= 8 and bitrate_dl < 30 then 1 end) as val8_30,
			count(case when bitrate_dl >= 30 then 1 end) as val30,
			floor(count(1) / 2) as majority';
		fieldsquery:= ' , bitrate_dl ';
		casequery:= ' , 
			case 
				when val30 > majority then 31 
				when val8_30 > majority then 20 
				when val3_8 > majority then 5
				when val0_3 > majority then 1
				when val30 + val8_30 > majority then 20
				when val30 + val3_8 > majority then 5
				when val30 + val8_30 + val3_8 > majority then 5
				when val30 + val0_3 > majority then 1
				when val8_30 + val3_8 > majority then 5
				when val8_30 + val0_3 > majority then 1
				when val3_8 + val0_3 > majority then 1
				when val30 + val8_30 + val3_8 <= majority then 1
			end as bitrate_dl ';
		wherequery:= wherequery || ' AND bitrate_dl is not null ';
	elsif lower(protocole) = 'voix' then
		fieldsquery_cluster:= ' , 
			count(case when min_mos_couple >= 2.1 and real_communiation_time = 120 then 1 end) as success,
			count(case when min_mos_couple < 2.1 and real_communiation_time = 120 then 1 end) as partial_success,
			count(case when real_communiation_time <> 120 then 1 end) as fail, 
			floor(count(1) / 2) as majority';
		fieldsquery:= ' , min_mos_couple, real_communiation_time ';
		casequery:= ' , case 
				when success > majority then 2 
				when partial_success > majority then 1 
				when fail > majority then 0
				when success + partial_success > majority then 1
				when fail + partial_success > majority then 0
				when success = fail and partial_success = 0 then 0
				when success + partial_success = fail then 0
			end as status ';
		wherequery:= wherequery || ' AND real_communiation_time is not null ';
	elsif lower(protocole) = 'sms' then
		fieldsquery_cluster:= ' , 
			count(case when sms_delai <= 10 then 1 end) as nb_pass,
			count(case when sms_delai > 10 then 1 end) as nb_fail ';
		fieldsquery:= ' , sms_delai ';
		casequery:= ' , case when nb_pass > nb_fail then 5 else 15 END  as sms_delai ';
		wherequery:= wherequery || ' AND sms_delai is not null ';
	end if; 
	
	queryst := '
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		selected_obj as (
			SELECT 
			t.id_hexa, 
			t.fid
			'|| fieldsquery ||'
			FROM bounds 
			INNER JOIN hexa_30m h30 ON public.ST_contains(bounds.geom, h30.geometry_centroid) 
			INNER JOIN qos t ON h30.fid = t.id_hexa 
			 '|| wherequery ||'
		),
		 stat_obj as (
			SELECT 
			 	id_hexa, 
				array_agg(fid) AS fids 
			'|| fieldsquery_cluster ||'
			from selected_obj
			GROUP BY id_hexa
			' || groupbyquery || '
		),
		mvtgeom AS (
			select 
			id_hexa as cid, 
			id_hexa as id, 
			public.ST_AsMVTGeom(geometry_centroid, bounds.geom) as geom,
			fids
			'|| casequery ||'
			from stat_obj s, bounds, hexa_30m h30
			WHERE h30.fid = s.id_hexa 
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	';
	EXECUTE queryst INTO resultquery;
	return resultquery;
end;
$$;


--
-- TOC entry 1830 (class 1255 OID 1658731)
-- Name: fc_qos_filterbuilder(text, text, text[], text[], text, character varying, character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_qos_filterbuilder(operator text, protocole text, situation text[], strate text[], datasource text, metropole character varying, habitation character varying) RETURNS text
    LANGUAGE plpgsql
    AS $_$

DECLARE 
	queryst text;
	elt_strate text;
	strin_strate text;
	other_strate text;
    situtation_where text;
	datasourceval integer;
	metropoleval boolean;
	habitationval boolean;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	queryst := ' WHERE mcc_mnc is not null ' ;
	if operator <> 'all' and operator <> '' then
		queryst := queryst || ' AND mcc_mnc = ' || operator::int;
	end if;
	
	if protocole <> '' then 
		if lower(protocole) = 'upload' then
			queryst := queryst || ' AND lower(protocole) in (''upload'', ''ulh'')';
		else
			queryst := queryst || ' AND lower(protocole) = ''' || lower(protocole) || '''';
		end if;
	end if; 
	
	situtation_where := '';
	if ARRAY_LENGTH(situation, 1) < 3 then
    	situtation_where := format(' AND upper(situation) = any(array[''%1$s'']) ', array_to_string(situation, ''',''')) ;
	end if;
	
	queryst := queryst || situtation_where ;
	
	if strate is null then
		queryst := queryst || ' AND lower(zone) = ''99999*''';
	else 
		if ARRAY_LENGTH(strate, 1) < 5 then
			strin_strate := '';
			other_strate := '';
			FOREACH elt_strate IN ARRAY strate LOOP
				if lower(elt_strate) = 'others' then
					other_strate := ' UPPER(public.unaccent(zone)) NOT IN (''ZONES INTERMEDIAIRES'',''ZONES DENSES'',''ZONES TOURISTIQUES'',''ZONES RURALES'')';
				else
					if strin_strate <> '' then
						strin_strate := strin_strate || ''',''';
					end if;
					strin_strate := strin_strate || lower(elt_strate);
				end if;
			END LOOP;
			
			if strin_strate = '' then 
				queryst := queryst || ' AND ' || other_strate ;
			elseif other_strate = '' then 
				queryst := queryst || ' AND lower(public.unaccent(zone)) IN (''' || strin_strate ||''')';
			else
				queryst := queryst || ' AND (lower(public.unaccent(zone)) IN (''' || strin_strate ||''') OR '|| other_strate ||')';
			end if;
			
		end if;	
	end if;
	
	if datasource = '' then 
		datasourceval = 1;
	else 
		datasourceval = datasource::integer;
	end if;
	queryst := queryst || ' AND id_data_source_desc = ' || datasourceval ;
	
	metropoleval = true;
	if metropole <> '1' then 
		metropoleval = false;
	end if;
	queryst := queryst || ' AND is_metropole = ' || metropoleval ;
	
		
	habitationval = true;
	if habitation <> '1' then 
		habitationval = false;
	end if;
	queryst := queryst || ' AND is_transport = ' || not habitationval ;
	
	return queryst;
end;
$_$;


--
-- TOC entry 1831 (class 1255 OID 1658732)
-- Name: fc_qos_filterbuilder(text, text, text, text[], text, character varying, character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_qos_filterbuilder(operator text, protocole text, situation text, strate text[], datasource text, metropole character varying, habitation character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE
queryst text;
elt_strate text;
strin_strate text;
other_strate text;
datasourceval integer;
metropoleval boolean;
habitationval boolean;
schema_function text;
begin
schema_function := public.parent_schema();
PERFORM set_config('search_path', schema_function, TRUE);
queryst := ' WHERE mcc_mnc is not null ' ;
if operator <> 'all' and operator <> '' then
queryst := queryst || ' AND mcc_mnc = ' || operator::int;
end if;

if protocole <> '' then
if lower(protocole) = 'upload' then
queryst := queryst || ' AND lower(protocole) in (''upload'', ''ulh'')';
else
queryst := queryst || ' AND lower(protocole) = ''' || lower(protocole) || '''';
end if;
end if;

if lower(situation) <> 'toutes' and situation <> '' then
queryst := queryst || ' AND lower(situation) = ''' || lower(situation) || '''';
end if;

if strate is null then
queryst := queryst || ' AND lower(zone) = ''99999*''';
else
if ARRAY_LENGTH(strate, 1) < 5 then
strin_strate := '';
other_strate := '';
FOREACH elt_strate IN ARRAY strate LOOP
if lower(elt_strate) = 'others' then
other_strate := ' UPPER(unaccent(zone)) NOT IN (''ZONES INTERMEDIAIRES'',''ZONES DENSES'',''ZONES TOURISTIQUES'',''ZONES RURALES'')';
else
if strin_strate <> '' then
strin_strate := strin_strate || ''',''';
end if;
strin_strate := strin_strate || lower(elt_strate);
end if;
END LOOP;

if strin_strate = '' then
queryst := queryst || ' AND ' || other_strate ;
elseif other_strate = '' then
queryst := queryst || ' AND lower(unaccent(zone)) IN (''' || strin_strate ||''')';
else
queryst := queryst || ' AND (lower(unaccent(zone)) IN (''' || strin_strate ||''') OR '|| other_strate ||')';
end if;

end if;
end if;

if datasource = '' then
datasourceval = 1;
else
datasourceval = datasource::integer;
end if;
queryst := queryst || ' AND id_data_source_desc = ' || datasourceval ;

metropoleval = true;
if metropole <> '1' then
metropoleval = false;
end if;
queryst := queryst || ' AND is_metropole = ' || metropoleval ;


habitationval = true;
if habitation <> '1' then
habitationval = false;
end if;
queryst := queryst || ' AND is_transport = ' || not habitationval ;

return queryst;
end;
$$;


--
-- TOC entry 1832 (class 1255 OID 1658733)
-- Name: fc_qos_transport(integer, integer, integer, text, text, text, text[], text, character varying, character varying, text[], character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_qos_transport(z integer, x integer, y integer, operator text, protocole text, situation text, strate text[], datasource text, metropole character varying, habitation character varying, axis text[] DEFAULT NULL::text[], axis_name character varying DEFAULT NULL::character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	fieldsquery text;
	fieldsquery_cluster text;
	casequery text;
	wherequery text;
	resultquery bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	wherequery := fc_qos_transport_filterbuilder(operator, protocole, situation, strate, datasource, metropole, habitation, axis, axis_name);
	
	wherequery:= wherequery || ' AND public.ST_Intersects(t.geometry, bounds.geom ) ';

	if lower(protocole) = 'web' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' acess_duration, loaded_in_less_10_secondes, loaded_in_less_5_secondes ';
		casequery:= ' , 
			case 
				when loaded_in_less_5_secondes then 0 
			else 
			case 
				when loaded_in_less_5_secondes = false AND 
				loaded_in_less_10_secondes then 5
			else 
			case 
				when loaded_in_less_5_secondes = false 
				and loaded_in_less_10_secondes = false then 10 
				else -1 end
			end 
			end as acess_duration ';
		--wherequery:= wherequery || ' AND acess_duration is not null AND loaded_in_less_10_secondes is not null AND loaded_in_less_5_secondes is not null ';
	end if; 
	if lower(protocole) = 'voix' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' min_mos_couple, real_communiation_time ';
		casequery:= ' , case when min_mos_couple >= 2.1 and real_communiation_time = 120 then 2 
			else 
				case when min_mos_couple < 2.1 and real_communiation_time = 120 then 1
			else 
				0 END END as status ';
		wherequery:= wherequery || ' AND real_communiation_time is not null ';
	end if;
	
	--fieldsquery := fieldsquery || ', public.ST_AsMVTGeom(geometry, bounds.geom) as geom';

	queryst := '
		
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		data_selected as (
			SELECT
			t.fid as id,
			array_agg(t.fid) ids,
			'|| fieldsquery ||', 
			t.geometry as geom
			FROM qos t, bounds
			 '|| wherequery ||'
			AND public.st_contains(bounds.geom, t.geometry)
			group by t.fid
		),
		mvtgeom AS (
			select 
			s.ids, 
			public.ST_AsMVTGeom(s.geom, bounds.geom) as geom
			'|| casequery ||'
			from data_selected s, bounds 
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	';
	
	--RAISE NOTICE 'queryst : %', queryst;
	
	EXECUTE queryst INTO resultquery;
	return resultquery;
end;
$$;


--
-- TOC entry 1833 (class 1255 OID 1658734)
-- Name: fc_qos_transport_debug(integer, integer, integer, text, text, text, text[], text, character varying, character varying, text[], character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_qos_transport_debug(z integer, x integer, y integer, operator text, protocole text, situation text, strate text[], datasource text, metropole character varying, habitation character varying, axis text[] DEFAULT NULL::text[], axis_name character varying DEFAULT NULL::character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	fieldsquery text;
	fieldsquery_cluster text;
	casequery text;
	wherequery text;
	--resultquery bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	wherequery := fc_qos_transport_filterbuilder(operator, protocole, situation, strate, datasource, metropole, habitation, axis, axis_name);
	
	wherequery:= wherequery || ' AND public.ST_Intersects(t.geometry, bounds.geom ) ';

	if lower(protocole) = 'web' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' acess_duration, loaded_in_less_10_secondes, loaded_in_less_5_secondes ';
		casequery:= ' , 
			case 
				when loaded_in_less_5_secondes then 0 
			else 
			case 
				when loaded_in_less_5_secondes = false AND 
				loaded_in_less_10_secondes then 5
			else 
			case 
				when loaded_in_less_5_secondes = false 
				and loaded_in_less_10_secondes = false then 10 
				else -1 end
			end 
			end as acess_duration ';
		--wherequery:= wherequery || ' AND acess_duration is not null AND loaded_in_less_10_secondes is not null AND loaded_in_less_5_secondes is not null ';
	end if; 
	if lower(protocole) = 'voix' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' crspa, real_communiation_time ';
		casequery:= ' , case when crspa then 2 
			else 
				case when crspa = false and real_communiation_time = 120 then 1
			else 
				0 END END as status ';
		wherequery:= wherequery || ' AND crspa is not null AND real_communiation_time is not null ';
	end if;
	
	--fieldsquery := fieldsquery || ', public.ST_AsMVTGeom(geometry, bounds.geom) as geom';

	queryst := '
		
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		data_selected as (
			SELECT
			t.fid as id,
			array_agg(t.fid) ids,
			'|| fieldsquery ||', 
			t.geometry as geom
			FROM mrm_private.qos t, bounds
			 '|| wherequery ||'
			AND public.st_contains(bounds.geom, t.geometry)
			group by t.fid
		),
		mvtgeom AS (
			select 
			s.ids, 
			public.ST_AsMVTGeom(s.geom, bounds.geom) as geom
			'|| casequery ||'
			from data_selected s, bounds 
		)
		SELECT *
		FROM mvtgeom limit 10
	';
	
	--RAISE NOTICE 'queryst : %', queryst;
	
	--EXECUTE queryst INTO resultquery;
	return queryst;
end;
$$;


--
-- TOC entry 1834 (class 1255 OID 1658735)
-- Name: fc_qos_transport_filterbuilder(text, text, text, text[], text, character varying, character varying, text[], character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_qos_transport_filterbuilder(operator text, protocole text, situation text, strate text[], datasource text, metropole character varying, habitation character varying, axis text[] DEFAULT NULL::text[], axis_name character varying DEFAULT NULL::character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	elt_strate text;
	strin_strate text;
	other_strate text;
	datasourceval integer;
	metropoleval boolean;
	habitationval boolean;
	schema_function text;
    elt_axis text;
	strin_axis text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	queryst := ' WHERE mcc_mnc is not null ' ;
	if operator <> 'all' and operator <> '' then
		queryst := queryst || ' AND mcc_mnc = ' || operator::int;
	end if;
	
	if protocole <> '' then 
		if lower(protocole) = 'upload' then
			queryst := queryst || ' AND lower(protocole) in (''upload'', ''ulh'')';
		else
			queryst := queryst || ' AND lower(protocole) = ''' || lower(protocole) || '''';
		end if;
	end if; 
	
	if lower(situation) <> 'toutes' and situation <> '' then 
		queryst := queryst || ' AND lower(situation) = ''' || lower(situation) || '''';
	end if; 
	
	if datasource = '' then 
		datasourceval = 1;
	else 
		datasourceval = datasource::integer;
	end if;
	queryst := queryst || ' AND id_data_source_desc = ' || datasourceval ;
	
	metropoleval = true;
	if metropole <> '1' then 
		metropoleval = false;
	end if;
	queryst := queryst || ' AND is_metropole = ' || metropoleval ;
	
		
	habitationval = true;
	if habitation <> '1' then 
		habitationval = false;
	end if;
	queryst := queryst || ' AND is_transport = ' || not habitationval ;
	
	if axis is not null and ARRAY_LENGTH(axis, 1) >= 1 then
        strin_axis := '';
		FOREACH elt_axis IN ARRAY axis LOOP
			if strin_axis <> '' then
				strin_axis := strin_axis || ',';
			end if;
			strin_axis := strin_axis || '''' || lower(public.unaccent(elt_axis)) || '''';
	  	END LOOP;
		queryst := queryst || ' AND axis IN (' ||  strin_axis || ')';
	end if;

	if axis_name is not null and trim(axis_name) != '' then 
		queryst := queryst || ' AND axis_name_search = ''' || lower(public.unaccent(axis_name)) || '''';
	end if;

	return queryst;
end;
$$;


--
-- TOC entry 1835 (class 1255 OID 1658736)
-- Name: fc_qos_transport_test(integer, integer, integer, text, text, text, text[], text, character varying, character varying, text[], character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_qos_transport_test(z integer, x integer, y integer, operator text, protocole text, situation text, strate text[], datasource text, metropole character varying, habitation character varying, axis text[] DEFAULT NULL::text[], axis_name character varying DEFAULT NULL::character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	fieldsquery text;
	fieldsquery_cluster text;
	casequery text;
	wherequery text;
	resultquery bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	wherequery := fc_qos_transport_filterbuilder(operator, protocole, situation, strate, datasource, metropole, habitation, axis, axis_name);
	
	wherequery:= wherequery || ' AND public.ST_Intersects(t.geometry, bounds.geom ) ';

	if lower(protocole) = 'web' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' acess_duration, loaded_in_less_10_secondes, loaded_in_less_5_secondes ';
		casequery:= ' , 
			case 
				when trunc(acess_duration) > 5 and loaded_in_less_10_secondes then 0 
			else 
			case 
				when trunc(acess_duration) > 10 and loaded_in_less_5_secondes then 5
				else 10 end 
			end as acess_duration ';
		wherequery:= wherequery || ' AND acess_duration is not null AND loaded_in_less_10_secondes is not null AND loaded_in_less_5_secondes is not null ';
	end if; 
	if lower(protocole) = 'voix' then
		fieldsquery_cluster:= '';
		fieldsquery:= ' crspa, real_communiation_time ';
		casequery:= ' , case when crspa then 2 
			else 
				case when crspa = false and real_communiation_time = 120 then 1
			else 
				0 END END as status ';
		wherequery:= wherequery || ' AND crspa is not null AND real_communiation_time is not null ';
	end if;
	
	--fieldsquery := fieldsquery || ', public.ST_AsMVTGeom(geometry, bounds.geom) as geom';

	queryst := '
		
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		data_selected as (
			SELECT
			t.fid as id,
			array_agg(t.fid) ids,
			'|| fieldsquery ||', 
			t.geometry as geom
			FROM mrm_private.qos t, bounds
			 '|| wherequery ||'
			AND public.st_contains(bounds.geom, t.geometry)
			group by t.fid
		),
		mvtgeom AS (
			select 
			s.ids, 
			public.ST_AsMVTGeom(s.geom, bounds.geom) as geom
			'|| casequery ||'
			from data_selected s, bounds 
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	';
	
	--RAISE NOTICE 'queryst : %', queryst;
	
	EXECUTE queryst INTO resultquery;
	return resultquery;
end;
$$;


--
-- TOC entry 1836 (class 1255 OID 1658737)
-- Name: fc_signalement(integer, integer, integer, text, character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_signalement(z integer, x integer, y integer, operator text, metropole character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	wherequery text;
	resultquery bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	wherequery := fc_signalement_filterbuilder(operator, metropole);
	
	queryst := '
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		selected_obj as (
			SELECT 
                hs.fid as id, hs.geometry_intersect,
				public.st_centroid(public.st_transform(hs.geometry_intersect, 4326)) as ct_geom,
				count(1) as total
			FROM bounds 
			INNER JOIN hexa_signalement hs ON public.ST_intersects(bounds.geom, hs.geometry_intersect) 
			INNER JOIN signalement s ON s.id_hexa = hs.fid
			 '|| wherequery ||'
            GROUP BY hs.fid, hs.geometry_intersect, ct_geom
		),
		mvtgeom AS (
			SELECT 
                id, 
                total, 
				public.st_x(ct_geom) as x, 
				public.st_y(ct_geom) as y, 
			public.ST_AsMVTGeom(geometry_intersect, bounds.geom) as geom
			from selected_obj s, bounds
			where s.total > 0 
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	';
	EXECUTE queryst INTO resultquery;
	return resultquery;
end;
$$;


--
-- TOC entry 1837 (class 1255 OID 1658738)
-- Name: fc_signalement_debug(integer, integer, integer, text, character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_signalement_debug(z integer, x integer, y integer, operator text, metropole character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	wherequery text;
	--resultquery bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	wherequery := fc_signalement_filterbuilder(operator, metropole);
	
	queryst := '
		WITH
		bounds AS (
			SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
		),
		selected_obj as (
			SELECT 
                hs.fid as id, hs.geometry, count(1) as total ,
				public.st_x(public.st_centroid(public.st_transform(geometry, ''epsg:3857'', 4326))) as x,
				public.st_y(public.st_centroid(public.st_transform(geometry, ''epsg:3857'', 4326))) as y
			FROM bounds 
			INNER JOIN mrm_private.hexa_signalement hs ON public.ST_contains(bounds.geom, st_centroid(hs.geometry)) 
			INNER JOIN mrm_private.signalement s ON s.id_hexa = hs.fid
			 '|| wherequery ||'
            GROUP BY hs.fid, hs.geometry, hs.x, hs.y
		),
		mvtgeom AS (
			SELECT 
                id, 
                total, x, y ,
			public.ST_AsMVTGeom(geometry, bounds.geom) as geom
			from selected_obj s, bounds
		)
		SELECT *
		FROM mvtgeom limit 10
	';
	return queryst;
end;
$$;


--
-- TOC entry 1838 (class 1255 OID 1658739)
-- Name: fc_signalement_filterbuilder(text, character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_signalement_filterbuilder(operator text, metropole character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	queryst text;
	metropoleval boolean;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	queryst := ' WHERE operateur is not null ' ;
	if operator <> 'all' and operator <> '' then
		queryst := queryst || ' AND operateur = ' || operator::int;
	end if;
	
	metropoleval = true;
	if metropole <> '1' then 
		metropoleval = false;
	end if;
	queryst := queryst || ' AND is_metropole = ' || metropoleval ;
	
	return queryst;
end;
$$;


--
-- TOC entry 1839 (class 1255 OID 1658740)
-- Name: fc_site(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_site(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 

	filter_techno_global := '';
	filter_techno_site := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := 'true';
	else
		bAllOperator := 'false';
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := filter_techno_global || ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := filter_techno_global || ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := filter_techno_global || ' AND s.site_strategique = true ';
    end if ; 
    
	filter_techno_site := filter_techno_global;
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
    elseif array_length(state, 1) = 2 and 'en_maintenance' = ANY(state) and 'a_venir' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
    elseif array_length(state, 1) = 2 and 'en_service' = ANY(state) and 'a_venir' = ANY(state) then 
		filter_techno_site := ' AND st.id is null ';
    end if ; 
	
	querysite := format('
			SELECT distinct t.fid, 
			case when st.id is not null then true else false end as is_maintenance , 
			false as is_sav 
			FROM anfr_sup_support t
			INNER JOIN site s ON s.sup_id = t.sup_id 
			LEFT JOIN site_state st ON s.id_station_anfr = st.station_anfr
			WHERE code_op = any(array[%2$s]) %1$s', 
			filter_techno_site, 
			array_to_string(liste_operateur, ', ')
			) ;

	querysav := format('
			SELECT distinct t.fid, false as is_maintenance , true as is_sav 
			FROM anfr_sup_support t
			INNER JOIN site_a_venir s ON s.sup_id = t.sup_id 
			WHERE code_op = any(array[%2$s]) %1$s ', 
			filter_techno_global, 
			array_to_string(liste_operateur, ', ')
			) ;

	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 

	if ( z < 9) then
		--Vue par departement
		
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			tot_dept AS (
                select t.id_departement, count(1) as tot_support, 
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from anfr_sup_support t 
				INNER JOIN support_filter sf ON sf.fid = t.fid 
				WHERE 1=1
				group by t.id_departement
			),
			mvtgeom AS (
			  SELECT d.gid, tot_support, ''dept'' as niveau,  
				case when tot_maintenance = 0 and tot_sav = 0 then ''en_service'' 
				else case when tot_maintenance >= tot_sav then ''en_maintenance''
				else ''a_venir'' end end as state,
              d.insee_dep as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, %4$s as allop,
                concat(%1$s,''|'',%2$s,''|'',%3$s) as tile
			  FROM departement d
				INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
				LEFT JOIN tot_dept ON  d.gid = tot_dept.id_departement
				WHERE tot_support is not null
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		', z, x, y, bAllOperator);
		RAISE NOTICE 'Calling query (%)', queryst;
		EXECUTE queryst INTO result;
        return result;
		
	elsif ( z <= 10) then 
		--Vue par commune, On ajoute un buffer pour récupérer les supports autour de la tuile
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			tot_com AS (
				select com_cd_insee as insee_com, count(1) as tot_support, array_agg(t.fid) AS fids,
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from anfr_sup_support t  
				INNER JOIN support_filter sf ON sf.fid = t.fid
				group by t.com_cd_insee
				having count(1) > 0
			),
			mvtgeom AS (
			  SELECT c.gid, tot_support, fids, ''com'' as niveau, 
			  c.insee_dep as code_dep, concat(%1$s,''|'',%2$s,''|'',%3$s) as tile, 
				case when tot_maintenance = 0 and tot_sav = 0 then ''en_service'' 
				else case when tot_maintenance >= tot_sav then ''en_maintenance''
				else ''a_venir'' end end as state,
				public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, %4$s as allop
			  FROM commune c
				INNER JOIN bounds ON public.ST_Intersects(c.geom, bounds.geom )
				LEFT JOIN tot_com ON  c.insee_com = tot_com.insee_com 
				WHERE tot_support is not null
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		', z, x, y, bAllOperator);
		--RAISE NOTICE 'Calling query (%)', query;
		EXECUTE queryst INTO result;
        return result;
		
	elsif ( z <= 15) then 
		
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),	
			clustered_points AS (
                SELECT public.ST_ClusterDBSCAN(t.geom, eps := 
				 (CASE 
					when %1$s = 11 then 500
					when %1$s = 12 then 385
					when %1$s = 13 then 280
					when %1$s = 14 then 150
					when %1$s = 15 then 75
					ELSE 1 END
				   ) , minpoints := 1) over() AS cid, 
				is_maintenance,
				is_sav,
				t.fid, t.geom, t.sup_id
                FROM anfr_sup_support t
                INNER JOIN support_filter s ON s.fid = t.fid 
            ),
			grouped_data as (
				select cid, 
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav,
			  	count(1) as tot_support, 
				array_agg(c.fid) as fids, 
				public.ST_PointOnSurface(public.ST_Collect(c.geom)) as geom, 
				array_agg(c.sup_id) as sup_ids
				from clustered_points c, bounds
				where public.ST_Intersects(c.geom, bounds.geom )
				group by cid 
			),
			mvtgeom AS (
			  SELECT cid, sup_ids,fids, 
				case when tot_maintenance = 0 and tot_sav = 0 then ''en_service'' 
				else case when tot_maintenance >= tot_sav then ''en_maintenance''
				else ''a_venir'' end end as state,
			  tot_support, 
			  ''clust'' as niveau, (
			  	select insee_dep from departement t 
				where public.ST_contains(t.geom, c.geom)
			  ) as code_dep, 
				public.ST_AsMVTGeom(c.geom, bounds.geom) AS geom, %4$s as allop
			  FROM grouped_data c, bounds 
			  WHERE public.ST_Intersects(c.geom, bounds.geom )
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		', z, x, y, bAllOperator);
		--RAISE NOTICE 'Calling query (%)', query;
		EXECUTE queryst INTO result;
        return result;
	else 
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			attr_data AS (
			  SELECT t.fid, t.fid as idsup, ''supp'' as niveau,(
				select insee_dep from departement 
				where gid = t.id_departement
			  ) as code_dep, 
				is_maintenance, 
				is_sav, 
				t.geom AS geom, %4$s as allop
			  FROM anfr_sup_support t
			  INNER JOIN support_filter sf ON sf.fid = t.fid 
			  group by t.fid, is_maintenance, is_sav
			),
			mvtgeom as (
				SELECT  public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom, t.fid, t.idsup, 
				t.niveau, t.code_dep, 
				case when not is_maintenance and not is_sav then ''en_service'' 
				else case when is_maintenance then ''en_maintenance''
				else ''a_venir'' end end as state, 
				t.allop 
				FROM 
				attr_data t , bounds 
				WHERE public.ST_Intersects(t.geom, bounds.geom )
			)
            SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		', z, x, y, bAllOperator);
		EXECUTE queryst INTO result;
        return result;
	end if;
end;
$_$;


--
-- TOC entry 1840 (class 1255 OID 1658742)
-- Name: fc_site_a_venir(integer, integer, integer, integer[], text[], text); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_site_a_venir(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	query text;
	queryFilter text;
	filter_techno_global text;
	bAllOperator boolean;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 

	filter_techno_global := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := filter_techno_global || ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := filter_techno_global || ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := filter_techno_global || ' AND s.site_strategique = true ';
    end if ; 
    
	if ( z < 9) then
		--Vue par departement
		query := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, t.id_departement, false as is_sav 
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site s ON s.sup_id = t.sup_id 
				WHERE code_op = any($4) ' || filter_techno_global || '
                AND t.id_departement is not null
                
				UNION 
                
                SELECT distinct t.fid, t.id_departement, true as is_sav
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site_a_venir s ON s.sup_id = t.sup_id 
				WHERE code_op = any($4) ' || filter_techno_global || '
				AND t.id_departement is not null
			),
			tot_dept AS (
                select t.id_departement, count(1) as tot_support, 
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from mrm_private.anfr_sup_support t 
				INNER JOIN support_filter sf ON sf.fid = t.fid 
				WHERE 1=1
				group by t.id_departement
			),
			mvtgeom AS (
			  SELECT d.gid, tot_support, ''dept'' as niveau, 
				case when tot_sav = 0 then false else true end as is_sav, 
              d.insee_dep as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, '|| bAllOperator ||' as allop,
                concat($1,''|'',$2,''|'',$3) as tile
			  FROM mrm_private.departement d
				INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
				LEFT JOIN tot_dept ON  d.gid = tot_dept.id_departement
				WHERE tot_support is not null
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		';
		--RAISE NOTICE 'Calling query (%)', query;
		EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return result;
		
	elsif ( z <= 10) then 
		--Vue par commune, On ajoute un buffer pour récupérer les supports autour de la tuile
		query := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, t.com_cd_insee, false as is_sav
				FROM anfr_sup_support t
				INNER JOIN site s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, public.ST_Buffer(bounds.geom, 10000) )
				WHERE code_op = any($4) ' || filter_techno_global || ' 
				
				UNION 
                
                SELECT distinct t.fid, t.com_cd_insee, true as is_sav
				FROM mrm_private.anfr_sup_support t
				INNER JOIN site_a_venir s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, public.ST_Buffer(bounds.geom, 10000) )
				WHERE code_op = any($4) ' || filter_techno_global || '
				AND t.id_departement is not null
			),
			tot_com AS (
				select sf.com_cd_insee as insee_com, count(1) as tot_support,	
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from anfr_sup_support t  
				INNER JOIN support_filter sf ON sf.fid = t.fid
				group by sf.com_cd_insee
				having count(1) > 0
			),
			mvtgeom AS (
			  SELECT c.gid, tot_support, ''com'' as niveau, 
			  c.insee_dep as code_dep, concat($1,''|'',$2,''|'',$3) as tile, 
				case when tot_sav = 0 then false else true end as is_sav, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, $5 as allop
			  FROM commune c
				INNER JOIN bounds ON public.ST_Intersects(c.geom, bounds.geom )
				LEFT JOIN tot_com ON  c.insee_com = tot_com.insee_com 
				WHERE tot_support is not null
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		';
		--RAISE NOTICE 'Calling query (%)', query;
		EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return result;
		
	elsif ( z <= 15) then 
		
		query := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, false as is_sav 
				FROM anfr_sup_support t
				INNER JOIN site s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, bounds.geom )
				WHERE code_op = any($4) ' || filter_techno_global || '
				
				UNION 
                
                SELECT distinct t.fid, true as is_sav
				FROM mrm_private.anfr_sup_support t
				INNER JOIN site_a_venir s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, public.ST_Buffer(bounds.geom, 10000) )
				WHERE code_op = any($4) ' || filter_techno_global || '
				AND t.id_departement is not null
				
			),
			clustered_points AS (
                SELECT public.ST_ClusterDBSCAN(t.geom, eps := 
				 (CASE 
					when $1 = 11 then 500
					when $1 = 12 then 385
					when $1 = 13 then 280
					when $1 = 14 then 150
					when $1 = 15 then 75
					ELSE 1 END
				   ) , minpoints := 1) over() AS cid, 
				sum(case when is_sav then 1 else 0 end) as tot_sav,
				t.fid, t.geom, t.sup_id
                FROM anfr_sup_support t
                INNER JOIN support_filter s ON s.fid = t.fid 
				group by t.fid, t.geom, t.sup_id
            ),
			mvtgeom AS (
			  SELECT cid, array_agg(sup_id) as sup_ids,array_agg(fid) as fids,
			  case when sum(tot_sav) = 0 then false else true end as is_sav,
			  concat($1,''|'',$2,''|'',$3) as tile as tile,
			  count(1) as tot_support, 
			  ''clust'' as niveau, (
			  	select insee_dep from departement t 
				where public.ST_contains(t.geom, public.ST_Centroid(public.ST_Collect(c.geom)))
			  ) as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(public.ST_Collect(c.geom)), bounds.geom) AS geom, $5 as allop
			  FROM clustered_points c, bounds 
			  WHERE public.ST_Intersects(c.geom, bounds.geom )
				group by cid, bounds.geom
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		';
		RAISE NOTICE 'Calling query (%)', query;
		EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return result;
	else 
		query := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, false as is_sav 
				FROM anfr_sup_support t
				INNER JOIN site s ON s.sup_id = t.sup_id
				INNER JOIN bounds ON public.ST_Intersects(t.geom, bounds.geom )
				WHERE code_op = any($4) ' || filter_techno_global || '
				
				UNION 
				
				
				SELECT distinct t.fid, true as is_sav 
				FROM anfr_sup_support t
				INNER JOIN site_a_venir s ON s.sup_id = t.sup_id
				INNER JOIN bounds ON public.ST_Intersects(t.geom, bounds.geom )
				WHERE code_op = any($4) ' || filter_techno_global || '
			),
			attr_data AS (
			  SELECT t.fid, t.fid as idsup, ''supp'' as niveau,(
				select insee_dep from departement 
				where gid = t.id_departement
			  ) as code_dep, 
				is_sav, 
				concat($1,''|'',$2,''|'',$3) as tile as tile,
				t.geom AS geom, $5 as allop
			  FROM anfr_sup_support t
			  INNER JOIN support_filter sf ON sf.fid = t.fid 
			  group by t.fid, sf.is_sav
			),
			mvtgeom as (
				SELECT  public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom, t.fid, t.idsup, 
				t.niveau, t.code_dep, t.is_sav, t.allop 
				FROM 
				attr_data t , bounds 
				WHERE public.ST_Intersects(t.geom, bounds.geom )
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		';
		EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return result;
	end if;
end;
$_$;


--
-- TOC entry 1841 (class 1255 OID 1658744)
-- Name: fc_site_a_venir_debug(integer, integer, integer, integer[], text[], text); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_site_a_venir_debug(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text) RETURNS text
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	queryst text;
	queryFilter text;
	filter_techno_global text;
	bAllOperator boolean;
	filter_techno text;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 

	filter_techno_global := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := filter_techno_global || ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := filter_techno_global || ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := filter_techno_global || ' AND s.site_strategique = true ';
    end if ; 
    
	if ( z < 9) then
		--Vue par departement
		queryst := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, t.id_departement, false as is_sav 
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site s ON s.sup_id = t.sup_id 
				WHERE code_op = any(liste_operateur) ' || filter_techno_global || '
                AND t.id_departement is not null
                
				UNION 
                
                SELECT distinct t.fid, t.id_departement, true as is_sav
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site_a_venir s ON s.sup_id = t.sup_id 
				WHERE code_op = any(liste_operateur) ' || filter_techno_global || '
				AND t.id_departement is not null
			),
			tot_dept AS (
                select t.id_departement, count(1) as tot_support, 
				sum(case when id_sav is null then 0 else 1 end) as tot_sav
				from mrm_private.anfr_sup_support t 
				INNER JOIN support_filter sf ON sf.fid = t.fid 
				WHERE 1=1
				group by t.id_departement
			),
			mvtgeom AS (
			  SELECT d.gid, tot_support, ''dept'' as niveau, 
				case when tot_sav = 0 then false else true end as is_sav, 
              d.insee_dep as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, '|| bAllOperator ||' as allop,
                2 as tile
			  FROM mrm_private.departement d
				INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
				LEFT JOIN tot_dept ON  d.gid = tot_dept.id_departement
				WHERE tot_support is not null
			)
			SELECT * 
			FROM mvtgeom limit 10
		';
		--RAISE NOTICE 'Calling query (%)', query;
        return queryst;
		
	elsif ( z <= 10) then 
		--Vue par commune, On ajoute un buffer pour récupérer les supports autour de la tuile
		queryst := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, sav.id as id_sav
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, public.ST_Buffer(bounds.geom, 10000) )
				LEFT JOIN mrm_private.site_a_venir sav ON s.id_station_anfr = sav.station_anfr
				WHERE code_op = any(liste_operateur) ' || filter_techno_global || ' 
			),
			tot_com AS (
				select com_cd_insee as insee_com, count(1) as tot_support, array_agg(t.fid) AS fids,				
				sum(case when id_sav is null then 0 else 1 end) as tot_sav 
				from mrm_private.anfr_sup_support t  
				INNER JOIN mrm_private.support_filter sf ON sf.fid = t.fid
				group by t.com_cd_insee
				having count(1) > 0
			),
			mvtgeom AS (
			  SELECT c.gid, tot_support, fids, ''com'' as niveau, 
			  c.insee_dep as code_dep, 2 as tile, 
				case when tot_sav = 0 then false else true end as is_sav, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, '|| bAllOperator ||' as allop
			  FROM mrm_private.commune c
				INNER JOIN bounds ON public.ST_Intersects(c.geom, bounds.geom )
				LEFT JOIN tot_com ON  c.insee_com = tot_com.insee_com 
				WHERE tot_support is not null
			)
			SELECT * 
			FROM mvtgeom limit 10
		';
		--RAISE NOTICE 'Calling query (%)', query;
        return queryst;
		
	elsif ( z <= 15) then 
		
		queryst := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, sav.id as id_sav 
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site s ON s.sup_id = t.sup_id 
				INNER JOIN bounds ON public.ST_Intersects(t.geom, bounds.geom )
				LEFT JOIN mrm_private.site_a_venir sav ON s.id_station_anfr = sav.station_anfr
				WHERE code_op = any(liste_operateur) ' || filter_techno_global || '
			),
			clustered_points AS (
                SELECT public.ST_ClusterDBSCAN(t.geom, eps := 75 , minpoints := 1) over() AS cid, 
				sum(case when id_sav is null then 0 else 1 end) as tot_sav,
				t.fid, t.geom, t.sup_id
                FROM mrm_private.anfr_sup_support t
                INNER JOIN support_filter s ON s.fid = t.fid 
				group by t.fid, t.geom, t.sup_id
            ),
			mvtgeom AS (
			  SELECT cid, array_agg(sup_id) as sup_ids, 
			  array_agg(c.fid) as fids, 
			  case when sum(tot_sav) = 0 then false else true end as is_sav,
			  count(1) as tot_support, 
			  ''clust'' as niveau, (
			  	select insee_dep from mrm_private.departement t 
				where public.ST_contains(t.geom, public.ST_Centroid(public.ST_Collect(c.geom)))
			  ) as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(public.ST_Collect(c.geom)), bounds.geom) AS geom, '|| bAllOperator ||' as allop
			  FROM clustered_points c, bounds 
			  WHERE public.ST_Intersects(c.geom, bounds.geom )
				group by cid, bounds.geom
			)
			SELECT * 
			FROM mvtgeom limit 10
		';
        return queryst;
	else 
		queryst := '
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope('|| z ||','|| x ||',' || y || ') AS geom
			),
			support_filter AS (
				SELECT distinct t.fid, sav.id as id_sav 
				FROM mrm_private.anfr_sup_support t
				INNER JOIN mrm_private.site s ON s.sup_id = t.sup_id
				INNER JOIN bounds ON public.ST_Intersects(t.geom, bounds.geom )
				LEFT JOIN mrm_private.site_a_venir sav ON s.id_station_anfr = sav.station_anfr
				WHERE code_op = any(' || liste_operateur|| ') ' || filter_techno_global || '
			),
			attr_data AS (
			  SELECT t.fid, t.fid as idsup, ''supp'' as niveau,(
				select insee_dep from mrm_private.departement 
				where gid = t.id_departement
			  ) as code_dep, 
				case when id_sav is null then false else true end as is_sav, 
				t.geom AS geom, '|| bAllOperator ||' as allop
			  FROM mrm_private.anfr_sup_support t
			  INNER JOIN support_filter sf ON sf.fid = t.fid 
			  group by t.fid, id_sav
			),
			mvtgeom as (
				SELECT  public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom, t.fid, t.idsup, 
				t.niveau, t.code_dep, t.is_sav, t.allop 
				FROM 
				attr_data t , bounds 
				WHERE public.ST_Intersects(t.geom, bounds.geom )
			)
			SELECT * 
			FROM mvtgeom limit 10
		';
        return queryst;
	end if;
end;
$$;


--
-- TOC entry 1827 (class 1255 OID 1658746)
-- Name: fc_site_debug(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_site_debug(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS text
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	--result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 

	filter_techno_global := '';
	filter_techno_site := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := 'true';
	else
		bAllOperator := 'false';
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := filter_techno_global || ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := filter_techno_global || ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := filter_techno_global || ' AND s.site_strategique = true ';
    end if ; 
    
	filter_techno_site := filter_techno_global;
	
    if array_length(state, 1) = 1 and 'maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
    elseif array_length(state, 1) = 2 and 'maintenance' = ANY(state) and 'sav' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
    elseif array_length(state, 1) = 2 and 'service' = ANY(state) and 'sav' = ANY(state) then 
		filter_techno_site := ' AND st.id is null ';
    end if ; 
	
	querysite := format('
			SELECT distinct t.fid, 
			case when st.id is not null then true else false end as is_maintenance , 
			false as is_sav 
			FROM %1$s.anfr_sup_support t
			INNER JOIN %1$s.site s ON s.sup_id = t.sup_id 
			LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
			WHERE code_op = any(array[%3$s]) %2$s', 
			schema_function, 
			filter_techno_site, 
			array_to_string(liste_operateur, ', ')
			) ;

	querysav := format('
			SELECT distinct t.fid, false as is_maintenance , true as is_sav 
			FROM %1$s.anfr_sup_support t
			INNER JOIN %1$s.site_a_venir s ON s.sup_id = t.sup_id 
			WHERE code_op = any(array[%3$s]) %2$s ', 
			schema_function, 
			filter_techno_global, 
			array_to_string(liste_operateur, ', ')
			) ;

	if array_length(state, 1) = 1 and 'maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'sav' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'sav' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 

	if ( z < 9) then
		--Vue par departement
		
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			tot_dept AS (
                select t.id_departement, count(1) as tot_support, 
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from '||schema_function||'.anfr_sup_support t 
				INNER JOIN support_filter sf ON sf.fid = t.fid 
				WHERE 1=1
				group by t.id_departement
			),
			mvtgeom AS (
			  SELECT d.gid, tot_support, ''dept'' as niveau,  
				case when tot_maintenance = 0 and tot_sav = 0 then ''service'' 
				else case when tot_maintenance >= tot_sav then ''maintenance''
				else ''sav'' end end as state,
              d.insee_dep as code_dep, 
				public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, %4$s as allop,
                concat(%1$s,''|'',%2$s,''|'',%3$s) as tile
			  FROM '||schema_function||'.departement d
				INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
				LEFT JOIN tot_dept ON  d.gid = tot_dept.id_departement
				WHERE tot_support is not null
			)
			SELECT *
			FROM mvtgeom limit 10
		', z, x, y, bAllOperator);
		--RAISE NOTICE 'Calling query (%)', query;
		--EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return queryst;
		
	elsif ( z <= 10) then 
		--Vue par commune, On ajoute un buffer pour récupérer les supports autour de la tuile
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			tot_com AS (
				select com_cd_insee as insee_com, count(1) as tot_support, array_agg(t.fid) AS fids,
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav
				from '||schema_function||'.anfr_sup_support t  
				INNER JOIN support_filter sf ON sf.fid = t.fid
				group by t.com_cd_insee
				having count(1) > 0
			),
			mvtgeom AS (
			  SELECT c.gid, tot_support, fids, ''com'' as niveau, 
			  c.insee_dep as code_dep, concat(%1$s,''|'',%2$s,''|'',%3$s) as tile, 
				case when tot_maintenance = 0 and tot_sav = 0 then ''service'' 
				else case when tot_maintenance >= tot_sav then ''maintenance''
				else ''sav'' end end as state,
				public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, %4$s as allop
			  FROM '||schema_function||'.commune c
				INNER JOIN bounds ON public.ST_Intersects(c.geom, bounds.geom )
				LEFT JOIN tot_com ON  c.insee_com = tot_com.insee_com 
				WHERE tot_support is not null
			)
			SELECT *
			FROM mvtgeom limit 10
		', z, x, y, bAllOperator);
		--RAISE NOTICE 'Calling query (%)', query;
		--EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return queryst;
		
	elsif ( z <= 15) then 
		
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			clustered_points AS (
                SELECT public.ST_ClusterDBSCAN(t.geom, eps := 
				 (CASE 
					when %1$s = 11 then 500
					when %1$s = 12 then 385
					when %1$s = 13 then 280
					when %1$s = 14 then 150
					when %1$s = 15 then 75
					ELSE 1 END
				   ) , minpoints := 1) over() AS cid, 
				is_maintenance,
				is_sav,
				t.fid, t.geom, t.sup_id
                FROM '||schema_function||'.anfr_sup_support t
                INNER JOIN support_filter s ON s.fid = t.fid 
            ),
			grouped_data as (
				select cid, 
				sum(case when is_maintenance then 1 else 0 end) as tot_maintenance,
				sum(case when is_sav then 1 else 0 end) as tot_sav,
			  	count(1) as tot_support, 
				array_agg(c.fid) as fids, 
				public.ST_PointOnSurface(public.ST_Collect(c.geom)) as geom, 
				array_agg(c.sup_id) as supids
				from clustered_points c, bounds
				where public.ST_Intersects(c.geom, bounds.geom )
				group by cid 
			),
			mvtgeom AS (
						 
			  SELECT cid, array_agg(sup_id) as sup_ids, 
			  array_agg(c.fid) as fids, 
				case when tot_maintenance = 0 and tot_sav = 0 then ''en_service'' 
				else case when tot_maintenance >= tot_sav then ''en_maintenance''
				else ''a_venir'' end end as state,
			  count(1) as tot_support, 
			  ''clust'' as niveau, (
			  	select insee_dep from '||schema_function||'.departement t 
				where public.ST_contains(t.geom, public.ST_Centroid(public.ST_Collect(c.geom)))
			  ) as code_dep, 
				public.ST_AsMVTGeom(c.geom, bounds.geom) AS geom, %4$s as allop
			  FROM clustered_points c, bounds 
			  WHERE public.ST_Intersects(c.geom, bounds.geom )
				group by cid, bounds.geom
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		', z, x, y, bAllOperator);
		--RAISE NOTICE 'Calling query (%)', query;
		--EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return queryst;
	else 
		queryst := format('
			WITH
			bounds AS (
				SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
			),
			support_filter AS (
				'||queryunion||'
			),
			attr_data AS (
			  SELECT t.fid, t.fid as idsup, ''supp'' as niveau,(
				select insee_dep from '||schema_function||'.departement 
				where gid = t.id_departement
			  ) as code_dep, 
				is_maintenance, 
				is_sav, 
				t.geom AS geom, %4$s as allop
			  FROM '||schema_function||'.anfr_sup_support t
			  INNER JOIN support_filter sf ON sf.fid = t.fid 
			  group by t.fid, is_maintenance, is_sav
			),
			mvtgeom as (
				SELECT  public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom, t.fid, t.idsup, 
				t.niveau, t.code_dep, 
				case when not is_maintenance and not is_sav then ''service'' 
				else case when is_maintenance then ''maintenance''
				else ''sav'' end end as state, 
				t.allop 
				FROM 
				attr_data t , bounds 
				WHERE public.ST_Intersects(t.geom, bounds.geom )
			)
			SELECT *
			FROM mvtgeom limit 10
		', z, x, y, bAllOperator);
		--EXECUTE query INTO result USING z, x, y, liste_operateur, bAllOperator;
        return queryst;
	end if;
end;
$_$;


--
-- TOC entry 1842 (class 1255 OID 1658748)
-- Name: fc_support_cluster(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_support_cluster(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	
	if array_length(state, 1) is null then 
		return null;
	end if ; 
	
	PERFORM set_config('search_path', schema_function, TRUE); 
	if ( z < 9) then
		return fc_support_cluster_dept(z, x, y, liste_operateur,techonologies, dispositif, state);
	elsif ( z <= 10) then 
		return fc_support_cluster_com(z, x, y, liste_operateur,techonologies, dispositif, state);
	elsif ( z <= 15) then 
		return fc_support_cluster_clu(z, x, y, liste_operateur,techonologies, dispositif, state);
	else 
		return fc_support_cluster_sup(z, x, y, liste_operateur,techonologies, dispositif, state);
	end if;
end;
$$;


--
-- TOC entry 1843 (class 1255 OID 1658749)
-- Name: fc_support_cluster_clu(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_support_cluster_clu(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := mrm_private.fc_support_cluster_filterbuilder(
		liste_operateur, 
		techonologies, 
		dispositif, 
		state
	);
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	filter_techno_site := '';
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_maintenance' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is not null ';
    end if ; 
	
	filter_techno_site := filter_techno_global || filter_techno_site ;
	
	querysite := format('
		select s.sup_id, false as is_sav, 
		case when st.id is not null then true else false end as is_maintenance  
		from %1$s.site s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
		WHERE code_op = any(array[%3$s]) %2$s', 
		schema_function, 
		filter_techno_site, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	querysav := format('
		select s.sup_id, true as is_sav, false as is_maintenance
		from %1$s.site_a_venir s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		WHERE code_op = any(array[%3$s]) %2$s' , 
		schema_function, 
		filter_techno_global, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 
	
	queryst := format('
		WITH bounds AS (
			SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
		),
		list_sup_ids as (
            select sup_id from '||schema_function||'.anfr_sup_support t
            inner join bounds ON public.ST_Intersects(public.st_buffer(bounds.geom, 30), t.geom)
		),
		site_all as (
			'|| queryunion || '
		), 
		support_filter as (
            select distinct t.fid,  
            sum(
                case when is_maintenance then 1 else 0 end
            ) as nb_maintenance,  
            sum(
                case when not is_maintenance and is_sav then 1 else 0 end
            ) as nb_sav, 
            sum(
                case when not is_maintenance and not is_sav then 1 else 0 end
            ) as nb_service
            FROM '||schema_function||'.anfr_sup_support t
            INNER JOIN site_all s ON s.sup_id = t.sup_id 
            group by fid
        ),
        clustered_points AS (
            SELECT public.ST_ClusterDBSCAN(t.geom, eps := 
             (CASE 
                when %1$s = 11 then 500
                when %1$s = 12 then 385
                when %1$s = 13 then 280
                when %1$s = 14 then 150
                when %1$s = 15 then 75
                ELSE 1 END
               ) , minpoints := 1) over() AS cid, 
            case when nb_maintenance > 0 then ''en_maintenance'' 
                else case when nb_sav > 0 then ''a_venir''
                else ''en_service'' end 
            end as state ,
            t.fid, t.geom
            FROM '||schema_function||'.anfr_sup_support t
            INNER JOIN support_filter s ON s.fid = t.fid 
            group by t.fid, t.geom, nb_maintenance, nb_sav, nb_service
        ),
        agg_clu as (
            select cid, public.ST_Centroid(public.ST_Collect(geom)) as geom, 
            array_agg(fid) as fids,
            count(1) as tot_support,
            '||schema_function||'.fc_support_cluster_getmainstate(array_agg(state)) as state
            from clustered_points 
            group by cid
        ),
        mvtgeom AS (
          SELECT 
          fids, 
          state,
          tot_support::integer, 
          ''clust'' as niveau, (
            select insee_dep from '||schema_function||'.departement t 
            where public.ST_contains(t.geom, c.geom)
          ) as code_dep, 
            public.ST_AsMVTGeom(c.geom, bounds.geom) AS geom, %5$s as allop
          FROM agg_clu c, bounds 
          WHERE public.ST_contains(bounds.geom, c.geom)
        )
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom', z, x, y, schema_function, bAllOperator
	); 
	--RAISE NOTICE 'Calling query (%)', queryst;
	EXECUTE queryst INTO result ;
    return result;
	
end;
$_$;


--
-- TOC entry 1844 (class 1255 OID 1658751)
-- Name: fc_support_cluster_com(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_support_cluster_com(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := mrm_private.fc_support_cluster_filterbuilder(
		liste_operateur, 
		techonologies, 
		dispositif, 
		state
	);
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	filter_techno_site := '';
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_maintenance' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is not null ';
    end if ; 
	
	filter_techno_site := filter_techno_global || filter_techno_site ;
	
	querysite := format('
		select s.sup_id, false as is_sav, 
		case when st.id is not null then true else false end as is_maintenance  
		from %1$s.site s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
		WHERE code_op = any(array[%3$s]) %2$s', 
		schema_function, 
		filter_techno_site, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	querysav := format('
		select s.sup_id, true as is_sav, false as is_maintenance
		from %1$s.site_a_venir s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		WHERE code_op = any(array[%3$s]) %2$s' , 
		schema_function, 
		filter_techno_global, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 
	
	queryst := format('
		WITH bounds AS (
			SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
		),
		list_sup_ids as (
			select sup_id from '||schema_function||'.anfr_sup_support 
			where id_departement in (
				select gid from '||schema_function||'.departement d, bounds
				where public.ST_Intersects(d.geom, bounds.geom )
			)
		),
		site_all as (
			'|| queryunion || '
		), 
		support_filter as (
			select distinct t.fid,  
			sum(
				case when is_maintenance then 1 else 0 end
			) as nb_maintenance,  
			sum(
				case when not is_maintenance and is_sav then 1 else 0 end
			) as nb_sav, 
			sum(
				case when not is_maintenance and not is_sav then 1 else 0 end
			) as nb_service
			FROM '||schema_function||'.anfr_sup_support t
			INNER JOIN site_all s ON s.sup_id = t.sup_id 
			group by fid
		),
		tot_com_by_type as (
			select t.com_cd_insee, count(1) as tot_support, 
			sum(nb_maintenance) as nb_maintenance, 
			sum(nb_sav) as nb_sav,
			sum(nb_service) as nb_service,
			array_agg(t.fid ) as fids 
			from '||schema_function||'.anfr_sup_support t 
			INNER JOIN support_filter sf ON sf.fid = t.fid 
			WHERE 1=1
			group by t.com_cd_insee
		),
		agg_com as (
			select 
				com_cd_insee, 
				fids,
				sum(tot_support) as tot_support, 
				case when nb_maintenance > 0 then ''en_maintenance''
					else case when nb_sav > 0 then ''a_venir''
					else ''en_service'' end 
				end as state 
			from tot_com_by_type
			where com_cd_insee is not null
			group by com_cd_insee, fids, nb_maintenance, nb_sav 
		),
		mvtgeom AS (
		  SELECT c.gid, tot_support::integer, ''com'' as niveau, state,
		  c.insee_dep as code_dep, fids,
			public.ST_AsMVTGeom(public.ST_PointOnSurface(c.geom), bounds.geom) AS geom, %5$s as allop,
			concat(%1$s,''|'',%2$s,''|'',%3$s) as tile
		  FROM '||schema_function||'.commune c
			INNER JOIN bounds ON public.ST_Intersects(public.ST_PointOnSurface(c.geom), bounds.geom )
			LEFT JOIN agg_com ON  c.insee_com = agg_com.com_cd_insee
			WHERE tot_support is not null
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom', z, x, y, schema_function, bAllOperator
	); 
	--RAISE NOTICE 'Calling query %', queryst;
	EXECUTE queryst INTO result ;
    return result;
	
end;
$_$;


--
-- TOC entry 1845 (class 1255 OID 1658753)
-- Name: fc_support_cluster_dept(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_support_cluster_dept(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := mrm_private.fc_support_cluster_filterbuilder(
		liste_operateur, 
		techonologies, 
		dispositif, 
		state
	);
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	filter_techno_site := '';
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_maintenance' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is not null ';
    end if ; 
	
	filter_techno_site := filter_techno_global || filter_techno_site ;
	
	querysite := format('
		select s.sup_id, false as is_sav, 
		case when st.id is not null then true else false end as is_maintenance  
		from %1$s.site s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
		WHERE code_op = any(array[%3$s]) %2$s', 
		schema_function, 
		filter_techno_site, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	querysav := format('
		select s.sup_id, true as is_sav, false as is_maintenance
		from %1$s.site_a_venir s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		WHERE code_op = any(array[%3$s]) %2$s' , 
		schema_function, 
		filter_techno_global, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 
	
	queryst := format('
		WITH bounds AS (
			SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
		),
		list_sup_ids as (
			select sup_id from '||schema_function||'.anfr_sup_support 
			where id_departement in (
				select gid from '||schema_function||'.departement d, bounds
				where public.ST_Intersects(d.geom, bounds.geom )
			)
		),
		site_all as (
			'|| queryunion || '
		), 
		support_filter as (
			select distinct t.fid,  
			sum(
				case when is_maintenance then 1 else 0 end
			) as nb_maintenance,  
			sum(
				case when not is_maintenance and is_sav then 1 else 0 end
			) as nb_sav, 
			sum(
				case when not is_maintenance and not is_sav then 1 else 0 end
			) as nb_service
			FROM '||schema_function||'.anfr_sup_support t
			INNER JOIN site_all s ON s.sup_id = t.sup_id 
			group by fid
		),
		tot_dept_by_type as (
			select t.id_departement, count(1) as tot_support, 
			sum(nb_maintenance) as nb_maintenance, 
			sum(nb_sav) as nb_sav,
			sum(nb_service) as nb_service,
			array_agg(t.fid ) as fids 
			from '||schema_function||'.anfr_sup_support t 
			INNER JOIN support_filter sf ON sf.fid = t.fid 
			WHERE 1=1
			group by t.id_departement
		),
		agg_dept as (
			select 
				id_departement, 
				fids,
				sum(tot_support) as tot_support, 
				case when nb_maintenance > 0 then ''en_maintenance''
					else case when nb_sav > 0 then ''a_venir''
					else ''en_service'' end 
				end as state 
			from tot_dept_by_type
			where id_departement is not null
			group by id_departement, fids, nb_maintenance, nb_sav 
		),
		mvtgeom AS (
		  SELECT d.gid, tot_support::integer, 
		  ''dept'' as niveau, state, fids,
		  d.insee_dep as code_dep, 
			public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, %5$s as allop,
			concat(%1$s,''|'',%2$s,''|'',%3$s) as tile
		  FROM '||schema_function||'.departement d
			INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
			LEFT JOIN agg_dept ON  d.gid = agg_dept.id_departement
			WHERE tot_support is not null
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom', z, x, y, schema_function, bAllOperator
	); 
	--RAISE NOTICE 'Calling query %', queryst;
	EXECUTE queryst INTO result ;
    return result;
	
end;
$_$;


--
-- TOC entry 1846 (class 1255 OID 1658755)
-- Name: fc_support_cluster_dept_debug(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_support_cluster_dept_debug(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS text
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := mrm_private.fc_support_cluster_filterbuilder(
		liste_operateur, 
		techonologies, 
		dispositif, 
		state
	);
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	filter_techno_site := '';
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_maintenance' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is not null ';
    end if ; 
	
	filter_techno_site := filter_techno_global || filter_techno_site ;
	
	querysite := format('
		select s.sup_id, false as is_sav, 
		case when st.id is not null then true else false end as is_maintenance  
		from %1$s.site s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
		WHERE code_op = any(array[%3$s]) %2$s', 
		schema_function, 
		filter_techno_site, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	querysav := format('
		select s.sup_id, true as is_sav, false as is_maintenance
		from %1$s.site_a_venir s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		WHERE code_op = any(array[%3$s]) %2$s' , 
		schema_function, 
		filter_techno_global, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 
	
	queryst := format('
		WITH bounds AS (
			SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
		),
		list_sup_ids as (
			select sup_id from '||schema_function||'.anfr_sup_support 
			where id_departement in (
				select gid from '||schema_function||'.departement d, bounds
				where public.ST_Intersects(d.geom, bounds.geom )
			)
		),
		site_all as (
			'|| queryunion || '
		), 
		support_filter as (
			select distinct t.fid,  
			sum(
				case when is_maintenance then 1 else 0 end
			) as nb_maintenance,  
			sum(
				case when not is_maintenance and is_sav then 1 else 0 end
			) as nb_sav, 
			sum(
				case when not is_maintenance and not is_sav then 1 else 0 end
			) as nb_service
			FROM '||schema_function||'.anfr_sup_support t
			INNER JOIN site_all s ON s.sup_id = t.sup_id 
			group by fid
		),
		tot_dept_by_type as (
			select t.id_departement, count(1) as tot_support, array_agg(t.fid ) as fids,
			case when nb_maintenance > 0 then ''en_maintenance'' 
				else case when nb_sav > 0 then ''a_venir'' 
				else ''en_service'' end 
			end as state 
			from '||schema_function||'.anfr_sup_support t 
			INNER JOIN support_filter sf ON sf.fid = t.fid 
			WHERE 1=1
			group by t.id_departement, sf.nb_maintenance, sf.nb_sav
		),
		agg_dept as (
			select 
				id_departement, 
				fids,
				sum(tot_support) as tot_support, 
			    '||schema_function||'.fc_support_cluster_getmainstate(array_agg(state)) as state
			from tot_dept_by_type 
			where id_departement is not null
			group by id_departement, fids
		),
		mvtgeom AS (
		  SELECT d.gid, tot_support::integer, 
		  ''dept'' as niveau, state, fids,
		  d.insee_dep as code_dep, 
			public.ST_AsMVTGeom(public.ST_PointOnSurface(d.geom), bounds.geom) AS geom, %5$s as allop,
			concat(%1$s,''|'',%2$s,''|'',%3$s) as tile
		  FROM '||schema_function||'.departement d
			INNER JOIN bounds ON public.ST_Intersects(d.geom, bounds.geom )
			LEFT JOIN agg_dept ON  d.gid = agg_dept.id_departement
			WHERE tot_support is not null
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom', z, x, y, schema_function, bAllOperator
	); 
	--RAISE NOTICE 'Calling query %', queryst;
	--EXECUTE queryst INTO result ;
    return queryst;
	
end;
$_$;


--
-- TOC entry 1847 (class 1255 OID 1658757)
-- Name: fc_support_cluster_filterbuilder(integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_support_cluster_filterbuilder(liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	filter_techno_global text;
	filter_techno text;
	schema_function text;
	bAllOperator text;
begin

	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := '';
	filter_techno := '';
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := 'true';
	else
		bAllOperator := 'false';
	end if;
	
	if (supports_istechno(techonologies, '2G')) then 
		filter_techno := filter_techno || ' s.site_2g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '3G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_3g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '4G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' s.site_4g = true ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = true ) ' ; 
	end if; 

	if (supports_istechno(techonologies, '5G_OTHERS')) then 
		if filter_techno <> '' then 
			filter_techno := filter_techno || ' OR ';
		end if;
		filter_techno := filter_techno || ' ( s.site_5g = true AND s.site_5g_3500_m_hz = false ) ' ; 
	end if; 

	if filter_techno <> '' then
		filter_techno_global := ' AND ( ' || filter_techno || ' ) ';
	end if;
    
    if dispositif = 'dcc' then 
		filter_techno_global := filter_techno_global || ' AND s.site_dcc = true ';
    end if ; 
	
    if dispositif = 'zb' then 
		filter_techno_global := filter_techno_global || ' AND s.site_zb = true ';
    end if ; 
    
    if dispositif = 'strategique' then 
		filter_techno_global := filter_techno_global || ' AND s.site_strategique = true ';
    end if ; 
    return filter_techno_global ;
end;
$$;


--
-- TOC entry 1848 (class 1255 OID 1658758)
-- Name: fc_support_cluster_getmainstate(text[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_support_cluster_getmainstate(state text[]) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE 
	resultstate text;
begin
	resultstate := 'en_service';
	if 'en_maintenance' = ANY(state) then 
		resultstate := 'en_maintenance';
	elseif 'a_venir' = ANY(state) then 
		resultstate := 'a_venir';
	end if;
	return resultstate;
end;
$$;


--
-- TOC entry 1849 (class 1255 OID 1658759)
-- Name: fc_support_cluster_sup(integer, integer, integer, integer[], text[], text, text[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_support_cluster_sup(z integer, x integer, y integer, liste_operateur integer[], techonologies text[], dispositif text, state text[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

#variable_conflict use_variable
DECLARE 
	queryst text;
	querysite text;
	querysav text;
	queryunion text;
	queryFilter text;
	filter_techno_global text;
	filter_techno_site text;
	bAllOperator text;
	filter_techno text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	
	filter_techno_global := mrm_private.fc_support_cluster_filterbuilder(
		liste_operateur, 
		techonologies, 
		dispositif, 
		state
	);
	
	if ARRAY_LENGTH(liste_operateur, 1) > 1 then 
		bAllOperator := true;
	else
		bAllOperator := false;
	end if;
	
	filter_techno_site := '';
	
    if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		filter_techno_site := ' AND st.id is not null ';
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_maintenance' = ANY(state) then
		filter_techno_site := ' AND st.id is null ';
	elseif array_length(state, 1) = 2 and not 'en_service' = ANY(state) then
		filter_techno_site := ' AND st.id is not null ';
    end if ;  
	
	
	filter_techno_site := filter_techno_global || filter_techno_site ;
	
	querysite := format('
		select s.sup_id, false as is_sav, 
		case when st.id is not null then true else false end as is_maintenance  
		from %1$s.site s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		LEFT JOIN %1$s.site_state st ON s.id_station_anfr = st.station_anfr
		WHERE code_op = any(array[%3$s]) %2$s', 
		schema_function, 
		filter_techno_site, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	querysav := format('
		select s.sup_id, true as is_sav, false as is_maintenance
		from %1$s.site_a_venir s 
		INNER JOIN list_sup_ids l ON l.sup_id = s.sup_id
		WHERE code_op = any(array[%3$s]) %2$s' , 
		schema_function, 
		filter_techno_global, 
		array_to_string(liste_operateur, ', ')
	) ;
	
	
	if array_length(state, 1) = 1 and 'en_maintenance' = ANY(state) then 
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'en_service' = ANY(state) then
		queryunion := querysite;
	elseif array_length(state, 1) = 1 and 'a_venir' = ANY(state) then
		queryunion := querysav;
	elseif array_length(state, 1) = 2 and not 'a_venir' = ANY(state) then
		queryunion := querysite;
	else 
		queryunion := querysite||' UNION '||querysav;
	end if ; 
	
	queryst := format('
		WITH bounds AS (
			SELECT public.ST_TileEnvelope(%1$s, %2$s, %3$s) AS geom
		),
		list_sup_ids as (
            select sup_id from '||schema_function||'.anfr_sup_support t
            inner join bounds ON public.ST_Intersects(public.st_buffer(bounds.geom, 30), t.geom)
		),
		site_all as (
			'|| queryunion || '
		), 
		support_filter as (
            select distinct t.fid, geom, t.id_departement,
            sum(
                case when is_maintenance then 1 else 0 end
            ) as nb_maintenance,  
            sum(
                case when not is_maintenance and is_sav then 1 else 0 end
            ) as nb_sav, 
            sum(
                case when not is_maintenance and not is_sav then 1 else 0 end
            ) as nb_service
            FROM %4$s.anfr_sup_support t
            INNER JOIN site_all s ON s.sup_id = t.sup_id 
            group by fid, id_departement
        ),
        support_filter_class as (
			select fid, geom, case when nb_maintenance > 0 then ''en_maintenance'' 
                else case when nb_sav > 0 then ''a_venir''
                else ''en_service'' end 
            end as state,
			''supp'' as niveau,
			(
				select insee_dep from %4$s.departement 
				where gid = t.id_departement
			  ) as code_dep
			from support_filter t
        ),
		mvtgeom AS (
			SELECT  
				fid, state, niveau, code_dep, 
				public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom
				FROM 
				support_filter_class t , bounds 
				WHERE public.ST_Intersects(t.geom, bounds.geom )
        )
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom', z, x, y, schema_function, bAllOperator
	); 
	RAISE NOTICE 'Calling query (%)', queryst;
	EXECUTE queryst INTO result ;
    return result;
	
end;
$_$;


--
-- TOC entry 1850 (class 1255 OID 1658760)
-- Name: fc_zac_poi(integer, integer, integer, text); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.fc_zac_poi(z integer, x integer, y integer, operateur text) RETURNS bytea
    LANGUAGE plpgsql
    AS $_$

DECLARE 
	query text;
	subquery text;
	schema_function text;
	result bytea;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 

	if (operateur = 'all') then 
		subquery := 'select id, z.id_point, num_zone_arrete, geom from zac_poi z';
	else
		subquery := 'select id, z.id_point, num_zone_arrete, geom from zac_poi z
inner join zac_poi_operateurs op ON op.id_point = z.id_point
where op.id_operateur = '||operateur ;
	end if;
	
    query := '
        WITH
        bounds AS (
            SELECT public.ST_TileEnvelope($1, $2, $3) AS geom
        ),
        zac_filter AS (' || subquery || '),
        mvtgeom AS (
          SELECT public.ST_AsMVTGeom(t.geom, bounds.geom) AS geom, t.id, t.id_point, t.num_zone_arrete
          FROM zac_filter t, bounds
          WHERE public.ST_Intersects(t.geom, bounds.geom )
        )
        SELECT public.ST_AsMVT(mvtgeom)
        FROM mvtgeom
    ';
    EXECUTE query INTO result USING z, x, y;
    return result;
end;
$_$;


--
-- TOC entry 1852 (class 1255 OID 1658761)
-- Name: generate_couvertures_tbc_tiles(integer, integer, integer, character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.generate_couvertures_tbc_tiles(z integer, x integer, y integer, in_techno character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	return (
		WITH
		bounds AS (
		  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
		 (CASE 
			when z >= 12 then 0
			when z = 11 then 0
			when z = 10 then 10
			when z = 9 then 100
			when z = 8 then 300
			when z = 7 then 900
			when z = 6 then 1500
			when z <= 5 then 3000 
			ELSE 1 END
		   ) as simplify_tolerance
		),

		mvtgeom AS (
		  SELECT fid, operateur, dept,
			public.ST_AsMVTGeom(
				  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

		  FROM couverture_theorique t, bounds
		  WHERE public.ST_Intersects(t.geom, bounds.geom )
			and techno = in_techno 
			and niveau = 'TBC'
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1853 (class 1255 OID 1658762)
-- Name: generate_couvertures_tiles(integer, integer, integer, bigint, character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.generate_couvertures_tiles(z integer, x integer, y integer, liste_operateur bigint, liste_techno character varying) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	return (
		WITH
		bounds AS (
		  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
		 (CASE 
			when z >= 12 then 0
			when z = 11 then 0
			when z = 10 then 10
			when z = 9 then 100
			when z = 8 then 300
			when z = 7 then 900
			when z = 6 then 1500
			when z <= 5 then 3000 
			ELSE 1 END
		   ) as simplify_tolerance
		),

		mvtgeom AS (
		  SELECT fid, operateur, date, techno, usage, niveau, dept, filename,
			public.ST_AsMVTGeom(
				  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

		  FROM couverture_theorique t, bounds
		  WHERE public.ST_Intersects(t.geom, bounds.geom )
			and operateur = liste_operateur
			and techno = liste_techno
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1854 (class 1255 OID 1658763)
-- Name: generate_hexa_layer(); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.generate_hexa_layer() RETURNS TABLE(fid bigint, geom public.geometry)
    LANGUAGE plpgsql
    AS $$
	
DECLARE 
	code_operateur_result text;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE);
	RETURN QUERY (with pts as (
		select geometry from qos
	)
	SELECT row_number() over () as fid, hex.geom
	FROM pts 
	--30 ou 300, à vérifier
	INNER JOIN public.ST_HexagonGrid(300, pts.geometry) AS hex ON public.ST_Intersects(pts.geometry, hex.geom)
	group by hex.geom);
end;
$$;


--
-- TOC entry 1855 (class 1255 OID 1658764)
-- Name: generate_hexa_signalement(integer); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.generate_hexa_signalement(radius integer) RETURNS TABLE(fid bigint, geom public.geometry)
    LANGUAGE plpgsql
    AS $$
	
DECLARE 
	code_operateur_result text;
	schema_function text;
begin
	schema_function := public.parent_schema();
	RAISE NOTICE 'schema_function: %', schema_function;
	PERFORM set_config('search_path', schema_function, TRUE);
	RETURN QUERY (with pts as (
		select geometry from signalement
	)
	SELECT row_number() over () as fid, hex.geom
	FROM pts 
	--30 ou 300, à vérifier
	INNER JOIN public.ST_HexagonGrid(radius, pts.geometry) AS hex ON public.ST_Intersects(pts.geometry, hex.geom)
	group by hex.geom);
	
end;
$$;


--
-- TOC entry 1856 (class 1255 OID 1658765)
-- Name: gettilesintersectinglayer(bigint, character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.gettilesintersectinglayer(liste_operateur bigint, liste_techno character varying) RETURNS TABLE(x integer, y integer, z integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tile_bounds public.GEOMETRY;
	max_zoom INTEGER := 7;
	schema_function text;
BEGIN
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	FOR current_zoom IN 1..max_zoom LOOP
		FOR _x IN 0..(2 ^ current_zoom - 1)
		LOOP
			FOR _y IN 0..(2 ^ current_zoom - 1)
			LOOP
				tile_bounds := public.ST_TileEnvelope(current_zoom, _x, _y);
				IF EXISTS (
					SELECT 1 FROM couverture_theorique
					WHERE public.ST_Intersects(geom, tile_bounds)
					AND operateur = liste_operateur
					AND techno = liste_techno
				)
				THEN
					RAISE NOTICE 'Computing %', current_zoom || ', ' || _x || ', ' || _y;
					z := current_zoom;
					x := _x;
					y := _y;
					RETURN NEXT;
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;
END;
$$;


--
-- TOC entry 1857 (class 1255 OID 1658766)
-- Name: gettilesintersectinglayer_couverture_tbc(character varying); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.gettilesintersectinglayer_couverture_tbc(in_techno character varying) RETURNS TABLE(x integer, y integer, z integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tile_bounds public.GEOMETRY;
	max_zoom INTEGER := 9;
	schema_function text;
BEGIN
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	FOR current_zoom IN 1..max_zoom LOOP
		FOR _x IN 0..(2 ^ current_zoom - 1)
		LOOP
			FOR _y IN 0..(2 ^ current_zoom - 1)
			LOOP
				tile_bounds := public.ST_TileEnvelope(current_zoom, _x, _y);
				IF EXISTS (
					SELECT 1 FROM couverture_theorique
					WHERE public.ST_Intersects(geom, tile_bounds)
					AND techno = in_techno
					AND niveau= 'TBC'
				)
				THEN
					RAISE NOTICE 'Computing %', current_zoom || ', ' || _x || ', ' || _y;
					z := current_zoom;
					x := _x;
					y := _y;
					RETURN NEXT;
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;
END;
$$;


--
-- TOC entry 1858 (class 1255 OID 1658767)
-- Name: lunch_generate_hexa_signalement(integer); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.lunch_generate_hexa_signalement(radius integer) RETURNS void
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();

	PERFORM set_config('search_path', schema_function, TRUE); 
	--Suppression des données
	delete from hexa_signalement;
	--injection du carroyage hexa
	insert into hexa_signalement (fid, geometry) select * from generate_hexa_signalement(radius);
	--Association des hexa aux données
	UPDATE signalement t SET id_hexa = h.fid
	FROM hexa_signalement as h WHERE public.ST_Intersects(t.geometry, h.geometry);
	--découpage des géométries, on optimise un peu le regroupement des departements sinon c'est trop long (+1min)
	WITH departements_regroupes AS (
     SELECT 
        public.ST_Buffer(public.ST_Simplify(public.ST_Union(dep.geom), 100), 50) AS geom_regroupe
    FROM 
        (select departement.geom from departement UNION select departement_stb_stm.geom from departement_stb_stm) as dep
	)

	update hexa_signalement set geometry_intersect = public.ST_Intersection(geometry, geom_regroupe)
	from departements_regroupes;
end;
$$;


--
-- TOC entry 1859 (class 1255 OID 1658768)
-- Name: lunch_generate_tiles_couverture(); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.lunch_generate_tiles_couverture() RETURNS void
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	delete from tiles_cache_couverture;
	with oper as (
		SELECT distinct operateur from couverture_theorique
	),
	techno as (
		SELECT distinct techno from couverture_theorique
	)
	insert into tiles_cache_couverture(
		z, x, y, operateur, techno, mvt)
	select tile.z, tile.x, tile.y, oper.operateur,  techno.techno,
	generate_couvertures_tiles(tile.z, tile.x, tile.y, oper.operateur, techno.techno)
	from techno, oper, GetTilesIntersectingLayer(operateur, techno) as tile;
end;
$$;


--
-- TOC entry 1851 (class 1255 OID 1658769)
-- Name: lunch_generate_tiles_couverture_tbc(); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.lunch_generate_tiles_couverture_tbc() RETURNS void
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	delete from tiles_cache_couverture_tbc;
	
	with liste_techno as (
	select '2G3G' as techno
	UNION
	select '4G' as techno
	)
	insert into tiles_cache_couverture_tbc(
		z, x, y, techno, mvt)
	select tile.z, tile.x, tile.y, liste_techno.techno,
	generate_couvertures_tbc_tiles(tile.z, tile.x, tile.y, liste_techno.techno)
	from liste_techno, gettilesintersectinglayer_couverture_tbc(liste_techno.techno) as tile;
end;
$$;


--
-- TOC entry 1860 (class 1255 OID 1658770)
-- Name: lunch_generate_tiles_hexa(); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.lunch_generate_tiles_hexa() RETURNS void
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	--Suppression des données
	delete from hexa_30m;
	--injection du carroyage hexa
	insert into hexa_30m select * from generate_hexa_layer();
	--Association des hexa aux données
	UPDATE qos SET id_hexa = h.fid
	FROM hexa_30m as h WHERE public.ST_Intersects(qos.geometry, h.geometry);
	--Ajout du centroid
	update hexa_30m set geometry_centroid = public.ST_centroid(geometry);
end;
$$;


--
-- TOC entry 1861 (class 1255 OID 1658771)
-- Name: site_operateur(integer, integer, integer, integer[]); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.site_operateur(z integer, x integer, y integer, liste_operateur integer[]) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	query text;
	result bytea;
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
    return (
		WITH
		bounds AS (SELECT public.ST_TileEnvelope(z, x, y) AS geom),
		mvtgeom AS (
		  SELECT code_op, nom_op, num_site, id_station_anfr,
		    x, y, latitude, longitude, nom_reg, nom_dep,
		    insee_dep, nom_com, insee_com, site_2g, site_3g,
		    site_4g, site_5g, date_ouverturecommerciale_5g,
		    site_5g_700_m_hz, site_5g_800_m_hz, site_5g_1800_m_hz,
		    site_5g_2100_m_hz, site_5g_3500_m_hz, id_site_partage,
		    mes_4g_trim, site_zb, site_dcc, site_strategique,
		    site_capa_240mbps, annee_donnee, trimestre_donnee,
			public.ST_AsMVTGeom(t.geometry, bounds.geom) AS geom
		  FROM "site" t, bounds
		  WHERE public.ST_Intersects(t.geometry, bounds.geom )
		  	and code_op = any(liste_operateur)
		)
		SELECT public.ST_AsMVT(mvtgeom)
		FROM mvtgeom
	);
end;
$$;


--
-- TOC entry 1862 (class 1255 OID 1658772)
-- Name: supports_istechno(text[], text); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.supports_istechno(techonologies text[], params_techno text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$

DECLARE 
    istechnovalid boolean ;
begin
    SELECT params_techno = any(techonologies) as val INTO istechnovalid ; 
	return istechnovalid ;
end;
$$;


--
-- TOC entry 1863 (class 1255 OID 1658773)
-- Name: tbc_2g3g_gettilesintersectinglayer(); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.tbc_2g3g_gettilesintersectinglayer() RETURNS TABLE(x integer, y integer, z integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tile_bounds GEOMETRY;
	max_zoom INTEGER := 7;
	schema_function text;
BEGIN
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	FOR current_zoom IN 1..max_zoom LOOP
		FOR _x IN 0..(2 ^ current_zoom - 1)
		LOOP
			FOR _y IN 0..(2 ^ current_zoom - 1)
			LOOP
				tile_bounds := public.ST_TileEnvelope(current_zoom, _x, _y);
				IF EXISTS (
					SELECT 1 FROM couverture_theorique
					WHERE public.ST_Intersects(geom, tile_bounds)
					AND techno = '2G3G'
					AND niveau = 'TBC'
				)
				THEN
					RAISE NOTICE 'Computing %', current_zoom || ', ' || _x || ', ' || _y;
					z := current_zoom;
					x := _x;
					y := _y;
					RETURN NEXT;
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;
END;
$$;


--
-- TOC entry 1864 (class 1255 OID 1658774)
-- Name: tbc_2g3g_lunch_generate_tiles_couverture(); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.tbc_2g3g_lunch_generate_tiles_couverture() RETURNS void
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	delete from tbc_2g3g_tiles_cache;
	with oper as (
		SELECT distinct operateur from couverture_theorique
	)
	insert into tbc_2g3g_tiles_cache(
		z, x, y, operateur, mvt)
	select tile.z, tile.x, tile.y, oper.operateur, 
	tbc_2g3g_generate_couvertures_tiles(tile.z, tile.x, tile.y)
	from oper, tbc_2g3g_gettilesintersectinglayer() as tile;
end;
$$;


--
-- TOC entry 1865 (class 1255 OID 1658775)
-- Name: tbc_couvertures(integer, integer, integer); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.tbc_couvertures(z integer, x integer, y integer) RETURNS bytea
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE); 
	if (z <= 7 and array_length(liste_operateur,1) = 1) then
		return (
			SELECT operateur, mvt
			from tbc_2g3g_tiles_cache 
			Where tiles_cache.x=x 
				AND tiles_cache.y=y 
				AND tiles_cache.z=z 
		);
	else
		return (
			WITH
			bounds AS (
			  SELECT public.ST_TileEnvelope(z, x, y) AS geom,
			 (CASE 
				when z >= 12 then 0
				when z = 11 then 0
				when z = 10 then 10
				when z = 9 then 100
				when z = 8 then 300
				ELSE 1 END
			   ) as simplify_tolerance
			),

			mvtgeom AS (
			  SELECT operateur, 
				public.ST_AsMVTGeom(
					  public.ST_Simplify(t.geom,simplify_tolerance), bounds.geom) AS geom

			  FROM couverture_theorique t, bounds
			  WHERE public.ST_Intersects(t.geom, bounds.geom )
				and techno = '2G3G' 
                and niveau = 'TBC'
			)
			SELECT public.ST_AsMVT(mvtgeom)
			FROM mvtgeom
		);
	end if;
end;
$$;


--
-- TOC entry 1866 (class 1255 OID 1658776)
-- Name: test_schema(integer); Type: FUNCTION; Schema: mrm_public; Owner: -
--

CREATE FUNCTION mrm_public.test_schema(radius integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
	
DECLARE 
	schema_function text;
begin
	schema_function := public.parent_schema();
	PERFORM set_config('search_path', schema_function, TRUE);
	return schema_function;
end;
$$;


--
-- TOC entry 1662 (class 1255 OID 782813)
-- Name: qos(); Type: FUNCTION; Schema: postgisftw; Owner: -
--

CREATE FUNCTION postgisftw.qos() RETURNS TABLE(mcc_mnc bigint, situation text, strate text, protocole text, temps_en_secondes double precision, geom public.geometry)
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
begin
	RETURN QUERY
		SELECT mcc_mnc,
            situation,
            strate,
            protocole,
            temps_en_secondes,
            geom
    FROM mrm_last."QoS_Metropole_data_habitations";
end;
$$;


--
-- TOC entry 1663 (class 1255 OID 782814)
-- Name: qos_met(); Type: FUNCTION; Schema: postgisftw; Owner: -
--

CREATE FUNCTION postgisftw.qos_met() RETURNS TABLE(mcc_mnc bigint, situation text, strate text, protocole text, temps_en_secondes double precision, geom public.geometry)
    LANGUAGE plpgsql
    AS $$

#variable_conflict use_variable
begin
	RETURN QUERY
		SELECT mcc_mnc,
            situation,
            strate,
            protocole,
            temps_en_secondes,
            geometry as geom
    FROM mrm_last."QoS_Metropole_data_habitations";
end;
$$;


--
-- TOC entry 1664 (class 1255 OID 782815)
-- Name: dms2dd(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dms2dd(strdegminsec character varying) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
    DECLARE
       i               numeric;
       intDmsLen       numeric;          -- Length of original string
       strCompassPoint Char(1);
       strNorm         varchar(16) = ''; -- Will contain normalized string
       strDegMinSecB   varchar(100);
       blnGotSeparator integer;          -- Keeps track of separator sequences
       arrDegMinSec    varchar[];        -- TYPE stringarray is table of varchar(2048) ;
       dDeg            numeric := 0;
       dMin            numeric := 0;
       dSec            numeric := 0;
       strChr          Char(1);
    BEGIN
       -- Remove leading and trailing spaces
       strDegMinSecB := REPLACE(strDegMinSec,' ','');
       -- assume no leading and trailing spaces?
       intDmsLen := Length(strDegMinSecB);
 
       blnGotSeparator := 0; -- Not in separator sequence right now 
 
       -- Loop over string, replacing anything that is not a digit or a
       -- decimal separator with
       -- a single blank
       FOR i in 1..intDmsLen LOOP
          -- Get current character
          strChr := SubStr(strDegMinSecB, i, 1);
          -- either add character to normalized string or replace
          -- separator sequence with single blank         
          If strpos('0123456789,.', strChr) > 0 Then
             -- add character but replace comma with point
             If (strChr <> ',') Then
                strNorm := strNorm || strChr;
             Else
                strNorm := strNorm || '.';
             End If;
             blnGotSeparator := 0;
          ElsIf strpos('neswNESW',strChr) > 0 Then -- Extract Compass Point if present
            strCompassPoint := strChr;
          Else
             -- ensure only one separator is replaced with a blank -
             -- suppress the rest
             If blnGotSeparator = 0 Then
                strNorm := strNorm || ' ';
                blnGotSeparator := 0;
             End If;
          End If;
       End Loop;
 
       -- Split normalized string into array of max 3 components
       arrDegMinSec := string_to_array(strNorm, ' ');
 
       --convert specified components to double
       i := array_upper(arrDegMinSec,1);
       If i >= 1 Then
          dDeg := CAST(arrDegMinSec[1] AS numeric);
       End If;
       If i >= 2 Then
          dMin := CAST(arrDegMinSec[2] AS numeric);
       End If;
       If i >= 3 Then
          dSec := CAST(arrDegMinSec[3] AS numeric);
       End If;
 
       -- convert components to value
       return (CASE WHEN UPPER(strCompassPoint) IN ('S','W') 
                    THEN -1 
                    ELSE 1 
                END
               *
               (dDeg + dMin / 60 + dSec / 3600));
    End
$$;


--
-- TOC entry 1665 (class 1255 OID 782816)
-- Name: dms_to_dd(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dms_to_dd(degrees text, minutes text, seconds text, direction text) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
dd numeric;
BEGIN
dd := ABS(CAST(degrees AS numeric)) + 
(ABS(CAST(minutes AS numeric)) / 60) + 
(ABS(CAST(seconds AS numeric)) / 3600);

IF direction = 'S' OR direction = 'W' THEN
dd := dd * -1;
END IF;

RETURN dd;
END;
$$;


--
-- TOC entry 1666 (class 1255 OID 782817)
-- Name: gettilesintersectinglayer(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gettilesintersectinglayer() RETURNS TABLE(x integer, y integer, z integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tile_bounds GEOMETRY;
	max_zoom INTEGER := 7;
BEGIN
	FOR current_zoom IN 1..max_zoom LOOP
		FOR _x IN 0..(2 ^ current_zoom - 1)
		LOOP
			FOR _y IN 0..(2 ^ current_zoom - 1)
			LOOP
				tile_bounds := ST_TileEnvelope(current_zoom, _x, _y);
				IF EXISTS (
					SELECT 1 FROM mrm_last.couverture_theorique
					WHERE ST_Intersects(geom, tile_bounds)
				)
				THEN
					RAISE NOTICE 'Computing %', current_zoom || ', ' || _x || ', ' || _y;
					z := current_zoom;
					x := _x;
					y := _y;
					RETURN NEXT;
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;
END;
$$;


--
-- TOC entry 1667 (class 1255 OID 782818)
-- Name: gettilesintersectinglayer(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gettilesintersectinglayer(zoom_level integer) RETURNS TABLE(x integer, y integer, z integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tile_bounds GEOMETRY;
BEGIN
    FOR _x IN 0..(2 ^ zoom_level - 1)
    LOOP
        FOR _y IN 0..(2 ^ zoom_level - 1)
        LOOP
            tile_bounds := ST_TileEnvelope(zoom_level, _x, _y);
            IF EXISTS (
                SELECT 1 FROM mrm_last.couverture_theorique
                WHERE ST_Intersects(geom, tile_bounds)
            )
            THEN
				RAISE NOTICE 'Computing %', _x;
                z := zoom_level;
                x := _x;
                y := _y;
                RETURN NEXT;
            END IF;
        END LOOP;
    END LOOP;
END;
$$;


--
-- TOC entry 1668 (class 1255 OID 782819)
-- Name: gettilesintersectinglayer(integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gettilesintersectinglayer(zoom_level integer, nom_table text) RETURNS TABLE(x integer, y integer, z integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tile_bounds GEOMETRY;
BEGIN
    FOR x IN 0..(2 ^ zoom_level - 1)
    LOOP
        FOR y IN 0..(2 ^ zoom_level - 1)
        LOOP
            tile_bounds := ST_TileEnvelope(zoom_level, x, y);
            IF EXISTS (
                SELECT 1 FROM mrm_last.couverture_theorique
                WHERE ST_Intersects(geom, tile_bounds)
            )
            THEN
                z := zoom_level;
                RETURN NEXT;
            END IF;
        END LOOP;
    END LOOP;
END;
$$;


--
-- TOC entry 1671 (class 1255 OID 782820)
-- Name: gettilesintersectinglayer(bigint, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gettilesintersectinglayer(liste_operateur bigint, liste_techno character varying) RETURNS TABLE(x integer, y integer, z integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tile_bounds GEOMETRY;
	max_zoom INTEGER := 7;
BEGIN
	FOR current_zoom IN 1..max_zoom LOOP
		FOR _x IN 0..(2 ^ current_zoom - 1)
		LOOP
			FOR _y IN 0..(2 ^ current_zoom - 1)
			LOOP
				tile_bounds := ST_TileEnvelope(current_zoom, _x, _y);
				IF EXISTS (
					SELECT 1 FROM mrm_last.couverture_theorique
					WHERE ST_Intersects(geom, tile_bounds)
					AND operateur = liste_operateur
					AND techno = liste_techno
				)
				THEN
					RAISE NOTICE 'Computing %', current_zoom || ', ' || _x || ', ' || _y;
					z := current_zoom;
					x := _x;
					y := _y;
					RETURN NEXT;
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;
END;
$$;


--
-- TOC entry 1672 (class 1255 OID 782821)
-- Name: is_date(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_date(s character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
PERFORM s::DATE;
RETURN true;
EXCEPTION WHEN OTHERS THEN
RETURN false;
END;
$$;


--
-- TOC entry 1673 (class 1255 OID 782822)
-- Name: parent_schema(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.parent_schema() RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        stack text; 
        schema_name text;
    BEGIN
		GET DIAGNOSTICS stack = PG_CONTEXT;
		--On récupère le nom du schema à partir du context
		schema_name := substring(stack FROM '
PL/pgSQL function ([^.]+)');
--		  RAISE NOTICE E'--- schema_name ---\n%', schema_name;
		  RAISE NOTICE E'--- Call Stack ---\n%', stack;
		  --On récupère le nom du schema à partir du context
		--Si le schema n'existe pas => on est dans le bon schema
		if (SELECT EXISTS (
			SELECT 1 
			FROM pg_namespace 
			WHERE nspname = schema_name
		)) THEN
        	RETURN schema_name;
		ELSE
			RETURN CURRENT_SCHEMA;
		END IF;
    END;
$$;


--
-- TOC entry 740 (class 1259 OID 1736644)
-- Name: anfr_sup_antenne_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.anfr_sup_antenne_fid_seq
    START WITH 610519
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 741 (class 1259 OID 1736645)
-- Name: anfr_sup_antenne; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.anfr_sup_antenne (
    fid bigint DEFAULT nextval('mrm_private.anfr_sup_antenne_fid_seq'::regclass) NOT NULL,
    sta_nm_anfr text,
    aer_id bigint,
    tae_id bigint,
    aer_nb_dimension text,
    aer_fg_rayon text,
    aer_nb_azimut text,
    aer_nb_alt_bas text,
    sup_id bigint,
    filename text
);


--
-- TOC entry 742 (class 1259 OID 1736651)
-- Name: anfr_sup_bande_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.anfr_sup_bande_fid_seq
    START WITH 4196194
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 743 (class 1259 OID 1736652)
-- Name: anfr_sup_bande; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.anfr_sup_bande (
    fid bigint DEFAULT nextval('mrm_private.anfr_sup_bande_fid_seq'::regclass) NOT NULL,
    sta_nm_anfr text,
    ban_id bigint,
    emr_id bigint,
    ban_nb_f_deb text,
    ban_nb_f_fin text,
    ban_fg_unite text,
    filename text
);


--
-- TOC entry 744 (class 1259 OID 1736658)
-- Name: anfr_sup_emetteur_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.anfr_sup_emetteur_fid_seq
    START WITH 2155004
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 745 (class 1259 OID 1736659)
-- Name: anfr_sup_emetteur; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.anfr_sup_emetteur (
    fid bigint DEFAULT nextval('mrm_private.anfr_sup_emetteur_fid_seq'::regclass) NOT NULL,
    emr_id bigint,
    emr_lb_systeme text,
    sta_nm_anfr text,
    aer_id bigint,
    emr_dt_service text,
    filename text
);


--
-- TOC entry 746 (class 1259 OID 1736665)
-- Name: anfr_sup_nature_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.anfr_sup_nature_ogc_fid_seq
    START WITH 2155004
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 747 (class 1259 OID 1736666)
-- Name: anfr_sup_nature; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.anfr_sup_nature (
    ogc_fid integer DEFAULT nextval('mrm_private.anfr_sup_nature_ogc_fid_seq'::regclass) NOT NULL,
    nat_id integer,
    nat_lb_nom character varying,
    filename text
);


--
-- TOC entry 748 (class 1259 OID 1736672)
-- Name: anfr_sup_station_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.anfr_sup_station_fid_seq
    START WITH 180247
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 749 (class 1259 OID 1736673)
-- Name: anfr_sup_station; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.anfr_sup_station (
    fid bigint DEFAULT nextval('mrm_private.anfr_sup_station_fid_seq'::regclass) NOT NULL,
    sta_nm_anfr text,
    adm_id bigint,
    dem_nm_comsis bigint,
    dte_implantation text,
    dte_modif text,
    dte_en_service text,
    filename text
);


--
-- TOC entry 750 (class 1259 OID 1736679)
-- Name: anfr_sup_support_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.anfr_sup_support_fid_seq
    START WITH 181298
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 751 (class 1259 OID 1736680)
-- Name: anfr_sup_support; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.anfr_sup_support (
    fid bigint DEFAULT nextval('mrm_private.anfr_sup_support_fid_seq'::regclass) NOT NULL,
    sup_id bigint,
    sta_nm_anfr text,
    nat_id bigint,
    cor_nb_dg_lat bigint,
    cor_nb_mn_lat bigint,
    cor_nb_sc_lat bigint,
    cor_cd_ns_lat text,
    cor_nb_dg_lon bigint,
    cor_nb_mn_lon bigint,
    cor_nb_sc_lon bigint,
    cor_cd_ew_lon text,
    sup_nm_haut text,
    tpo_id double precision,
    adr_lb_lieu text,
    adr_lb_add1 text,
    adr_lb_add2 text,
    adr_lb_add3 text,
    adr_nm_cp bigint,
    com_cd_insee text,
    geom public.geometry(Point,3857),
    id_departement integer,
    filename text
);


--
-- TOC entry 752 (class 1259 OID 1736686)
-- Name: anfr_sup_support_log_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.anfr_sup_support_log_fid_seq
    START WITH 181294
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 753 (class 1259 OID 1736687)
-- Name: anfr_sup_support_log; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.anfr_sup_support_log (
    fid bigint DEFAULT nextval('mrm_private.anfr_sup_support_log_fid_seq'::regclass) NOT NULL,
    sup_id bigint,
    sta_nm_anfr text,
    nat_id bigint,
    cor_nb_dg_lat bigint,
    cor_nb_mn_lat bigint,
    cor_nb_sc_lat bigint,
    cor_cd_ns_lat text,
    cor_nb_dg_lon bigint,
    cor_nb_mn_lon bigint,
    cor_nb_sc_lon bigint,
    cor_cd_ew_lon text,
    sup_nm_haut text,
    tpo_id double precision,
    adr_lb_lieu text,
    adr_lb_add1 text,
    adr_lb_add2 text,
    adr_lb_add3 text,
    adr_nm_cp bigint,
    com_cd_insee text,
    geom public.geometry(Point,3857),
    id_departement integer,
    filename text
);


--
-- TOC entry 754 (class 1259 OID 1736693)
-- Name: commune; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.commune (
    gid integer NOT NULL,
    id character varying(24),
    nom character varying(50),
    nom_m character varying(50),
    insee_com character varying(5),
    statut character varying(26),
    population integer,
    insee_can character varying(5),
    insee_arr character varying(2),
    insee_dep character varying(3),
    insee_reg character varying(2),
    siren_epci character varying(20),
    geom public.geometry(MultiPolygon,3857)
);


--
-- TOC entry 755 (class 1259 OID 1736698)
-- Name: commune_gid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.commune_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7401 (class 0 OID 0)
-- Dependencies: 755
-- Name: commune_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.commune_gid_seq OWNED BY mrm_private.commune.gid;


--
-- TOC entry 756 (class 1259 OID 1736699)
-- Name: commune_light; Type: VIEW; Schema: mrm_private; Owner: -
--

CREATE VIEW mrm_private.commune_light AS
 SELECT commune.gid,
    commune.id,
    commune.nom,
    commune.nom_m,
    commune.insee_com,
    commune.statut,
    commune.population,
    commune.insee_can,
    commune.insee_arr,
    commune.insee_dep,
    commune.insee_reg,
    commune.siren_epci,
    (public.st_setsrid(public.st_envelope(commune.geom), 3857))::public.geometry(Polygon,3857) AS extent
   FROM mrm_private.commune;


--
-- TOC entry 757 (class 1259 OID 1736703)
-- Name: commune_stb_stm; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.commune_stb_stm (
    gid integer NOT NULL,
    id character varying(80),
    nom character varying(80),
    nom_m character varying(80),
    insee_com character varying(80),
    statut character varying(80),
    population numeric,
    insee_can character varying(80),
    insee_arr integer,
    insee_dep character varying(80),
    insee_reg character varying(80),
    siren_epci character varying(80),
    geom public.geometry(MultiPolygon,5490)
);


--
-- TOC entry 758 (class 1259 OID 1736708)
-- Name: commune_stb_stm_gid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.commune_stb_stm_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7402 (class 0 OID 0)
-- Dependencies: 758
-- Name: commune_stb_stm_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.commune_stb_stm_gid_seq OWNED BY mrm_private.commune_stb_stm.gid;


--
-- TOC entry 759 (class 1259 OID 1736709)
-- Name: couverture_theorique; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.couverture_theorique (
    fid integer NOT NULL,
    operateur bigint,
    operateur_commercial character varying,
    operateur_infra character varying,
    date character varying,
    techno character varying,
    usage character varying,
    niveau character varying,
    dept character varying,
    geom public.geometry(MultiPolygon,3857),
    filename text
);


--
-- TOC entry 760 (class 1259 OID 1736714)
-- Name: couverture_theorique_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.couverture_theorique_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7403 (class 0 OID 0)
-- Dependencies: 760
-- Name: couverture_theorique_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.couverture_theorique_fid_seq OWNED BY mrm_private.couverture_theorique.fid;


--
-- TOC entry 761 (class 1259 OID 1736715)
-- Name: data_date_description; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.data_date_description (
    id bigint NOT NULL,
    page character varying(50) NOT NULL,
    date_build_start date NOT NULL,
    date_build_end date,
    date_maj timestamp without time zone,
    territoire character varying(50) NOT NULL
);


--
-- TOC entry 762 (class 1259 OID 1736718)
-- Name: data_date_description_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.data_date_description_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7404 (class 0 OID 0)
-- Dependencies: 762
-- Name: data_date_description_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.data_date_description_id_seq OWNED BY mrm_private.data_date_description.id;


--
-- TOC entry 763 (class 1259 OID 1736719)
-- Name: departement; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.departement (
    gid integer NOT NULL,
    id character varying(24),
    nom_m character varying(30),
    nom character varying(30),
    insee_dep character varying(3),
    insee_reg character varying(2),
    geom public.geometry(MultiPolygon,3857)
);


--
-- TOC entry 764 (class 1259 OID 1736724)
-- Name: departement_gid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.departement_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7405 (class 0 OID 0)
-- Dependencies: 764
-- Name: departement_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.departement_gid_seq OWNED BY mrm_private.departement.gid;


--
-- TOC entry 765 (class 1259 OID 1736725)
-- Name: departement_light; Type: VIEW; Schema: mrm_private; Owner: -
--

CREATE VIEW mrm_private.departement_light AS
 SELECT departement.gid,
    departement.id,
    departement.nom_m,
    departement.nom,
    departement.insee_dep,
    departement.insee_reg,
    (public.st_setsrid(public.st_envelope(departement.geom), 3857))::public.geometry(Polygon,3857) AS extent
   FROM mrm_private.departement;


--
-- TOC entry 766 (class 1259 OID 1736729)
-- Name: departement_stb_stm; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.departement_stb_stm (
    gid integer NOT NULL,
    id character varying(80),
    nom_m character varying(80),
    nom character varying(80),
    insee_dep character varying(80),
    insee_reg character varying(80),
    geom public.geometry(MultiPolygon,5490)
);


--
-- TOC entry 767 (class 1259 OID 1736734)
-- Name: departement_stb_stm_gid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.departement_stb_stm_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7406 (class 0 OID 0)
-- Dependencies: 767
-- Name: departement_stb_stm_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.departement_stb_stm_gid_seq OWNED BY mrm_private.departement_stb_stm.gid;


--
-- TOC entry 768 (class 1259 OID 1736735)
-- Name: emetteurs_link_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.emetteurs_link_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 769 (class 1259 OID 1736736)
-- Name: emetteurs_link; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.emetteurs_link (
    id integer DEFAULT nextval('mrm_private.emetteurs_link_id_seq'::regclass) NOT NULL,
    emr_lb_systeme character varying,
    a_conserver boolean,
    affichage character varying,
    technologie character varying,
    filename text
);


--
-- TOC entry 770 (class 1259 OID 1736742)
-- Name: geography_columns; Type: VIEW; Schema: mrm_private; Owner: -
--

CREATE VIEW mrm_private.geography_columns AS
 SELECT current_database() AS f_table_catalog,
    n.nspname AS f_table_schema,
    c.relname AS f_table_name,
    a.attname AS f_geography_column,
    public.postgis_typmod_dims(a.atttypmod) AS coord_dimension,
    public.postgis_typmod_srid(a.atttypmod) AS srid,
    public.postgis_typmod_type(a.atttypmod) AS type
   FROM pg_class c,
    pg_attribute a,
    pg_type t,
    pg_namespace n
  WHERE ((t.typname = 'geography'::name) AND (a.attisdropped = false) AND (a.atttypid = t.oid) AND (a.attrelid = c.oid) AND (c.relnamespace = n.oid) AND (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));


--
-- TOC entry 771 (class 1259 OID 1736747)
-- Name: geometry_columns; Type: VIEW; Schema: mrm_private; Owner: -
--

CREATE VIEW mrm_private.geometry_columns AS
 SELECT (current_database())::character varying(256) AS f_table_catalog,
    n.nspname AS f_table_schema,
    c.relname AS f_table_name,
    a.attname AS f_geometry_column,
    COALESCE(public.postgis_typmod_dims(a.atttypmod), sn.ndims, 2) AS coord_dimension,
    COALESCE(NULLIF(public.postgis_typmod_srid(a.atttypmod), 0), sr.srid, 0) AS srid,
    (replace(replace(COALESCE(NULLIF(upper(public.postgis_typmod_type(a.atttypmod)), 'GEOMETRY'::text), st.type, 'GEOMETRY'::text), 'ZM'::text, ''::text), 'Z'::text, ''::text))::character varying(30) AS type
   FROM ((((((pg_class c
     JOIN pg_attribute a ON (((a.attrelid = c.oid) AND (NOT a.attisdropped))))
     JOIN pg_namespace n ON ((c.relnamespace = n.oid)))
     JOIN pg_type t ON ((a.atttypid = t.oid)))
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            replace(split_part(s.consrc, ''''::text, 2), ')'::text, ''::text) AS type
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE (s.consrc ~~* '%geometrytype(% = %'::text)) st ON (((st.connamespace = n.oid) AND (st.conrelid = c.oid) AND (a.attnum = ANY (st.conkey)))))
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            (replace(split_part(s.consrc, ' = '::text, 2), ')'::text, ''::text))::integer AS ndims
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE (s.consrc ~~* '%ndims(% = %'::text)) sn ON (((sn.connamespace = n.oid) AND (sn.conrelid = c.oid) AND (a.attnum = ANY (sn.conkey)))))
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            (replace(replace(split_part(s.consrc, ' = '::text, 2), ')'::text, ''::text), '('::text, ''::text))::integer AS srid
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE (s.consrc ~~* '%srid(% = %'::text)) sr ON (((sr.connamespace = n.oid) AND (sr.conrelid = c.oid) AND (a.attnum = ANY (sr.conkey)))))
  WHERE ((c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])) AND (NOT (c.relname = 'raster_columns'::name)) AND (t.typname = 'geometry'::name) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));


--
-- TOC entry 772 (class 1259 OID 1736752)
-- Name: hexa_30m; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.hexa_30m (
    fid integer NOT NULL,
    geometry public.geometry(Polygon,3857),
    geometry_centroid public.geometry(Point,3857)
);


--
-- TOC entry 773 (class 1259 OID 1736757)
-- Name: hexa_signalement; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.hexa_signalement (
    fid integer NOT NULL,
    geometry public.geometry(Polygon,3857),
    geometry_intersect public.geometry(Geometry,3857)
);


--
-- TOC entry 774 (class 1259 OID 1736762)
-- Name: import_log_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.import_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 775 (class 1259 OID 1736763)
-- Name: import_log; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.import_log (
    id integer DEFAULT nextval('mrm_private.import_log_id_seq'::regclass) NOT NULL,
    date timestamp without time zone,
    type character varying(100),
    success boolean NOT NULL,
    observation character varying(200)
);


--
-- TOC entry 776 (class 1259 OID 1736767)
-- Name: insee_density_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.insee_density_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 777 (class 1259 OID 1736768)
-- Name: insee_density; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.insee_density (
    id integer DEFAULT nextval('mrm_private.insee_density_id_seq'::regclass) NOT NULL,
    codegeo character varying,
    dens integer,
    libdens character varying,
    touristic_zones integer,
    filename text
);


--
-- TOC entry 778 (class 1259 OID 1736774)
-- Name: l_commune_arrondissement; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.l_commune_arrondissement (
    ogc_fid integer NOT NULL,
    typecom character varying,
    com character varying,
    reg character varying,
    dep character varying,
    ctcd character varying,
    arr character varying,
    tncc character varying,
    ncc character varying,
    nccenr character varying,
    libelle character varying,
    can character varying,
    comparent character varying
);


--
-- TOC entry 779 (class 1259 OID 1736779)
-- Name: l_commune_arrondissement_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.l_commune_arrondissement_ogc_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7407 (class 0 OID 0)
-- Dependencies: 779
-- Name: l_commune_arrondissement_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.l_commune_arrondissement_ogc_fid_seq OWNED BY mrm_private.l_commune_arrondissement.ogc_fid;


--
-- TOC entry 780 (class 1259 OID 1736780)
-- Name: operateurs; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.operateurs (
    identifiant integer NOT NULL,
    nom_entier character varying(255) NOT NULL,
    nom_affichage character varying(255) NOT NULL,
    logo character varying(255),
    couleur_defaut character varying(25) NOT NULL,
    couleur_niveau_1 character varying(25) NOT NULL,
    couleur_niveau_2 character varying(25) NOT NULL,
    couleur_niveau_3 character varying(25) NOT NULL,
    couleur_niveau_4 character varying(25) NOT NULL,
    perimetre_metro boolean NOT NULL,
    perimetre_971 boolean NOT NULL,
    perimetre_972 boolean NOT NULL,
    perimetre_973 boolean NOT NULL,
    perimetre_974 boolean NOT NULL,
    perimetre_976 boolean NOT NULL,
    perimetre_977 boolean NOT NULL,
    perimetre_978 boolean NOT NULL,
    icon_antenne character varying(25),
    code character varying(255),
    opt_couleur_defaut character varying(25),
    opt_couleur_niveau_1 character varying(25),
    opt_couleur_niveau_2 character varying(25),
    opt_couleur_niveau_3 character varying(25),
    opt_couleur_niveau_4 character varying(25),
    map_couleur_defaut character varying(25),
    map_couleur_niveau_1 character varying(25),
    map_couleur_niveau_2 character varying(25),
    map_couleur_niveau_3 character varying(25),
    map_couleur_niveau_4 character varying(25),
    map_opt_couleur_defaut character varying(25),
    map_opt_couleur_niveau_1 character varying(25),
    map_opt_couleur_niveau_2 character varying(25),
    map_opt_couleur_niveau_3 character varying(25),
    map_opt_couleur_niveau_4 character varying(25)
);


--
-- TOC entry 781 (class 1259 OID 1736785)
-- Name: parameters; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.parameters (
    id integer NOT NULL,
    key_word character varying(50) NOT NULL,
    label_value character varying(100) NOT NULL,
    link_value text
);


--
-- TOC entry 782 (class 1259 OID 1736790)
-- Name: parameters_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7408 (class 0 OID 0)
-- Dependencies: 782
-- Name: parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.parameters_id_seq OWNED BY mrm_private.parameters.id;


--
-- TOC entry 783 (class 1259 OID 1736791)
-- Name: qos; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.qos (
    fid bigint NOT NULL,
    "1440p_pourcentage" numeric,
    "144p_pourcentage" numeric,
    "180p_pourcentage" numeric,
    "2160p_pourcentage" numeric,
    "240p_pourcentage" numeric,
    "360p_higher_pourcentage" numeric,
    "360p_pourcentage" numeric,
    "4320p_pourcentage" numeric,
    "480p_pourcentage" numeric,
    "720p_higher_pourcentage" numeric,
    "720p_pourcentage" numeric,
    acess_duration numeric,
    average_mos_couple numeric,
    axis character varying(100),
    axis_name character varying(255),
    axis_precision character varying(255),
    band_serving integer,
    band_start integer,
    bitrate_dl numeric,
    bitrate_ul numeric,
    call_direction character varying(255),
    call_number integer,
    call_setup_time_to_alerting numeric,
    call_type character varying(255),
    cell_id integer,
    crspa boolean,
    date_end date,
    date_start date,
    date_time_end timestamp without time zone,
    date_time_start timestamp without time zone,
    descoping boolean,
    descoping_reason character varying(255),
    detail text,
    dialed_number integer,
    dl_superior_3mbps boolean,
    dl_volume numeric,
    download_ok boolean,
    ec_n0 numeric,
    helicopter_measure boolean,
    hour_end time without time zone,
    hour_start time without time zone,
    id_measure integer,
    id_sending_terminal bigint,
    imei bigint,
    imsi bigint,
    insee_com character varying(5),
    insee_dep character varying(3),
    intra_inter_op_couple text,
    lac integer,
    latitude_end numeric,
    latitude_start numeric,
    list_mos numeric[],
    loaded_in_less_10_secondes boolean,
    loaded_in_less_5_secondes boolean,
    longitude_end numeric,
    longitude_start numeric,
    mcc_end integer,
    mcc_start integer,
    min_mos numeric,
    min_mos_couple numeric,
    mnc_end integer,
    mnc_start integer,
    mos_average numeric,
    nom_com character varying(255),
    nom_dep character varying(255),
    nom_reg character varying(255),
    operator character varying(255),
    mcc_mnc integer,
    quality_correct boolean,
    quality_perfect boolean,
    real_communiation_time numeric,
    reason_of_failed text,
    result text,
    rscp numeric,
    rsrp numeric,
    rsrq numeric,
    rx_lev integer,
    rx_level numeric,
    rx_qual integer,
    protocole character varying(20),
    situation character varying(20),
    sms_content text,
    sms_delai numeric,
    sms_reception_date_time timestamp without time zone,
    sms_sending_date_time timestamp without time zone,
    sms_sending_number character varying(255),
    sms_success boolean,
    tac integer,
    techno_end character varying(25),
    techno_start character varying(25),
    terminal character varying(150),
    territory character varying(20),
    time_to_call numeric,
    trace_name character varying(255),
    traffic_time numeric,
    transfert_duration numeric,
    transfert_file_size numeric,
    ul_volume numeric,
    upload_ok boolean,
    url text,
    video_freez_duration numeric,
    video_initialisation_duration numeric,
    video_viewing_duration numeric,
    zone character varying(255),
    zone_name character varying(255),
    zone_precision character varying(255),
    id_hexa integer,
    id_data_source_desc integer,
    geometry public.geometry(Point,3857),
    filename text,
    is_metropole boolean,
    is_transport boolean,
    operator_called character varying(255),
    operator_calling character varying(255),
    operator_identical character varying(5),
    operating_system character varying(255),
    operating_system_version character varying(255),
    pci text,
    ping_result boolean,
    axis_name_search character varying
);


--
-- TOC entry 784 (class 1259 OID 1736796)
-- Name: qos_categorie_transport; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.qos_categorie_transport (
    id bigint NOT NULL,
    axis character varying(100),
    axis_name character varying(255),
    minx numeric,
    miny numeric,
    maxx numeric,
    maxy numeric,
    axis_name_search character varying(255)
);


--
-- TOC entry 785 (class 1259 OID 1736801)
-- Name: qos_categorie_transport_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.qos_categorie_transport_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7409 (class 0 OID 0)
-- Dependencies: 785
-- Name: qos_categorie_transport_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.qos_categorie_transport_id_seq OWNED BY mrm_private.qos_categorie_transport.id;


--
-- TOC entry 786 (class 1259 OID 1736802)
-- Name: qos_data_source_desc; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.qos_data_source_desc (
    id integer NOT NULL,
    id_data_source integer NOT NULL,
    title text
);


--
-- TOC entry 787 (class 1259 OID 1736807)
-- Name: qos_data_source_desc_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.qos_data_source_desc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7410 (class 0 OID 0)
-- Dependencies: 787
-- Name: qos_data_source_desc_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.qos_data_source_desc_id_seq OWNED BY mrm_private.qos_data_source_desc.id;


--
-- TOC entry 788 (class 1259 OID 1736808)
-- Name: qos_data_source_list_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.qos_data_source_list_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 789 (class 1259 OID 1736809)
-- Name: qos_data_source_list; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.qos_data_source_list (
    id integer DEFAULT nextval('mrm_private.qos_data_source_list_id_seq'::regclass) NOT NULL,
    title character varying(255),
    source character varying(20)
);


--
-- TOC entry 790 (class 1259 OID 1736813)
-- Name: qos_density_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.qos_density_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 791 (class 1259 OID 1736814)
-- Name: qos_density; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.qos_density (
    id integer DEFAULT nextval('mrm_private.qos_density_id_seq'::regclass) NOT NULL,
    protocole character varying,
    zone character varying,
    mcc_mnc character varying,
    label character varying,
    result character varying,
    filename text
);


--
-- TOC entry 792 (class 1259 OID 1736820)
-- Name: qos_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.qos_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7411 (class 0 OID 0)
-- Dependencies: 792
-- Name: qos_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.qos_fid_seq OWNED BY mrm_private.qos.fid;


--
-- TOC entry 793 (class 1259 OID 1736821)
-- Name: qos_stat_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.qos_stat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 794 (class 1259 OID 1736822)
-- Name: qos_stat; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.qos_stat (
    id integer DEFAULT nextval('mrm_private.qos_stat_id_seq'::regclass) NOT NULL,
    nom_region character varying,
    insee_dep character varying(3),
    service character varying(20),
    zone character varying(20),
    situation character varying(20),
    mccmnc character varying,
    resultat numeric,
    nb_test numeric,
    filename text
);


--
-- TOC entry 795 (class 1259 OID 1736828)
-- Name: qos_test; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.qos_test (
    fid integer NOT NULL,
    "1440p_pourcentage" numeric,
    "144p_pourcentage" numeric,
    "180p_pourcentage" numeric,
    "2160p_pourcentage" numeric,
    "240p_pourcentage" numeric,
    "360p_higher_pourcentage" numeric,
    "360p_pourcentage" numeric,
    "4320p_pourcentage" numeric,
    "480p_pourcentage" numeric,
    "720p_higher_pourcentage" numeric,
    "720p_pourcentage" numeric,
    acess_duration numeric,
    average_mos_couple numeric,
    axis character varying(100),
    axis_name character varying(255),
    axis_precision character varying(255),
    band_serving integer,
    band_start integer,
    bitrate_dl numeric,
    bitrate_ul numeric,
    call_direction character varying(255),
    call_number integer,
    call_setup_time_to_alerting numeric,
    call_type character varying(255),
    cell_id integer,
    crspa boolean,
    date_end date,
    date_start date,
    date_time_end timestamp without time zone,
    date_time_start timestamp without time zone,
    descoping boolean,
    descoping_reason character varying(255),
    detail text,
    dialed_number integer,
    dl_superior_3mbps boolean,
    dl_volume numeric,
    download_ok boolean,
    ec_n0 numeric,
    helicopter_measure boolean,
    hour_end time without time zone,
    hour_start time without time zone,
    id_measure integer,
    id_sending_terminal bigint,
    imei bigint,
    imsi bigint,
    insee_com character varying(5),
    insee_dep character varying(3),
    intra_inter_op_couple text,
    lac integer,
    latitude_end numeric,
    latitude_start numeric,
    list_mos numeric[],
    loaded_in_less_10_secondes boolean,
    loaded_in_less_5_secondes boolean,
    longitude_end numeric,
    longitude_start numeric,
    mcc_end integer,
    mcc_start integer,
    min_mos numeric,
    min_mos_couple numeric,
    mnc_end integer,
    mnc_start integer,
    mos_average numeric,
    nom_com character varying(255),
    nom_dep character varying(255),
    nom_reg character varying(255),
    operator character varying(255),
    mcc_mnc integer,
    quality_correct boolean,
    quality_perfect boolean,
    real_communiation_time numeric,
    reason_of_failed text,
    result text,
    rscp numeric,
    rsrp numeric,
    rsrq numeric,
    rx_lev integer,
    rx_level numeric,
    rx_qual integer,
    protocole character varying(20),
    situation character varying(20),
    sms_content text,
    sms_delai numeric,
    sms_reception_date_time timestamp without time zone,
    sms_sending_date_time timestamp without time zone,
    sms_sending_number character varying(255),
    sms_success boolean,
    tac integer,
    techno_end character varying(25),
    techno_start character varying(25),
    terminal character varying(150),
    territory character varying(20),
    time_to_call numeric,
    trace_name character varying(255),
    traffic_time numeric,
    transfert_duration numeric,
    transfert_file_size numeric,
    ul_volume numeric,
    upload_ok boolean,
    url text,
    video_freez_duration numeric,
    video_initialisation_duration numeric,
    video_viewing_duration numeric,
    zone character varying(255),
    zone_name character varying(255),
    zone_precision character varying(255),
    id_hexa integer,
    id_data_source_desc integer,
    geometry public.geometry(Point,3857),
    filename text,
    is_metropole boolean,
    is_transport boolean,
    operator_called character varying(255),
    operator_calling character varying(255),
    operator_identical character varying(5),
    operating_system character varying(255),
    operating_system_version character varying(255),
    pci text,
    ping_result boolean,
    axis_name_search character varying
);


--
-- TOC entry 796 (class 1259 OID 1736833)
-- Name: qos_test_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.qos_test_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7412 (class 0 OID 0)
-- Dependencies: 796
-- Name: qos_test_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.qos_test_fid_seq OWNED BY mrm_private.qos_test.fid;


--
-- TOC entry 797 (class 1259 OID 1736834)
-- Name: region; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.region (
    gid integer NOT NULL,
    id character varying(24),
    nom_m character varying(35),
    nom character varying(35),
    insee_reg character varying(2),
    geom public.geometry(MultiPolygon,3857)
);


--
-- TOC entry 798 (class 1259 OID 1736839)
-- Name: region_gid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.region_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7413 (class 0 OID 0)
-- Dependencies: 798
-- Name: region_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.region_gid_seq OWNED BY mrm_private.region.gid;


--
-- TOC entry 799 (class 1259 OID 1736840)
-- Name: region_light; Type: VIEW; Schema: mrm_private; Owner: -
--

CREATE VIEW mrm_private.region_light AS
 SELECT region.gid,
    region.id,
    region.nom_m,
    region.nom,
    region.insee_reg,
    (public.st_setsrid(public.st_envelope(region.geom), 3857))::public.geometry(Polygon,3857) AS extent
   FROM mrm_private.region;


--
-- TOC entry 800 (class 1259 OID 1736844)
-- Name: region_stb_stm; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.region_stb_stm (
    gid integer NOT NULL,
    id character varying(80),
    nom_m character varying(80),
    nom character varying(80),
    insee_reg character varying(80),
    geom public.geometry(MultiPolygon,5490)
);


--
-- TOC entry 801 (class 1259 OID 1736849)
-- Name: region_stb_stm_gid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.region_stb_stm_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7414 (class 0 OID 0)
-- Dependencies: 801
-- Name: region_stb_stm_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.region_stb_stm_gid_seq OWNED BY mrm_private.region_stb_stm.gid;


--
-- TOC entry 802 (class 1259 OID 1736850)
-- Name: seq_site_a_venir_fid; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.seq_site_a_venir_fid
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 803 (class 1259 OID 1736851)
-- Name: site; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.site (
    fid bigint NOT NULL,
    code_op bigint,
    nom_op text,
    num_site text,
    id_station_anfr text,
    x double precision,
    y double precision,
    latitude double precision,
    longitude double precision,
    nom_reg text,
    nom_dep text,
    insee_dep text,
    nom_com text,
    insee_com text,
    site_2g boolean,
    site_3g boolean,
    site_4g boolean,
    site_5g boolean,
    date_ouverturecommerciale_5g text,
    site_5g_700_m_hz boolean,
    site_5g_800_m_hz boolean,
    site_5g_1800_m_hz boolean,
    site_5g_2100_m_hz boolean,
    site_5g_3500_m_hz boolean,
    id_site_partage text,
    mes_4g_trim boolean,
    site_zb boolean,
    site_dcc boolean,
    site_strategique boolean,
    site_capa_240mbps boolean,
    annee_donnee text,
    trimestre_donnee text,
    geometry public.geometry(Point,3857),
    sup_id bigint,
    filename text
);


--
-- TOC entry 804 (class 1259 OID 1736856)
-- Name: seq_site_fid; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.seq_site_fid
    START WITH 107135
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 7415 (class 0 OID 0)
-- Dependencies: 804
-- Name: seq_site_fid; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.seq_site_fid OWNED BY mrm_private.site.fid;


--
-- TOC entry 805 (class 1259 OID 1736857)
-- Name: signalement_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.signalement_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 806 (class 1259 OID 1736858)
-- Name: signalement; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.signalement (
    fid integer DEFAULT nextval('mrm_private.signalement_seq'::regclass) NOT NULL,
    id integer,
    date date,
    insee_com character varying(5),
    operateur integer,
    latitude numeric,
    longitude numeric,
    id_hexa integer,
    geometry public.geometry(Point,3857),
    filename text,
    is_metropole boolean
);


--
-- TOC entry 807 (class 1259 OID 1736864)
-- Name: signalement_test_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.signalement_test_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 808 (class 1259 OID 1736865)
-- Name: site_a_venir; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.site_a_venir (
    fid bigint DEFAULT nextval('mrm_private.seq_site_a_venir_fid'::regclass) NOT NULL,
    code_op bigint,
    nom_op text,
    num_site text,
    id_station_anfr text,
    x double precision,
    y double precision,
    latitude double precision,
    longitude double precision,
    nom_reg text,
    nom_dep text,
    insee_dep text,
    nom_com text,
    insee_com text,
    site_2g boolean,
    site_3g boolean,
    site_4g boolean,
    site_5g boolean,
    date_ouverturecommerciale_5g text,
    site_5g_700_m_hz boolean,
    site_5g_800_m_hz boolean,
    site_5g_1800_m_hz boolean,
    site_5g_2100_m_hz boolean,
    site_5g_3500_m_hz boolean,
    id_site_partage text,
    mes_4g_trim boolean,
    site_zb boolean,
    site_dcc boolean,
    site_strategique boolean,
    site_capa_240mbps boolean,
    annee_donnee text,
    trimestre_donnee text,
    geometry public.geometry(Point,3857),
    sup_id bigint,
    filename text
);


--
-- TOC entry 809 (class 1259 OID 1736871)
-- Name: site_log; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.site_log (
    fid bigint NOT NULL,
    code_op bigint,
    nom_op text,
    num_site text,
    id_station_anfr text,
    x double precision,
    y double precision,
    latitude double precision,
    longitude double precision,
    nom_reg text,
    nom_dep text,
    insee_dep text,
    nom_com text,
    insee_com text,
    site_2g boolean,
    site_3g boolean,
    site_4g boolean,
    site_5g boolean,
    date_ouverturecommerciale_5g text,
    site_5g_700_m_hz boolean,
    site_5g_800_m_hz boolean,
    site_5g_1800_m_hz boolean,
    site_5g_2100_m_hz boolean,
    site_5g_3500_m_hz boolean,
    id_site_partage text,
    mes_4g_trim boolean,
    site_zb boolean,
    site_dcc boolean,
    site_strategique boolean,
    site_capa_240mbps boolean,
    annee_donnee text,
    trimestre_donnee text,
    geometry public.geometry(Point,3857),
    sup_id bigint
);


--
-- TOC entry 810 (class 1259 OID 1736876)
-- Name: site_state; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.site_state (
    id bigint NOT NULL,
    operateur character varying(255),
    departement character varying(4),
    code_postal character varying(20),
    code_insee character varying(5),
    commune character varying(255),
    station_anfr text,
    voix2g character varying(20),
    voix3g character varying(20),
    voix4g character varying(20),
    data3g character varying(20),
    data4g character varying(20),
    data5g character varying(20),
    voix character varying(20),
    data character varying(20),
    propre integer,
    raison character varying(255),
    detail text,
    debut_voix timestamp with time zone,
    fin_voix timestamp with time zone,
    debut_data timestamp with time zone,
    fin_data timestamp with time zone,
    debut timestamp with time zone,
    fin timestamp with time zone,
    geomlong numeric,
    geomlat numeric,
    geometry public.geometry(Point,3857)
);


--
-- TOC entry 811 (class 1259 OID 1736881)
-- Name: site_state_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.site_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7416 (class 0 OID 0)
-- Dependencies: 811
-- Name: site_state_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.site_state_id_seq OWNED BY mrm_private.site_state.id;


--
-- TOC entry 812 (class 1259 OID 1736882)
-- Name: stat_site_commune; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stat_site_commune (
    id bigint NOT NULL,
    insee_com character varying(5) NOT NULL,
    total_site integer,
    code_op bigint,
    "2g3g4g" integer,
    "5g" integer,
    "5g_autres" integer
);


--
-- TOC entry 813 (class 1259 OID 1736885)
-- Name: stat_site_communes_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stat_site_communes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7417 (class 0 OID 0)
-- Dependencies: 813
-- Name: stat_site_communes_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.stat_site_communes_id_seq OWNED BY mrm_private.stat_site_commune.id;


--
-- TOC entry 814 (class 1259 OID 1736886)
-- Name: stat_site_departement; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stat_site_departement (
    id bigint NOT NULL,
    insee_dep character varying(5) NOT NULL,
    total_site integer,
    code_op bigint,
    "2g3g4g" integer,
    "5g" integer,
    "5g_autres" integer
);


--
-- TOC entry 815 (class 1259 OID 1736889)
-- Name: stat_site_departement_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stat_site_departement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7418 (class 0 OID 0)
-- Dependencies: 815
-- Name: stat_site_departement_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.stat_site_departement_id_seq OWNED BY mrm_private.stat_site_departement.id;


--
-- TOC entry 816 (class 1259 OID 1736890)
-- Name: stat_site_region; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stat_site_region (
    id bigint NOT NULL,
    insee_reg character varying(5) NOT NULL,
    total_site integer,
    code_op bigint,
    "2g3g4g" integer,
    "5g" integer,
    "5g_autres" integer
);


--
-- TOC entry 817 (class 1259 OID 1736893)
-- Name: stat_site_region_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stat_site_region_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7419 (class 0 OID 0)
-- Dependencies: 817
-- Name: stat_site_region_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.stat_site_region_id_seq OWNED BY mrm_private.stat_site_region.id;


--
-- TOC entry 818 (class 1259 OID 1736894)
-- Name: stat_site_territoire; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stat_site_territoire (
    id bigint NOT NULL,
    insee_territoire character varying(5) NOT NULL,
    total_site integer,
    code_op bigint,
    "2g3g4g" integer,
    "5g" integer,
    "5g_autres" integer
);


--
-- TOC entry 819 (class 1259 OID 1736897)
-- Name: stat_site_territoire_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stat_site_territoire_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7420 (class 0 OID 0)
-- Dependencies: 819
-- Name: stat_site_territoire_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.stat_site_territoire_id_seq OWNED BY mrm_private.stat_site_territoire.id;


--
-- TOC entry 820 (class 1259 OID 1736898)
-- Name: stats_couv_communes; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stats_couv_communes (
    fid integer NOT NULL,
    techno character varying,
    commune character varying,
    couv_nc numeric,
    couv_cl numeric,
    couv_bc numeric,
    couv_tbc numeric,
    pop_nc numeric,
    pop_cl numeric,
    pop_bc numeric,
    pop_tbc numeric,
    filename text,
    mcc_mnc bigint
);


--
-- TOC entry 821 (class 1259 OID 1736903)
-- Name: stats_couv_communes_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stats_couv_communes_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7421 (class 0 OID 0)
-- Dependencies: 821
-- Name: stats_couv_communes_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.stats_couv_communes_fid_seq OWNED BY mrm_private.stats_couv_communes.fid;


--
-- TOC entry 822 (class 1259 OID 1736904)
-- Name: stats_couv_departements; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stats_couv_departements (
    fid integer NOT NULL,
    techno character varying,
    departement character varying,
    couv_nc numeric,
    couv_cl numeric,
    couv_bc numeric,
    couv_tbc numeric,
    pop_nc numeric,
    pop_cl numeric,
    pop_bc numeric,
    pop_tbc numeric,
    filename text,
    mcc_mnc integer
);


--
-- TOC entry 823 (class 1259 OID 1736909)
-- Name: stats_couv_departements_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stats_couv_departements_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7422 (class 0 OID 0)
-- Dependencies: 823
-- Name: stats_couv_departements_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.stats_couv_departements_fid_seq OWNED BY mrm_private.stats_couv_departements.fid;


--
-- TOC entry 824 (class 1259 OID 1736910)
-- Name: stats_couv_regions; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stats_couv_regions (
    fid integer NOT NULL,
    techno character varying,
    region character varying,
    couv_nc numeric,
    couv_cl numeric,
    couv_bc numeric,
    couv_tbc numeric,
    pop_nc numeric,
    pop_cl numeric,
    pop_bc numeric,
    pop_tbc numeric,
    filename text,
    mcc_mnc integer
);


--
-- TOC entry 825 (class 1259 OID 1736915)
-- Name: stats_couv_regions_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stats_couv_regions_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7423 (class 0 OID 0)
-- Dependencies: 825
-- Name: stats_couv_regions_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.stats_couv_regions_fid_seq OWNED BY mrm_private.stats_couv_regions.fid;


--
-- TOC entry 826 (class 1259 OID 1736916)
-- Name: stats_couv_territoires; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stats_couv_territoires (
    fid integer NOT NULL,
    techno character varying,
    territoire character varying,
    couv_nc numeric,
    couv_cl numeric,
    couv_bc numeric,
    couv_tbc numeric,
    pop_nc numeric,
    pop_cl numeric,
    pop_bc numeric,
    pop_tbc numeric,
    filename text,
    mcc_mnc integer
);


--
-- TOC entry 827 (class 1259 OID 1736921)
-- Name: stats_couv_territoires_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stats_couv_territoires_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7424 (class 0 OID 0)
-- Dependencies: 827
-- Name: stats_couv_territoires_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.stats_couv_territoires_fid_seq OWNED BY mrm_private.stats_couv_territoires.fid;


--
-- TOC entry 828 (class 1259 OID 1736922)
-- Name: stats_nbope_couverture_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stats_nbope_couverture_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 829 (class 1259 OID 1736923)
-- Name: stats_nbope_couverture; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stats_nbope_couverture (
    id integer DEFAULT nextval('mrm_private.stats_nbope_couverture_id_seq'::regclass) NOT NULL,
    techno text,
    niveau text,
    code character varying,
    pop_0 double precision,
    pop_1 double precision,
    pop_2 double precision,
    pop_3 double precision,
    pop_4 double precision,
    pop_5 double precision,
    couv_0 double precision,
    couv_1 double precision,
    couv_2 double precision,
    couv_3 double precision,
    couv_4 double precision,
    couv_5 double precision,
    filename text,
    type text
);


--
-- TOC entry 830 (class 1259 OID 1736929)
-- Name: stats_nbope_couverture_met; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stats_nbope_couverture_met (
    ogc_fid integer NOT NULL,
    techno character varying,
    niveau character varying,
    commune character varying,
    pop_0 character varying,
    pop_1 character varying,
    pop_2 character varying,
    pop_3 character varying,
    pop_4 character varying,
    pop_5 character varying,
    couv_0 character varying,
    couv_1 character varying,
    couv_2 character varying,
    couv_3 character varying,
    couv_4 character varying,
    couv_5 character varying
);


--
-- TOC entry 831 (class 1259 OID 1736934)
-- Name: stats_nbope_couverture_met_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stats_nbope_couverture_met_ogc_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7425 (class 0 OID 0)
-- Dependencies: 831
-- Name: stats_nbope_couverture_met_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.stats_nbope_couverture_met_ogc_fid_seq OWNED BY mrm_private.stats_nbope_couverture_met.ogc_fid;


--
-- TOC entry 832 (class 1259 OID 1736935)
-- Name: stats_qos_departements_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stats_qos_departements_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 833 (class 1259 OID 1736936)
-- Name: stats_qos_departements; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stats_qos_departements (
    id integer DEFAULT nextval('mrm_private.stats_qos_departements_fid_seq'::regclass),
    nom_region character varying,
    insee_dep character varying,
    protocole character varying,
    zone character varying,
    situation character varying,
    mcc_mnc integer,
    resultat numeric,
    nb_test numeric,
    filename text
);


--
-- TOC entry 834 (class 1259 OID 1736942)
-- Name: stats_test_met; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.stats_test_met (
    ogc_fid integer NOT NULL,
    techno character varying,
    niveau character varying,
    code character varying,
    pop_0 character varying,
    pop_1 character varying,
    pop_2 character varying,
    pop_3 character varying,
    pop_4 character varying,
    pop_5 character varying,
    couv_0 character varying,
    couv_1 character varying,
    couv_2 character varying,
    couv_3 character varying,
    couv_4 character varying,
    couv_5 character varying
);


--
-- TOC entry 835 (class 1259 OID 1736947)
-- Name: stats_test_met_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.stats_test_met_ogc_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7426 (class 0 OID 0)
-- Dependencies: 835
-- Name: stats_test_met_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.stats_test_met_ogc_fid_seq OWNED BY mrm_private.stats_test_met.ogc_fid;


--
-- TOC entry 836 (class 1259 OID 1736948)
-- Name: tbc_2g3g_tiles_cache; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.tbc_2g3g_tiles_cache (
    z integer NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    operateur bigint NOT NULL,
    mvt bytea NOT NULL
);


--
-- TOC entry 837 (class 1259 OID 1736953)
-- Name: tiles_cache; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.tiles_cache (
    z integer NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    operateur bigint NOT NULL,
    techno character varying NOT NULL,
    mvt bytea NOT NULL
);


--
-- TOC entry 838 (class 1259 OID 1736958)
-- Name: tiles_cache_couverture; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.tiles_cache_couverture (
    z integer NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    operateur bigint NOT NULL,
    techno character varying NOT NULL,
    mvt bytea NOT NULL
);


--
-- TOC entry 839 (class 1259 OID 1736963)
-- Name: tiles_cache_couverture_tbc; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.tiles_cache_couverture_tbc (
    z integer NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    techno character varying NOT NULL,
    mvt bytea NOT NULL
);


--
-- TOC entry 840 (class 1259 OID 1736968)
-- Name: zac_axe_ferre_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.zac_axe_ferre_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 841 (class 1259 OID 1736969)
-- Name: zac_axe_ferre; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.zac_axe_ferre (
    ogc_fid integer DEFAULT nextval('mrm_private.zac_axe_ferre_ogc_fid_seq'::regclass) NOT NULL,
    id bigint,
    geometry public.geometry(MultiLineString,3857),
    filename text
);


--
-- TOC entry 842 (class 1259 OID 1736975)
-- Name: zac_axe_ferre_old; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.zac_axe_ferre_old (
    fid integer NOT NULL,
    objectid numeric(10,0),
    nom_dep character varying(30),
    insee_dep character varying(3),
    insee_reg character varying(2),
    shape_leng numeric(19,11),
    geometry public.geometry(MultiLineStringZ,3857),
    filename text
);


--
-- TOC entry 843 (class 1259 OID 1736980)
-- Name: zac_axe_ferre_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.zac_axe_ferre_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7427 (class 0 OID 0)
-- Dependencies: 843
-- Name: zac_axe_ferre_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.zac_axe_ferre_fid_seq OWNED BY mrm_private.zac_axe_ferre_old.fid;


--
-- TOC entry 844 (class 1259 OID 1736981)
-- Name: zac_axe_routier_prioritaire_5g_old; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.zac_axe_routier_prioritaire_5g_old (
    fid integer NOT NULL,
    id_rte500 numeric(6,0),
    vocation character varying(18),
    nb_chausse character varying(12),
    nb_voies character varying(27),
    etat character varying(10),
    acces character varying(10),
    res_vert character varying(16),
    sens character varying(12),
    res_europe character varying(20),
    num_route character varying(10),
    class_adm character varying(15),
    longueur numeric(6,2),
    long_axe numeric(10,0),
    geometry public.geometry(MultiLineStringZ,3857),
    filename text
);


--
-- TOC entry 845 (class 1259 OID 1736986)
-- Name: zac_axe_routier_principale_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.zac_axe_routier_principale_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7428 (class 0 OID 0)
-- Dependencies: 845
-- Name: zac_axe_routier_principale_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.zac_axe_routier_principale_fid_seq OWNED BY mrm_private.zac_axe_routier_prioritaire_5g_old.fid;


--
-- TOC entry 846 (class 1259 OID 1736987)
-- Name: zac_axe_routier_prioritaire_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.zac_axe_routier_prioritaire_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 847 (class 1259 OID 1736988)
-- Name: zac_axe_routier_prioritaire; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.zac_axe_routier_prioritaire (
    ogc_fid integer DEFAULT nextval('mrm_private.zac_axe_routier_prioritaire_ogc_fid_seq'::regclass) NOT NULL,
    id bigint,
    geometry public.geometry(MultiLineString,3857),
    filename text
);


--
-- TOC entry 848 (class 1259 OID 1736994)
-- Name: zac_axe_routier_prioritaire_5g_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.zac_axe_routier_prioritaire_5g_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 849 (class 1259 OID 1736995)
-- Name: zac_axe_routier_prioritaire_5g; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.zac_axe_routier_prioritaire_5g (
    ogc_fid integer DEFAULT nextval('mrm_private.zac_axe_routier_prioritaire_5g_ogc_fid_seq'::regclass) NOT NULL,
    id bigint,
    geometry public.geometry(MultiLineString,3857),
    filename text
);


--
-- TOC entry 850 (class 1259 OID 1737001)
-- Name: zac_axe_routier_prioritaire_old; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.zac_axe_routier_prioritaire_old (
    fid integer NOT NULL,
    code_dpt character varying,
    classe character varying,
    nom_route character varying,
    idarp integer,
    long double precision,
    geometry public.geometry(MultiLineStringZ,3857),
    filename text
);


--
-- TOC entry 851 (class 1259 OID 1737006)
-- Name: zac_axe_routier_prioritaire_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.zac_axe_routier_prioritaire_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7429 (class 0 OID 0)
-- Dependencies: 851
-- Name: zac_axe_routier_prioritaire_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.zac_axe_routier_prioritaire_fid_seq OWNED BY mrm_private.zac_axe_routier_prioritaire_old.fid;


--
-- TOC entry 852 (class 1259 OID 1737007)
-- Name: zac_poi_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.zac_poi_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 853 (class 1259 OID 1737008)
-- Name: zac_poi; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.zac_poi (
    id integer DEFAULT nextval('mrm_private.zac_poi_id_seq'::regclass) NOT NULL,
    id_point bigint,
    num_arrete character varying,
    date_publication_arrete text,
    id_dossier integer,
    nom_dossier character varying,
    nb_sites_dossier integer,
    code_insee character varying,
    nom_commune character varying,
    departement character varying,
    insee_dep character varying,
    region character varying,
    x_lambert_93 numeric,
    y_lambert_93 numeric,
    origine_zone character varying,
    origine_coordonnees character varying,
    num_zone_arrete character varying,
    nom_point_arrete character varying,
    identifiant_site character varying,
    lien_arrete character varying,
    geom public.geometry(Point,3857),
    filename text
);


--
-- TOC entry 854 (class 1259 OID 1737014)
-- Name: zac_poi_operateurs; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.zac_poi_operateurs (
    fid bigint NOT NULL,
    id_point bigint NOT NULL,
    id_operateur integer NOT NULL,
    filename text
);


--
-- TOC entry 855 (class 1259 OID 1737019)
-- Name: zac_poi_operateurs_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.zac_poi_operateurs_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7430 (class 0 OID 0)
-- Dependencies: 855
-- Name: zac_poi_operateurs_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_private; Owner: -
--

ALTER SEQUENCE mrm_private.zac_poi_operateurs_fid_seq OWNED BY mrm_private.zac_poi_operateurs.fid;


--
-- TOC entry 856 (class 1259 OID 1737020)
-- Name: zac_site_id_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.zac_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 857 (class 1259 OID 1737021)
-- Name: zac_site; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.zac_site (
    id integer DEFAULT nextval('mrm_private.zac_site_id_seq'::regclass) NOT NULL,
    num_arrete character varying,
    date_publication_arrete text,
    numero_site integer,
    nom_site_operateurs character varying,
    site_physique integer,
    numero_site_physique integer,
    nom_site_arrete character varying,
    id_dossier integer,
    nom_de_la_zone character varying,
    region character varying,
    departement character varying,
    insee_dep character varying,
    x_lambert_93 numeric,
    y_lambert_93 numeric,
    op_leader bigint,
    sites_demandes integer,
    sites_mes integer,
    sites_6_mois integer,
    sites_6_24_mois integer,
    sites_attente_deploiement integer,
    origine_zone character varying,
    num_zone_arrete character varying,
    geom public.geometry(Point,3857),
    filename text
);


--
-- TOC entry 858 (class 1259 OID 1737027)
-- Name: zac_site_operateurs_fid_seq; Type: SEQUENCE; Schema: mrm_private; Owner: -
--

CREATE SEQUENCE mrm_private.zac_site_operateurs_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 859 (class 1259 OID 1737028)
-- Name: zac_site_operateurs; Type: TABLE; Schema: mrm_private; Owner: -
--

CREATE TABLE mrm_private.zac_site_operateurs (
    fid bigint DEFAULT nextval('mrm_private.zac_site_operateurs_fid_seq'::regclass) NOT NULL,
    numero_site bigint NOT NULL,
    id_operateur integer NOT NULL,
    filename text
);


--
-- TOC entry 620 (class 1259 OID 1658777)
-- Name: anfr_sup_antenne_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.anfr_sup_antenne_fid_seq
    START WITH 610519
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 621 (class 1259 OID 1658778)
-- Name: anfr_sup_antenne; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.anfr_sup_antenne (
    fid bigint DEFAULT nextval('mrm_public.anfr_sup_antenne_fid_seq'::regclass) NOT NULL,
    sta_nm_anfr text,
    aer_id bigint,
    tae_id bigint,
    aer_nb_dimension text,
    aer_fg_rayon text,
    aer_nb_azimut text,
    aer_nb_alt_bas text,
    sup_id bigint,
    filename text
);


--
-- TOC entry 622 (class 1259 OID 1658784)
-- Name: anfr_sup_bande_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.anfr_sup_bande_fid_seq
    START WITH 4196194
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 623 (class 1259 OID 1658785)
-- Name: anfr_sup_bande; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.anfr_sup_bande (
    fid bigint DEFAULT nextval('mrm_public.anfr_sup_bande_fid_seq'::regclass) NOT NULL,
    sta_nm_anfr text,
    ban_id bigint,
    emr_id bigint,
    ban_nb_f_deb text,
    ban_nb_f_fin text,
    ban_fg_unite text,
    filename text
);


--
-- TOC entry 624 (class 1259 OID 1658791)
-- Name: anfr_sup_emetteur_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.anfr_sup_emetteur_fid_seq
    START WITH 2155004
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 625 (class 1259 OID 1658792)
-- Name: anfr_sup_emetteur; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.anfr_sup_emetteur (
    fid bigint DEFAULT nextval('mrm_public.anfr_sup_emetteur_fid_seq'::regclass) NOT NULL,
    emr_id bigint,
    emr_lb_systeme text,
    sta_nm_anfr text,
    aer_id bigint,
    emr_dt_service text,
    filename text
);


--
-- TOC entry 626 (class 1259 OID 1658798)
-- Name: anfr_sup_nature_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.anfr_sup_nature_ogc_fid_seq
    START WITH 2155004
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 627 (class 1259 OID 1658799)
-- Name: anfr_sup_nature; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.anfr_sup_nature (
    ogc_fid integer DEFAULT nextval('mrm_public.anfr_sup_nature_ogc_fid_seq'::regclass) NOT NULL,
    nat_id integer,
    nat_lb_nom character varying,
    filename text
);


--
-- TOC entry 628 (class 1259 OID 1658805)
-- Name: anfr_sup_station_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.anfr_sup_station_fid_seq
    START WITH 180247
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 629 (class 1259 OID 1658806)
-- Name: anfr_sup_station; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.anfr_sup_station (
    fid bigint DEFAULT nextval('mrm_public.anfr_sup_station_fid_seq'::regclass) NOT NULL,
    sta_nm_anfr text,
    adm_id bigint,
    dem_nm_comsis bigint,
    dte_implantation text,
    dte_modif text,
    dte_en_service text,
    filename text
);


--
-- TOC entry 630 (class 1259 OID 1658812)
-- Name: anfr_sup_support_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.anfr_sup_support_fid_seq
    START WITH 181298
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 631 (class 1259 OID 1658813)
-- Name: anfr_sup_support; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.anfr_sup_support (
    fid bigint DEFAULT nextval('mrm_public.anfr_sup_support_fid_seq'::regclass) NOT NULL,
    sup_id bigint,
    sta_nm_anfr text,
    nat_id bigint,
    cor_nb_dg_lat bigint,
    cor_nb_mn_lat bigint,
    cor_nb_sc_lat bigint,
    cor_cd_ns_lat text,
    cor_nb_dg_lon bigint,
    cor_nb_mn_lon bigint,
    cor_nb_sc_lon bigint,
    cor_cd_ew_lon text,
    sup_nm_haut text,
    tpo_id double precision,
    adr_lb_lieu text,
    adr_lb_add1 text,
    adr_lb_add2 text,
    adr_lb_add3 text,
    adr_nm_cp bigint,
    com_cd_insee text,
    geom public.geometry(Point,3857),
    id_departement integer,
    filename text
);


--
-- TOC entry 632 (class 1259 OID 1658819)
-- Name: anfr_sup_support_log_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.anfr_sup_support_log_fid_seq
    START WITH 181294
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 633 (class 1259 OID 1658820)
-- Name: anfr_sup_support_log; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.anfr_sup_support_log (
    fid bigint DEFAULT nextval('mrm_public.anfr_sup_support_log_fid_seq'::regclass) NOT NULL,
    sup_id bigint,
    sta_nm_anfr text,
    nat_id bigint,
    cor_nb_dg_lat bigint,
    cor_nb_mn_lat bigint,
    cor_nb_sc_lat bigint,
    cor_cd_ns_lat text,
    cor_nb_dg_lon bigint,
    cor_nb_mn_lon bigint,
    cor_nb_sc_lon bigint,
    cor_cd_ew_lon text,
    sup_nm_haut text,
    tpo_id double precision,
    adr_lb_lieu text,
    adr_lb_add1 text,
    adr_lb_add2 text,
    adr_lb_add3 text,
    adr_nm_cp bigint,
    com_cd_insee text,
    geom public.geometry(Point,3857),
    id_departement integer,
    filename text
);


--
-- TOC entry 634 (class 1259 OID 1658826)
-- Name: commune; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.commune (
    gid integer NOT NULL,
    id character varying(24),
    nom character varying(50),
    nom_m character varying(50),
    insee_com character varying(5),
    statut character varying(26),
    population integer,
    insee_can character varying(5),
    insee_arr character varying(2),
    insee_dep character varying(3),
    insee_reg character varying(2),
    siren_epci character varying(20),
    geom public.geometry(MultiPolygon,3857)
);


--
-- TOC entry 635 (class 1259 OID 1658831)
-- Name: commune_gid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.commune_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7461 (class 0 OID 0)
-- Dependencies: 635
-- Name: commune_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.commune_gid_seq OWNED BY mrm_public.commune.gid;


--
-- TOC entry 636 (class 1259 OID 1658832)
-- Name: commune_light; Type: VIEW; Schema: mrm_public; Owner: -
--

CREATE VIEW mrm_public.commune_light AS
 SELECT commune.gid,
    commune.id,
    commune.nom,
    commune.nom_m,
    commune.insee_com,
    commune.statut,
    commune.population,
    commune.insee_can,
    commune.insee_arr,
    commune.insee_dep,
    commune.insee_reg,
    commune.siren_epci,
    (public.st_setsrid(public.st_envelope(commune.geom), 3857))::public.geometry(Polygon,3857) AS extent
   FROM mrm_public.commune;


--
-- TOC entry 637 (class 1259 OID 1658836)
-- Name: commune_stb_stm; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.commune_stb_stm (
    gid integer NOT NULL,
    id character varying(80),
    nom character varying(80),
    nom_m character varying(80),
    insee_com character varying(80),
    statut character varying(80),
    population numeric,
    insee_can character varying(80),
    insee_arr integer,
    insee_dep character varying(80),
    insee_reg character varying(80),
    siren_epci character varying(80),
    geom public.geometry(MultiPolygon,5490)
);


--
-- TOC entry 638 (class 1259 OID 1658841)
-- Name: commune_stb_stm_gid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.commune_stb_stm_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7462 (class 0 OID 0)
-- Dependencies: 638
-- Name: commune_stb_stm_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.commune_stb_stm_gid_seq OWNED BY mrm_public.commune_stb_stm.gid;


--
-- TOC entry 639 (class 1259 OID 1658842)
-- Name: couverture_theorique; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.couverture_theorique (
    fid integer NOT NULL,
    operateur bigint,
    operateur_commercial character varying,
    operateur_infra character varying,
    date character varying,
    techno character varying,
    usage character varying,
    niveau character varying,
    dept character varying,
    geom public.geometry(MultiPolygon,3857),
    filename text
);


--
-- TOC entry 640 (class 1259 OID 1658847)
-- Name: couverture_theorique_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.couverture_theorique_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7463 (class 0 OID 0)
-- Dependencies: 640
-- Name: couverture_theorique_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.couverture_theorique_fid_seq OWNED BY mrm_public.couverture_theorique.fid;


--
-- TOC entry 641 (class 1259 OID 1658848)
-- Name: data_date_description; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.data_date_description (
    id bigint NOT NULL,
    page character varying(50) NOT NULL,
    date_build_start date NOT NULL,
    date_build_end date,
    date_maj timestamp without time zone,
    territoire character varying(50) NOT NULL
);


--
-- TOC entry 642 (class 1259 OID 1658851)
-- Name: data_date_description_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.data_date_description_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7464 (class 0 OID 0)
-- Dependencies: 642
-- Name: data_date_description_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.data_date_description_id_seq OWNED BY mrm_public.data_date_description.id;


--
-- TOC entry 643 (class 1259 OID 1658852)
-- Name: departement; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.departement (
    gid integer NOT NULL,
    id character varying(24),
    nom_m character varying(30),
    nom character varying(30),
    insee_dep character varying(3),
    insee_reg character varying(2),
    geom public.geometry(MultiPolygon,3857)
);


--
-- TOC entry 644 (class 1259 OID 1658857)
-- Name: departement_gid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.departement_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7465 (class 0 OID 0)
-- Dependencies: 644
-- Name: departement_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.departement_gid_seq OWNED BY mrm_public.departement.gid;


--
-- TOC entry 645 (class 1259 OID 1658858)
-- Name: departement_light; Type: VIEW; Schema: mrm_public; Owner: -
--

CREATE VIEW mrm_public.departement_light AS
 SELECT departement.gid,
    departement.id,
    departement.nom_m,
    departement.nom,
    departement.insee_dep,
    departement.insee_reg,
    (public.st_setsrid(public.st_envelope(departement.geom), 3857))::public.geometry(Polygon,3857) AS extent
   FROM mrm_public.departement;


--
-- TOC entry 646 (class 1259 OID 1658862)
-- Name: departement_stb_stm; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.departement_stb_stm (
    gid integer NOT NULL,
    id character varying(80),
    nom_m character varying(80),
    nom character varying(80),
    insee_dep character varying(80),
    insee_reg character varying(80),
    geom public.geometry(MultiPolygon,5490)
);


--
-- TOC entry 647 (class 1259 OID 1658867)
-- Name: departement_stb_stm_gid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.departement_stb_stm_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7466 (class 0 OID 0)
-- Dependencies: 647
-- Name: departement_stb_stm_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.departement_stb_stm_gid_seq OWNED BY mrm_public.departement_stb_stm.gid;


--
-- TOC entry 648 (class 1259 OID 1658868)
-- Name: emetteurs_link_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.emetteurs_link_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 649 (class 1259 OID 1658869)
-- Name: emetteurs_link; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.emetteurs_link (
    id integer DEFAULT nextval('mrm_public.emetteurs_link_id_seq'::regclass) NOT NULL,
    emr_lb_systeme character varying,
    a_conserver boolean,
    affichage character varying,
    technologie character varying,
    filename text
);


--
-- TOC entry 650 (class 1259 OID 1658875)
-- Name: geography_columns; Type: VIEW; Schema: mrm_public; Owner: -
--

CREATE VIEW mrm_public.geography_columns AS
 SELECT current_database() AS f_table_catalog,
    n.nspname AS f_table_schema,
    c.relname AS f_table_name,
    a.attname AS f_geography_column,
    public.postgis_typmod_dims(a.atttypmod) AS coord_dimension,
    public.postgis_typmod_srid(a.atttypmod) AS srid,
    public.postgis_typmod_type(a.atttypmod) AS type
   FROM pg_class c,
    pg_attribute a,
    pg_type t,
    pg_namespace n
  WHERE ((t.typname = 'geography'::name) AND (a.attisdropped = false) AND (a.atttypid = t.oid) AND (a.attrelid = c.oid) AND (c.relnamespace = n.oid) AND (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));


--
-- TOC entry 651 (class 1259 OID 1658880)
-- Name: geometry_columns; Type: VIEW; Schema: mrm_public; Owner: -
--

CREATE VIEW mrm_public.geometry_columns AS
 SELECT (current_database())::character varying(256) AS f_table_catalog,
    n.nspname AS f_table_schema,
    c.relname AS f_table_name,
    a.attname AS f_geometry_column,
    COALESCE(public.postgis_typmod_dims(a.atttypmod), sn.ndims, 2) AS coord_dimension,
    COALESCE(NULLIF(public.postgis_typmod_srid(a.atttypmod), 0), sr.srid, 0) AS srid,
    (replace(replace(COALESCE(NULLIF(upper(public.postgis_typmod_type(a.atttypmod)), 'GEOMETRY'::text), st.type, 'GEOMETRY'::text), 'ZM'::text, ''::text), 'Z'::text, ''::text))::character varying(30) AS type
   FROM ((((((pg_class c
     JOIN pg_attribute a ON (((a.attrelid = c.oid) AND (NOT a.attisdropped))))
     JOIN pg_namespace n ON ((c.relnamespace = n.oid)))
     JOIN pg_type t ON ((a.atttypid = t.oid)))
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            replace(split_part(s.consrc, ''''::text, 2), ')'::text, ''::text) AS type
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE (s.consrc ~~* '%geometrytype(% = %'::text)) st ON (((st.connamespace = n.oid) AND (st.conrelid = c.oid) AND (a.attnum = ANY (st.conkey)))))
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            (replace(split_part(s.consrc, ' = '::text, 2), ')'::text, ''::text))::integer AS ndims
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE (s.consrc ~~* '%ndims(% = %'::text)) sn ON (((sn.connamespace = n.oid) AND (sn.conrelid = c.oid) AND (a.attnum = ANY (sn.conkey)))))
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            (replace(replace(split_part(s.consrc, ' = '::text, 2), ')'::text, ''::text), '('::text, ''::text))::integer AS srid
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE (s.consrc ~~* '%srid(% = %'::text)) sr ON (((sr.connamespace = n.oid) AND (sr.conrelid = c.oid) AND (a.attnum = ANY (sr.conkey)))))
  WHERE ((c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])) AND (NOT (c.relname = 'raster_columns'::name)) AND (t.typname = 'geometry'::name) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));


--
-- TOC entry 652 (class 1259 OID 1658885)
-- Name: hexa_30m; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.hexa_30m (
    fid integer NOT NULL,
    geometry public.geometry(Polygon,3857),
    geometry_centroid public.geometry(Point,3857)
);


--
-- TOC entry 653 (class 1259 OID 1658890)
-- Name: hexa_signalement; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.hexa_signalement (
    fid integer NOT NULL,
    geometry public.geometry(Polygon,3857),
    geometry_intersect public.geometry(Geometry,3857)
);


--
-- TOC entry 654 (class 1259 OID 1658895)
-- Name: import_log_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.import_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 655 (class 1259 OID 1658896)
-- Name: import_log; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.import_log (
    id integer DEFAULT nextval('mrm_public.import_log_id_seq'::regclass) NOT NULL,
    date timestamp without time zone,
    type character varying(100),
    success boolean NOT NULL,
    observation character varying(200)
);


--
-- TOC entry 656 (class 1259 OID 1658900)
-- Name: insee_density_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.insee_density_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 657 (class 1259 OID 1658901)
-- Name: insee_density; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.insee_density (
    id integer DEFAULT nextval('mrm_public.insee_density_id_seq'::regclass) NOT NULL,
    codegeo character varying,
    dens integer,
    libdens character varying,
    touristic_zones integer,
    filename text
);


--
-- TOC entry 658 (class 1259 OID 1658907)
-- Name: l_commune_arrondissement; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.l_commune_arrondissement (
    ogc_fid integer NOT NULL,
    typecom character varying,
    com character varying,
    reg character varying,
    dep character varying,
    ctcd character varying,
    arr character varying,
    tncc character varying,
    ncc character varying,
    nccenr character varying,
    libelle character varying,
    can character varying,
    comparent character varying
);


--
-- TOC entry 659 (class 1259 OID 1658912)
-- Name: l_commune_arrondissement_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.l_commune_arrondissement_ogc_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7467 (class 0 OID 0)
-- Dependencies: 659
-- Name: l_commune_arrondissement_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.l_commune_arrondissement_ogc_fid_seq OWNED BY mrm_public.l_commune_arrondissement.ogc_fid;


--
-- TOC entry 660 (class 1259 OID 1658913)
-- Name: operateurs; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.operateurs (
    identifiant integer NOT NULL,
    nom_entier character varying(255) NOT NULL,
    nom_affichage character varying(255) NOT NULL,
    logo character varying(255),
    couleur_defaut character varying(25) NOT NULL,
    couleur_niveau_1 character varying(25) NOT NULL,
    couleur_niveau_2 character varying(25) NOT NULL,
    couleur_niveau_3 character varying(25) NOT NULL,
    couleur_niveau_4 character varying(25) NOT NULL,
    perimetre_metro boolean NOT NULL,
    perimetre_971 boolean NOT NULL,
    perimetre_972 boolean NOT NULL,
    perimetre_973 boolean NOT NULL,
    perimetre_974 boolean NOT NULL,
    perimetre_976 boolean NOT NULL,
    perimetre_977 boolean NOT NULL,
    perimetre_978 boolean NOT NULL,
    icon_antenne character varying(25),
    code character varying(255),
    opt_couleur_defaut character varying(25),
    opt_couleur_niveau_1 character varying(25),
    opt_couleur_niveau_2 character varying(25),
    opt_couleur_niveau_3 character varying(25),
    opt_couleur_niveau_4 character varying(25),
    map_couleur_defaut character varying(25),
    map_couleur_niveau_1 character varying(25),
    map_couleur_niveau_2 character varying(25),
    map_couleur_niveau_3 character varying(25),
    map_couleur_niveau_4 character varying(25),
    map_opt_couleur_defaut character varying(25),
    map_opt_couleur_niveau_1 character varying(25),
    map_opt_couleur_niveau_2 character varying(25),
    map_opt_couleur_niveau_3 character varying(25),
    map_opt_couleur_niveau_4 character varying(25)
);


--
-- TOC entry 661 (class 1259 OID 1658918)
-- Name: parameters; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.parameters (
    id integer NOT NULL,
    key_word character varying(50) NOT NULL,
    label_value character varying(100) NOT NULL,
    link_value text
);


--
-- TOC entry 662 (class 1259 OID 1658923)
-- Name: parameters_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7468 (class 0 OID 0)
-- Dependencies: 662
-- Name: parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.parameters_id_seq OWNED BY mrm_public.parameters.id;


--
-- TOC entry 663 (class 1259 OID 1658924)
-- Name: qos; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.qos (
    fid bigint NOT NULL,
    "1440p_pourcentage" numeric,
    "144p_pourcentage" numeric,
    "180p_pourcentage" numeric,
    "2160p_pourcentage" numeric,
    "240p_pourcentage" numeric,
    "360p_higher_pourcentage" numeric,
    "360p_pourcentage" numeric,
    "4320p_pourcentage" numeric,
    "480p_pourcentage" numeric,
    "720p_higher_pourcentage" numeric,
    "720p_pourcentage" numeric,
    acess_duration numeric,
    average_mos_couple numeric,
    axis character varying(100),
    axis_name character varying(255),
    axis_precision character varying(255),
    band_serving integer,
    band_start integer,
    bitrate_dl numeric,
    bitrate_ul numeric,
    call_direction character varying(255),
    call_number integer,
    call_setup_time_to_alerting numeric,
    call_type character varying(255),
    cell_id integer,
    crspa boolean,
    date_end date,
    date_start date,
    date_time_end timestamp without time zone,
    date_time_start timestamp without time zone,
    descoping boolean,
    descoping_reason character varying(255),
    detail text,
    dialed_number integer,
    dl_superior_3mbps boolean,
    dl_volume numeric,
    download_ok boolean,
    ec_n0 numeric,
    helicopter_measure boolean,
    hour_end time without time zone,
    hour_start time without time zone,
    id_measure integer,
    id_sending_terminal bigint,
    imei bigint,
    imsi bigint,
    insee_com character varying(5),
    insee_dep character varying(3),
    intra_inter_op_couple text,
    lac integer,
    latitude_end numeric,
    latitude_start numeric,
    list_mos numeric[],
    loaded_in_less_10_secondes boolean,
    loaded_in_less_5_secondes boolean,
    longitude_end numeric,
    longitude_start numeric,
    mcc_end integer,
    mcc_start integer,
    min_mos numeric,
    min_mos_couple numeric,
    mnc_end integer,
    mnc_start integer,
    mos_average numeric,
    nom_com character varying(255),
    nom_dep character varying(255),
    nom_reg character varying(255),
    operator character varying(255),
    mcc_mnc integer,
    quality_correct boolean,
    quality_perfect boolean,
    real_communiation_time numeric,
    reason_of_failed text,
    result text,
    rscp numeric,
    rsrp numeric,
    rsrq numeric,
    rx_lev integer,
    rx_level numeric,
    rx_qual integer,
    protocole character varying(20),
    situation character varying(20),
    sms_content text,
    sms_delai numeric,
    sms_reception_date_time timestamp without time zone,
    sms_sending_date_time timestamp without time zone,
    sms_sending_number character varying(255),
    sms_success boolean,
    tac integer,
    techno_end character varying(25),
    techno_start character varying(25),
    terminal character varying(150),
    territory character varying(20),
    time_to_call numeric,
    trace_name character varying(255),
    traffic_time numeric,
    transfert_duration numeric,
    transfert_file_size numeric,
    ul_volume numeric,
    upload_ok boolean,
    url text,
    video_freez_duration numeric,
    video_initialisation_duration numeric,
    video_viewing_duration numeric,
    zone character varying(255),
    zone_name character varying(255),
    zone_precision character varying(255),
    id_hexa integer,
    id_data_source_desc integer,
    geometry public.geometry(Point,3857),
    filename text,
    is_metropole boolean,
    is_transport boolean,
    operator_called character varying(255),
    operator_calling character varying(255),
    operator_identical character varying(5),
    operating_system character varying(255),
    operating_system_version character varying(255),
    pci text,
    ping_result boolean,
    axis_name_search character varying
);


--
-- TOC entry 664 (class 1259 OID 1658929)
-- Name: qos_categorie_transport; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.qos_categorie_transport (
    id bigint NOT NULL,
    axis character varying(100),
    axis_name character varying(255),
    minx numeric,
    miny numeric,
    maxx numeric,
    maxy numeric,
    axis_name_search character varying(255)
);


--
-- TOC entry 665 (class 1259 OID 1658934)
-- Name: qos_categorie_transport_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.qos_categorie_transport_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7469 (class 0 OID 0)
-- Dependencies: 665
-- Name: qos_categorie_transport_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.qos_categorie_transport_id_seq OWNED BY mrm_public.qos_categorie_transport.id;


--
-- TOC entry 666 (class 1259 OID 1658935)
-- Name: qos_data_source_desc; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.qos_data_source_desc (
    id integer NOT NULL,
    id_data_source integer NOT NULL,
    title text
);


--
-- TOC entry 667 (class 1259 OID 1658940)
-- Name: qos_data_source_desc_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.qos_data_source_desc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7470 (class 0 OID 0)
-- Dependencies: 667
-- Name: qos_data_source_desc_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.qos_data_source_desc_id_seq OWNED BY mrm_public.qos_data_source_desc.id;


--
-- TOC entry 668 (class 1259 OID 1658941)
-- Name: qos_data_source_list_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.qos_data_source_list_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 669 (class 1259 OID 1658942)
-- Name: qos_data_source_list; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.qos_data_source_list (
    id integer DEFAULT nextval('mrm_public.qos_data_source_list_id_seq'::regclass) NOT NULL,
    title character varying(255),
    source character varying(20)
);


--
-- TOC entry 670 (class 1259 OID 1658946)
-- Name: qos_density_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.qos_density_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 671 (class 1259 OID 1658947)
-- Name: qos_density; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.qos_density (
    id integer DEFAULT nextval('mrm_public.qos_density_id_seq'::regclass) NOT NULL,
    protocole character varying,
    zone character varying,
    mcc_mnc character varying,
    label character varying,
    result character varying,
    filename text
);


--
-- TOC entry 672 (class 1259 OID 1658953)
-- Name: qos_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.qos_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7471 (class 0 OID 0)
-- Dependencies: 672
-- Name: qos_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.qos_fid_seq OWNED BY mrm_public.qos.fid;


--
-- TOC entry 673 (class 1259 OID 1658954)
-- Name: qos_stat_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.qos_stat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 674 (class 1259 OID 1658955)
-- Name: qos_stat; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.qos_stat (
    id integer DEFAULT nextval('mrm_public.qos_stat_id_seq'::regclass) NOT NULL,
    nom_region character varying,
    insee_dep character varying(3),
    service character varying(20),
    zone character varying(20),
    situation character varying(20),
    mccmnc character varying,
    resultat numeric,
    nb_test numeric,
    filename text
);


--
-- TOC entry 675 (class 1259 OID 1658961)
-- Name: qos_test; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.qos_test (
    fid integer NOT NULL,
    "1440p_pourcentage" numeric,
    "144p_pourcentage" numeric,
    "180p_pourcentage" numeric,
    "2160p_pourcentage" numeric,
    "240p_pourcentage" numeric,
    "360p_higher_pourcentage" numeric,
    "360p_pourcentage" numeric,
    "4320p_pourcentage" numeric,
    "480p_pourcentage" numeric,
    "720p_higher_pourcentage" numeric,
    "720p_pourcentage" numeric,
    acess_duration numeric,
    average_mos_couple numeric,
    axis character varying(100),
    axis_name character varying(255),
    axis_precision character varying(255),
    band_serving integer,
    band_start integer,
    bitrate_dl numeric,
    bitrate_ul numeric,
    call_direction character varying(255),
    call_number integer,
    call_setup_time_to_alerting numeric,
    call_type character varying(255),
    cell_id integer,
    crspa boolean,
    date_end date,
    date_start date,
    date_time_end timestamp without time zone,
    date_time_start timestamp without time zone,
    descoping boolean,
    descoping_reason character varying(255),
    detail text,
    dialed_number integer,
    dl_superior_3mbps boolean,
    dl_volume numeric,
    download_ok boolean,
    ec_n0 numeric,
    helicopter_measure boolean,
    hour_end time without time zone,
    hour_start time without time zone,
    id_measure integer,
    id_sending_terminal bigint,
    imei bigint,
    imsi bigint,
    insee_com character varying(5),
    insee_dep character varying(3),
    intra_inter_op_couple text,
    lac integer,
    latitude_end numeric,
    latitude_start numeric,
    list_mos numeric[],
    loaded_in_less_10_secondes boolean,
    loaded_in_less_5_secondes boolean,
    longitude_end numeric,
    longitude_start numeric,
    mcc_end integer,
    mcc_start integer,
    min_mos numeric,
    min_mos_couple numeric,
    mnc_end integer,
    mnc_start integer,
    mos_average numeric,
    nom_com character varying(255),
    nom_dep character varying(255),
    nom_reg character varying(255),
    operator character varying(255),
    mcc_mnc integer,
    quality_correct boolean,
    quality_perfect boolean,
    real_communiation_time numeric,
    reason_of_failed text,
    result text,
    rscp numeric,
    rsrp numeric,
    rsrq numeric,
    rx_lev integer,
    rx_level numeric,
    rx_qual integer,
    protocole character varying(20),
    situation character varying(20),
    sms_content text,
    sms_delai numeric,
    sms_reception_date_time timestamp without time zone,
    sms_sending_date_time timestamp without time zone,
    sms_sending_number character varying(255),
    sms_success boolean,
    tac integer,
    techno_end character varying(25),
    techno_start character varying(25),
    terminal character varying(150),
    territory character varying(20),
    time_to_call numeric,
    trace_name character varying(255),
    traffic_time numeric,
    transfert_duration numeric,
    transfert_file_size numeric,
    ul_volume numeric,
    upload_ok boolean,
    url text,
    video_freez_duration numeric,
    video_initialisation_duration numeric,
    video_viewing_duration numeric,
    zone character varying(255),
    zone_name character varying(255),
    zone_precision character varying(255),
    id_hexa integer,
    id_data_source_desc integer,
    geometry public.geometry(Point,3857),
    filename text,
    is_metropole boolean,
    is_transport boolean,
    operator_called character varying(255),
    operator_calling character varying(255),
    operator_identical character varying(5),
    operating_system character varying(255),
    operating_system_version character varying(255),
    pci text,
    ping_result boolean,
    axis_name_search character varying
);


--
-- TOC entry 676 (class 1259 OID 1658966)
-- Name: qos_test_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.qos_test_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7472 (class 0 OID 0)
-- Dependencies: 676
-- Name: qos_test_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.qos_test_fid_seq OWNED BY mrm_public.qos_test.fid;


--
-- TOC entry 677 (class 1259 OID 1658967)
-- Name: region; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.region (
    gid integer NOT NULL,
    id character varying(24),
    nom_m character varying(35),
    nom character varying(35),
    insee_reg character varying(2),
    geom public.geometry(MultiPolygon,3857)
);


--
-- TOC entry 678 (class 1259 OID 1658972)
-- Name: region_gid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.region_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7473 (class 0 OID 0)
-- Dependencies: 678
-- Name: region_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.region_gid_seq OWNED BY mrm_public.region.gid;


--
-- TOC entry 679 (class 1259 OID 1658973)
-- Name: region_light; Type: VIEW; Schema: mrm_public; Owner: -
--

CREATE VIEW mrm_public.region_light AS
 SELECT region.gid,
    region.id,
    region.nom_m,
    region.nom,
    region.insee_reg,
    (public.st_setsrid(public.st_envelope(region.geom), 3857))::public.geometry(Polygon,3857) AS extent
   FROM mrm_public.region;


--
-- TOC entry 680 (class 1259 OID 1658977)
-- Name: region_stb_stm; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.region_stb_stm (
    gid integer NOT NULL,
    id character varying(80),
    nom_m character varying(80),
    nom character varying(80),
    insee_reg character varying(80),
    geom public.geometry(MultiPolygon,5490)
);


--
-- TOC entry 681 (class 1259 OID 1658982)
-- Name: region_stb_stm_gid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.region_stb_stm_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7474 (class 0 OID 0)
-- Dependencies: 681
-- Name: region_stb_stm_gid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.region_stb_stm_gid_seq OWNED BY mrm_public.region_stb_stm.gid;


--
-- TOC entry 682 (class 1259 OID 1658983)
-- Name: seq_site_a_venir_fid; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.seq_site_a_venir_fid
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 683 (class 1259 OID 1658984)
-- Name: site; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.site (
    fid bigint NOT NULL,
    code_op bigint,
    nom_op text,
    num_site text,
    id_station_anfr text,
    x double precision,
    y double precision,
    latitude double precision,
    longitude double precision,
    nom_reg text,
    nom_dep text,
    insee_dep text,
    nom_com text,
    insee_com text,
    site_2g boolean,
    site_3g boolean,
    site_4g boolean,
    site_5g boolean,
    date_ouverturecommerciale_5g text,
    site_5g_700_m_hz boolean,
    site_5g_800_m_hz boolean,
    site_5g_1800_m_hz boolean,
    site_5g_2100_m_hz boolean,
    site_5g_3500_m_hz boolean,
    id_site_partage text,
    mes_4g_trim boolean,
    site_zb boolean,
    site_dcc boolean,
    site_strategique boolean,
    site_capa_240mbps boolean,
    annee_donnee text,
    trimestre_donnee text,
    geometry public.geometry(Point,3857),
    sup_id bigint,
    filename text
);


--
-- TOC entry 684 (class 1259 OID 1658989)
-- Name: seq_site_fid; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.seq_site_fid
    START WITH 107135
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 7475 (class 0 OID 0)
-- Dependencies: 684
-- Name: seq_site_fid; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.seq_site_fid OWNED BY mrm_public.site.fid;


--
-- TOC entry 685 (class 1259 OID 1658990)
-- Name: signalement_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.signalement_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 686 (class 1259 OID 1658991)
-- Name: signalement; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.signalement (
    fid integer DEFAULT nextval('mrm_public.signalement_seq'::regclass) NOT NULL,
    id integer,
    date date,
    insee_com character varying(5),
    operateur integer,
    latitude numeric,
    longitude numeric,
    id_hexa integer,
    geometry public.geometry(Point,3857),
    filename text,
    is_metropole boolean
);


--
-- TOC entry 687 (class 1259 OID 1658997)
-- Name: signalement_test_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.signalement_test_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 688 (class 1259 OID 1658998)
-- Name: site_a_venir; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.site_a_venir (
    fid bigint DEFAULT nextval('mrm_public.seq_site_a_venir_fid'::regclass) NOT NULL,
    code_op bigint,
    nom_op text,
    num_site text,
    id_station_anfr text,
    x double precision,
    y double precision,
    latitude double precision,
    longitude double precision,
    nom_reg text,
    nom_dep text,
    insee_dep text,
    nom_com text,
    insee_com text,
    site_2g boolean,
    site_3g boolean,
    site_4g boolean,
    site_5g boolean,
    date_ouverturecommerciale_5g text,
    site_5g_700_m_hz boolean,
    site_5g_800_m_hz boolean,
    site_5g_1800_m_hz boolean,
    site_5g_2100_m_hz boolean,
    site_5g_3500_m_hz boolean,
    id_site_partage text,
    mes_4g_trim boolean,
    site_zb boolean,
    site_dcc boolean,
    site_strategique boolean,
    site_capa_240mbps boolean,
    annee_donnee text,
    trimestre_donnee text,
    geometry public.geometry(Point,3857),
    sup_id bigint,
    filename text
);


--
-- TOC entry 689 (class 1259 OID 1659004)
-- Name: site_log; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.site_log (
    fid bigint NOT NULL,
    code_op bigint,
    nom_op text,
    num_site text,
    id_station_anfr text,
    x double precision,
    y double precision,
    latitude double precision,
    longitude double precision,
    nom_reg text,
    nom_dep text,
    insee_dep text,
    nom_com text,
    insee_com text,
    site_2g boolean,
    site_3g boolean,
    site_4g boolean,
    site_5g boolean,
    date_ouverturecommerciale_5g text,
    site_5g_700_m_hz boolean,
    site_5g_800_m_hz boolean,
    site_5g_1800_m_hz boolean,
    site_5g_2100_m_hz boolean,
    site_5g_3500_m_hz boolean,
    id_site_partage text,
    mes_4g_trim boolean,
    site_zb boolean,
    site_dcc boolean,
    site_strategique boolean,
    site_capa_240mbps boolean,
    annee_donnee text,
    trimestre_donnee text,
    geometry public.geometry(Point,3857),
    sup_id bigint
);


--
-- TOC entry 690 (class 1259 OID 1659009)
-- Name: site_state; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.site_state (
    id bigint NOT NULL,
    operateur character varying(255),
    departement character varying(4),
    code_postal character varying(20),
    code_insee character varying(5),
    commune character varying(255),
    station_anfr text,
    voix2g character varying(20),
    voix3g character varying(20),
    voix4g character varying(20),
    data3g character varying(20),
    data4g character varying(20),
    data5g character varying(20),
    voix character varying(20),
    data character varying(20),
    propre integer,
    raison character varying(255),
    detail text,
    debut_voix timestamp with time zone,
    fin_voix timestamp with time zone,
    debut_data timestamp with time zone,
    fin_data timestamp with time zone,
    debut timestamp with time zone,
    fin timestamp with time zone,
    geomlong numeric,
    geomlat numeric,
    geometry public.geometry(Point,3857)
);


--
-- TOC entry 691 (class 1259 OID 1659014)
-- Name: site_state_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.site_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7476 (class 0 OID 0)
-- Dependencies: 691
-- Name: site_state_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.site_state_id_seq OWNED BY mrm_public.site_state.id;


--
-- TOC entry 692 (class 1259 OID 1659015)
-- Name: stat_site_commune; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stat_site_commune (
    id bigint NOT NULL,
    insee_com character varying(5) NOT NULL,
    total_site integer,
    code_op bigint,
    "2g3g4g" integer,
    "5g" integer,
    "5g_autres" integer
);


--
-- TOC entry 693 (class 1259 OID 1659018)
-- Name: stat_site_communes_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stat_site_communes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7477 (class 0 OID 0)
-- Dependencies: 693
-- Name: stat_site_communes_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.stat_site_communes_id_seq OWNED BY mrm_public.stat_site_commune.id;


--
-- TOC entry 694 (class 1259 OID 1659019)
-- Name: stat_site_departement; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stat_site_departement (
    id bigint NOT NULL,
    insee_dep character varying(5) NOT NULL,
    total_site integer,
    code_op bigint,
    "2g3g4g" integer,
    "5g" integer,
    "5g_autres" integer
);


--
-- TOC entry 695 (class 1259 OID 1659022)
-- Name: stat_site_departement_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stat_site_departement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7478 (class 0 OID 0)
-- Dependencies: 695
-- Name: stat_site_departement_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.stat_site_departement_id_seq OWNED BY mrm_public.stat_site_departement.id;


--
-- TOC entry 696 (class 1259 OID 1659023)
-- Name: stat_site_region; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stat_site_region (
    id bigint NOT NULL,
    insee_reg character varying(5) NOT NULL,
    total_site integer,
    code_op bigint,
    "2g3g4g" integer,
    "5g" integer,
    "5g_autres" integer
);


--
-- TOC entry 697 (class 1259 OID 1659026)
-- Name: stat_site_region_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stat_site_region_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7479 (class 0 OID 0)
-- Dependencies: 697
-- Name: stat_site_region_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.stat_site_region_id_seq OWNED BY mrm_public.stat_site_region.id;


--
-- TOC entry 698 (class 1259 OID 1659027)
-- Name: stat_site_territoire; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stat_site_territoire (
    id bigint NOT NULL,
    insee_territoire character varying(5) NOT NULL,
    total_site integer,
    code_op bigint,
    "2g3g4g" integer,
    "5g" integer,
    "5g_autres" integer
);


--
-- TOC entry 699 (class 1259 OID 1659030)
-- Name: stat_site_territoire_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stat_site_territoire_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7480 (class 0 OID 0)
-- Dependencies: 699
-- Name: stat_site_territoire_id_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.stat_site_territoire_id_seq OWNED BY mrm_public.stat_site_territoire.id;


--
-- TOC entry 700 (class 1259 OID 1659031)
-- Name: stats_couv_communes; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stats_couv_communes (
    fid integer NOT NULL,
    techno character varying,
    commune character varying,
    couv_nc numeric,
    couv_cl numeric,
    couv_bc numeric,
    couv_tbc numeric,
    pop_nc numeric,
    pop_cl numeric,
    pop_bc numeric,
    pop_tbc numeric,
    filename text,
    mcc_mnc bigint
);


--
-- TOC entry 701 (class 1259 OID 1659036)
-- Name: stats_couv_communes_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stats_couv_communes_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7481 (class 0 OID 0)
-- Dependencies: 701
-- Name: stats_couv_communes_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.stats_couv_communes_fid_seq OWNED BY mrm_public.stats_couv_communes.fid;


--
-- TOC entry 702 (class 1259 OID 1659037)
-- Name: stats_couv_departements; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stats_couv_departements (
    fid integer NOT NULL,
    techno character varying,
    departement character varying,
    couv_nc numeric,
    couv_cl numeric,
    couv_bc numeric,
    couv_tbc numeric,
    pop_nc numeric,
    pop_cl numeric,
    pop_bc numeric,
    pop_tbc numeric,
    filename text,
    mcc_mnc integer
);


--
-- TOC entry 703 (class 1259 OID 1659042)
-- Name: stats_couv_departements_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stats_couv_departements_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7482 (class 0 OID 0)
-- Dependencies: 703
-- Name: stats_couv_departements_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.stats_couv_departements_fid_seq OWNED BY mrm_public.stats_couv_departements.fid;


--
-- TOC entry 704 (class 1259 OID 1659043)
-- Name: stats_couv_regions; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stats_couv_regions (
    fid integer NOT NULL,
    techno character varying,
    region character varying,
    couv_nc numeric,
    couv_cl numeric,
    couv_bc numeric,
    couv_tbc numeric,
    pop_nc numeric,
    pop_cl numeric,
    pop_bc numeric,
    pop_tbc numeric,
    filename text,
    mcc_mnc integer
);


--
-- TOC entry 705 (class 1259 OID 1659048)
-- Name: stats_couv_regions_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stats_couv_regions_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7483 (class 0 OID 0)
-- Dependencies: 705
-- Name: stats_couv_regions_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.stats_couv_regions_fid_seq OWNED BY mrm_public.stats_couv_regions.fid;


--
-- TOC entry 706 (class 1259 OID 1659049)
-- Name: stats_couv_territoires; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stats_couv_territoires (
    fid integer NOT NULL,
    techno character varying,
    territoire character varying,
    couv_nc numeric,
    couv_cl numeric,
    couv_bc numeric,
    couv_tbc numeric,
    pop_nc numeric,
    pop_cl numeric,
    pop_bc numeric,
    pop_tbc numeric,
    filename text,
    mcc_mnc integer
);


--
-- TOC entry 707 (class 1259 OID 1659054)
-- Name: stats_couv_territoires_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stats_couv_territoires_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7484 (class 0 OID 0)
-- Dependencies: 707
-- Name: stats_couv_territoires_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.stats_couv_territoires_fid_seq OWNED BY mrm_public.stats_couv_territoires.fid;


--
-- TOC entry 708 (class 1259 OID 1659055)
-- Name: stats_nbope_couverture_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stats_nbope_couverture_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 709 (class 1259 OID 1659056)
-- Name: stats_nbope_couverture; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stats_nbope_couverture (
    id integer DEFAULT nextval('mrm_public.stats_nbope_couverture_id_seq'::regclass) NOT NULL,
    techno text,
    niveau text,
    code character varying,
    pop_0 double precision,
    pop_1 double precision,
    pop_2 double precision,
    pop_3 double precision,
    pop_4 double precision,
    pop_5 double precision,
    couv_0 double precision,
    couv_1 double precision,
    couv_2 double precision,
    couv_3 double precision,
    couv_4 double precision,
    couv_5 double precision,
    filename text,
    type text
);


--
-- TOC entry 710 (class 1259 OID 1659062)
-- Name: stats_nbope_couverture_met; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stats_nbope_couverture_met (
    ogc_fid integer NOT NULL,
    techno character varying,
    niveau character varying,
    commune character varying,
    pop_0 character varying,
    pop_1 character varying,
    pop_2 character varying,
    pop_3 character varying,
    pop_4 character varying,
    pop_5 character varying,
    couv_0 character varying,
    couv_1 character varying,
    couv_2 character varying,
    couv_3 character varying,
    couv_4 character varying,
    couv_5 character varying
);


--
-- TOC entry 711 (class 1259 OID 1659067)
-- Name: stats_nbope_couverture_met_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stats_nbope_couverture_met_ogc_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7485 (class 0 OID 0)
-- Dependencies: 711
-- Name: stats_nbope_couverture_met_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.stats_nbope_couverture_met_ogc_fid_seq OWNED BY mrm_public.stats_nbope_couverture_met.ogc_fid;


--
-- TOC entry 712 (class 1259 OID 1659068)
-- Name: stats_qos_departements_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stats_qos_departements_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 713 (class 1259 OID 1659069)
-- Name: stats_qos_departements; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stats_qos_departements (
    id integer DEFAULT nextval('mrm_public.stats_qos_departements_fid_seq'::regclass),
    nom_region character varying,
    insee_dep character varying,
    protocole character varying,
    zone character varying,
    situation character varying,
    mcc_mnc integer,
    resultat numeric,
    nb_test numeric,
    filename text
);


--
-- TOC entry 714 (class 1259 OID 1659075)
-- Name: stats_test_met; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.stats_test_met (
    ogc_fid integer NOT NULL,
    techno character varying,
    niveau character varying,
    code character varying,
    pop_0 character varying,
    pop_1 character varying,
    pop_2 character varying,
    pop_3 character varying,
    pop_4 character varying,
    pop_5 character varying,
    couv_0 character varying,
    couv_1 character varying,
    couv_2 character varying,
    couv_3 character varying,
    couv_4 character varying,
    couv_5 character varying
);


--
-- TOC entry 715 (class 1259 OID 1659080)
-- Name: stats_test_met_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.stats_test_met_ogc_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7486 (class 0 OID 0)
-- Dependencies: 715
-- Name: stats_test_met_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.stats_test_met_ogc_fid_seq OWNED BY mrm_public.stats_test_met.ogc_fid;


--
-- TOC entry 716 (class 1259 OID 1659081)
-- Name: tbc_2g3g_tiles_cache; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.tbc_2g3g_tiles_cache (
    z integer NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    operateur bigint NOT NULL,
    mvt bytea NOT NULL
);


--
-- TOC entry 717 (class 1259 OID 1659086)
-- Name: tiles_cache; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.tiles_cache (
    z integer NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    operateur bigint NOT NULL,
    techno character varying NOT NULL,
    mvt bytea NOT NULL
);


--
-- TOC entry 718 (class 1259 OID 1659091)
-- Name: tiles_cache_couverture; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.tiles_cache_couverture (
    z integer NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    operateur bigint NOT NULL,
    techno character varying NOT NULL,
    mvt bytea NOT NULL
);


--
-- TOC entry 719 (class 1259 OID 1659096)
-- Name: tiles_cache_couverture_tbc; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.tiles_cache_couverture_tbc (
    z integer NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    techno character varying NOT NULL,
    mvt bytea NOT NULL
);


--
-- TOC entry 720 (class 1259 OID 1659101)
-- Name: zac_axe_ferre_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.zac_axe_ferre_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 721 (class 1259 OID 1659102)
-- Name: zac_axe_ferre; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.zac_axe_ferre (
    ogc_fid integer DEFAULT nextval('mrm_public.zac_axe_ferre_ogc_fid_seq'::regclass) NOT NULL,
    id bigint,
    geometry public.geometry(MultiLineString,3857),
    filename text
);


--
-- TOC entry 722 (class 1259 OID 1659108)
-- Name: zac_axe_ferre_old; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.zac_axe_ferre_old (
    fid integer NOT NULL,
    objectid numeric(10,0),
    nom_dep character varying(30),
    insee_dep character varying(3),
    insee_reg character varying(2),
    shape_leng numeric(19,11),
    geometry public.geometry(MultiLineStringZ,3857),
    filename text
);


--
-- TOC entry 723 (class 1259 OID 1659113)
-- Name: zac_axe_ferre_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.zac_axe_ferre_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7487 (class 0 OID 0)
-- Dependencies: 723
-- Name: zac_axe_ferre_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.zac_axe_ferre_fid_seq OWNED BY mrm_public.zac_axe_ferre_old.fid;


--
-- TOC entry 724 (class 1259 OID 1659114)
-- Name: zac_axe_routier_prioritaire_5g_old; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.zac_axe_routier_prioritaire_5g_old (
    fid integer NOT NULL,
    id_rte500 numeric(6,0),
    vocation character varying(18),
    nb_chausse character varying(12),
    nb_voies character varying(27),
    etat character varying(10),
    acces character varying(10),
    res_vert character varying(16),
    sens character varying(12),
    res_europe character varying(20),
    num_route character varying(10),
    class_adm character varying(15),
    longueur numeric(6,2),
    long_axe numeric(10,0),
    geometry public.geometry(MultiLineStringZ,3857),
    filename text
);


--
-- TOC entry 725 (class 1259 OID 1659119)
-- Name: zac_axe_routier_principale_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.zac_axe_routier_principale_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7488 (class 0 OID 0)
-- Dependencies: 725
-- Name: zac_axe_routier_principale_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.zac_axe_routier_principale_fid_seq OWNED BY mrm_public.zac_axe_routier_prioritaire_5g_old.fid;


--
-- TOC entry 726 (class 1259 OID 1659120)
-- Name: zac_axe_routier_prioritaire_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.zac_axe_routier_prioritaire_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 727 (class 1259 OID 1659121)
-- Name: zac_axe_routier_prioritaire; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.zac_axe_routier_prioritaire (
    ogc_fid integer DEFAULT nextval('mrm_public.zac_axe_routier_prioritaire_ogc_fid_seq'::regclass) NOT NULL,
    id bigint,
    geometry public.geometry(MultiLineString,3857),
    filename text
);


--
-- TOC entry 728 (class 1259 OID 1659127)
-- Name: zac_axe_routier_prioritaire_5g_ogc_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.zac_axe_routier_prioritaire_5g_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 729 (class 1259 OID 1659128)
-- Name: zac_axe_routier_prioritaire_5g; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.zac_axe_routier_prioritaire_5g (
    ogc_fid integer DEFAULT nextval('mrm_public.zac_axe_routier_prioritaire_5g_ogc_fid_seq'::regclass) NOT NULL,
    id bigint,
    geometry public.geometry(MultiLineString,3857),
    filename text
);


--
-- TOC entry 730 (class 1259 OID 1659134)
-- Name: zac_axe_routier_prioritaire_old; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.zac_axe_routier_prioritaire_old (
    fid integer NOT NULL,
    code_dpt character varying,
    classe character varying,
    nom_route character varying,
    idarp integer,
    long double precision,
    geometry public.geometry(MultiLineStringZ,3857),
    filename text
);


--
-- TOC entry 731 (class 1259 OID 1659139)
-- Name: zac_axe_routier_prioritaire_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.zac_axe_routier_prioritaire_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7489 (class 0 OID 0)
-- Dependencies: 731
-- Name: zac_axe_routier_prioritaire_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.zac_axe_routier_prioritaire_fid_seq OWNED BY mrm_public.zac_axe_routier_prioritaire_old.fid;


--
-- TOC entry 732 (class 1259 OID 1659140)
-- Name: zac_poi_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.zac_poi_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 733 (class 1259 OID 1659141)
-- Name: zac_poi; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.zac_poi (
    id integer DEFAULT nextval('mrm_public.zac_poi_id_seq'::regclass) NOT NULL,
    id_point bigint,
    num_arrete character varying,
    date_publication_arrete text,
    id_dossier integer,
    nom_dossier character varying,
    nb_sites_dossier integer,
    code_insee character varying,
    nom_commune character varying,
    departement character varying,
    insee_dep character varying,
    region character varying,
    x_lambert_93 numeric,
    y_lambert_93 numeric,
    origine_zone character varying,
    origine_coordonnees character varying,
    num_zone_arrete character varying,
    nom_point_arrete character varying,
    identifiant_site character varying,
    lien_arrete character varying,
    geom public.geometry(Point,3857),
    filename text
);


--
-- TOC entry 734 (class 1259 OID 1659147)
-- Name: zac_poi_operateurs; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.zac_poi_operateurs (
    fid bigint NOT NULL,
    id_point bigint NOT NULL,
    id_operateur integer NOT NULL,
    filename text
);


--
-- TOC entry 735 (class 1259 OID 1659152)
-- Name: zac_poi_operateurs_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.zac_poi_operateurs_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7490 (class 0 OID 0)
-- Dependencies: 735
-- Name: zac_poi_operateurs_fid_seq; Type: SEQUENCE OWNED BY; Schema: mrm_public; Owner: -
--

ALTER SEQUENCE mrm_public.zac_poi_operateurs_fid_seq OWNED BY mrm_public.zac_poi_operateurs.fid;


--
-- TOC entry 736 (class 1259 OID 1659153)
-- Name: zac_site_id_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.zac_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- TOC entry 737 (class 1259 OID 1659154)
-- Name: zac_site; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.zac_site (
    id integer DEFAULT nextval('mrm_public.zac_site_id_seq'::regclass) NOT NULL,
    num_arrete character varying,
    date_publication_arrete text,
    numero_site integer,
    nom_site_operateurs character varying,
    site_physique integer,
    numero_site_physique integer,
    nom_site_arrete character varying,
    id_dossier integer,
    nom_de_la_zone character varying,
    region character varying,
    departement character varying,
    insee_dep character varying,
    x_lambert_93 numeric,
    y_lambert_93 numeric,
    op_leader bigint,
    sites_demandes integer,
    sites_mes integer,
    sites_6_mois integer,
    sites_6_24_mois integer,
    sites_attente_deploiement integer,
    origine_zone character varying,
    num_zone_arrete character varying,
    geom public.geometry(Point,3857),
    filename text
);


--
-- TOC entry 738 (class 1259 OID 1659160)
-- Name: zac_site_operateurs_fid_seq; Type: SEQUENCE; Schema: mrm_public; Owner: -
--

CREATE SEQUENCE mrm_public.zac_site_operateurs_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 739 (class 1259 OID 1659161)
-- Name: zac_site_operateurs; Type: TABLE; Schema: mrm_public; Owner: -
--

CREATE TABLE mrm_public.zac_site_operateurs (
    fid bigint DEFAULT nextval('mrm_public.zac_site_operateurs_fid_seq'::regclass) NOT NULL,
    numero_site bigint NOT NULL,
    id_operateur integer NOT NULL,
    filename text
);


--
-- TOC entry 229 (class 1259 OID 784383)
-- Name: auth_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);


--
-- TOC entry 230 (class 1259 OID 784386)
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_group ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 231 (class 1259 OID 784387)
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_group_permissions (
    id bigint NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


--
-- TOC entry 232 (class 1259 OID 784390)
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_group_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 233 (class 1259 OID 784391)
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


--
-- TOC entry 234 (class 1259 OID 784394)
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_permission ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 235 (class 1259 OID 784395)
-- Name: axes_accessattempt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.axes_accessattempt (
    id integer NOT NULL,
    user_agent character varying(255) NOT NULL,
    ip_address inet,
    username character varying(255),
    http_accept character varying(1025) NOT NULL,
    path_info character varying(255) NOT NULL,
    attempt_time timestamp with time zone NOT NULL,
    get_data text NOT NULL,
    post_data text NOT NULL,
    failures_since_start integer NOT NULL,
    CONSTRAINT axes_accessattempt_failures_since_start_check CHECK ((failures_since_start >= 0))
);


--
-- TOC entry 236 (class 1259 OID 784401)
-- Name: axes_accessattempt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.axes_accessattempt ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.axes_accessattempt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 237 (class 1259 OID 784402)
-- Name: axes_accessfailurelog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.axes_accessfailurelog (
    id integer NOT NULL,
    user_agent character varying(255) NOT NULL,
    ip_address inet,
    username character varying(255),
    http_accept character varying(1025) NOT NULL,
    path_info character varying(255) NOT NULL,
    attempt_time timestamp with time zone NOT NULL,
    locked_out boolean NOT NULL
);


--
-- TOC entry 238 (class 1259 OID 784407)
-- Name: axes_accessfailurelog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.axes_accessfailurelog ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.axes_accessfailurelog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 239 (class 1259 OID 784408)
-- Name: axes_accesslog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.axes_accesslog (
    id integer NOT NULL,
    user_agent character varying(255) NOT NULL,
    ip_address inet,
    username character varying(255),
    http_accept character varying(1025) NOT NULL,
    path_info character varying(255) NOT NULL,
    attempt_time timestamp with time zone NOT NULL,
    logout_time timestamp with time zone,
    session_hash character varying(64) NOT NULL
);


--
-- TOC entry 240 (class 1259 OID 784413)
-- Name: axes_accesslog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.axes_accesslog ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.axes_accesslog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 241 (class 1259 OID 784414)
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id bigint NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);


--
-- TOC entry 242 (class 1259 OID 784420)
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_admin_log ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_admin_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 243 (class 1259 OID 784421)
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


--
-- TOC entry 244 (class 1259 OID 784424)
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_content_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_content_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 245 (class 1259 OID 784425)
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


--
-- TOC entry 246 (class 1259 OID 784430)
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_migrations ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 247 (class 1259 OID 784431)
-- Name: django_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


--
-- TOC entry 248 (class 1259 OID 784436)
-- Name: import_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_log (
    id integer NOT NULL,
    date timestamp without time zone,
    type character varying(100),
    success boolean NOT NULL,
    observation character varying(200)
);


--
-- TOC entry 249 (class 1259 OID 784439)
-- Name: import_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.import_log ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.import_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 250 (class 1259 OID 784440)
-- Name: operateurs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operateurs (
    identifiant integer NOT NULL,
    nom_entier character varying(255) NOT NULL,
    nom_affichage character varying(255) NOT NULL,
    logo character varying(255),
    couleur_defaut character varying(25) NOT NULL,
    couleur_niveau_1 character varying(25) NOT NULL,
    couleur_niveau_2 character varying(25) NOT NULL,
    couleur_niveau_3 character varying(25) NOT NULL,
    couleur_niveau_4 character varying(25) NOT NULL,
    perimetre_metro boolean NOT NULL,
    perimetre_971 boolean NOT NULL,
    perimetre_972 boolean NOT NULL,
    perimetre_973 boolean NOT NULL,
    perimetre_974 boolean NOT NULL,
    perimetre_976 boolean NOT NULL,
    perimetre_977 boolean NOT NULL,
    perimetre_978 boolean NOT NULL,
    icon_antenne character varying(25),
    code character varying(255)
);


--
-- TOC entry 251 (class 1259 OID 784445)
-- Name: qos_data_source_list; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qos_data_source_list (
    id integer NOT NULL,
    title character varying(255),
    source character varying(20)
);


--
-- TOC entry 252 (class 1259 OID 784448)
-- Name: qos_data_source_list_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.qos_data_source_list_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7551 (class 0 OID 0)
-- Dependencies: 252
-- Name: qos_data_source_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.qos_data_source_list_id_seq OWNED BY public.qos_data_source_list.id;


--
-- TOC entry 253 (class 1259 OID 784449)
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL
);


--
-- TOC entry 254 (class 1259 OID 784454)
-- Name: users_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_groups (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    group_id integer NOT NULL
);


--
-- TOC entry 255 (class 1259 OID 784457)
-- Name: users_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.users_groups ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.users_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 256 (class 1259 OID 784458)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.users ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 257 (class 1259 OID 784459)
-- Name: users_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_user_permissions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    permission_id integer NOT NULL
);


--
-- TOC entry 258 (class 1259 OID 784462)
-- Name: users_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.users_user_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.users_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 6311 (class 2604 OID 1737034)
-- Name: commune gid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.commune ALTER COLUMN gid SET DEFAULT nextval('mrm_private.commune_gid_seq'::regclass);


--
-- TOC entry 6312 (class 2604 OID 1737035)
-- Name: commune_stb_stm gid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.commune_stb_stm ALTER COLUMN gid SET DEFAULT nextval('mrm_private.commune_stb_stm_gid_seq'::regclass);


--
-- TOC entry 6313 (class 2604 OID 1737036)
-- Name: couverture_theorique fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.couverture_theorique ALTER COLUMN fid SET DEFAULT nextval('mrm_private.couverture_theorique_fid_seq'::regclass);


--
-- TOC entry 6314 (class 2604 OID 1737037)
-- Name: data_date_description id; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.data_date_description ALTER COLUMN id SET DEFAULT nextval('mrm_private.data_date_description_id_seq'::regclass);


--
-- TOC entry 6315 (class 2604 OID 1737038)
-- Name: departement gid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.departement ALTER COLUMN gid SET DEFAULT nextval('mrm_private.departement_gid_seq'::regclass);


--
-- TOC entry 6316 (class 2604 OID 1737039)
-- Name: departement_stb_stm gid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.departement_stb_stm ALTER COLUMN gid SET DEFAULT nextval('mrm_private.departement_stb_stm_gid_seq'::regclass);


--
-- TOC entry 6320 (class 2604 OID 1737040)
-- Name: l_commune_arrondissement ogc_fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.l_commune_arrondissement ALTER COLUMN ogc_fid SET DEFAULT nextval('mrm_private.l_commune_arrondissement_ogc_fid_seq'::regclass);


--
-- TOC entry 6321 (class 2604 OID 1737041)
-- Name: parameters id; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.parameters ALTER COLUMN id SET DEFAULT nextval('mrm_private.parameters_id_seq'::regclass);


--
-- TOC entry 6322 (class 2604 OID 1737042)
-- Name: qos fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos ALTER COLUMN fid SET DEFAULT nextval('mrm_private.qos_fid_seq'::regclass);


--
-- TOC entry 6323 (class 2604 OID 1737043)
-- Name: qos_categorie_transport id; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos_categorie_transport ALTER COLUMN id SET DEFAULT nextval('mrm_private.qos_categorie_transport_id_seq'::regclass);


--
-- TOC entry 6324 (class 2604 OID 1737044)
-- Name: qos_data_source_desc id; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos_data_source_desc ALTER COLUMN id SET DEFAULT nextval('mrm_private.qos_data_source_desc_id_seq'::regclass);


--
-- TOC entry 6328 (class 2604 OID 1737045)
-- Name: qos_test fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos_test ALTER COLUMN fid SET DEFAULT nextval('mrm_private.qos_test_fid_seq'::regclass);


--
-- TOC entry 6329 (class 2604 OID 1737046)
-- Name: region gid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.region ALTER COLUMN gid SET DEFAULT nextval('mrm_private.region_gid_seq'::regclass);


--
-- TOC entry 6330 (class 2604 OID 1737047)
-- Name: region_stb_stm gid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.region_stb_stm ALTER COLUMN gid SET DEFAULT nextval('mrm_private.region_stb_stm_gid_seq'::regclass);


--
-- TOC entry 6331 (class 2604 OID 1737048)
-- Name: site fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.site ALTER COLUMN fid SET DEFAULT nextval('mrm_private.seq_site_fid'::regclass);


--
-- TOC entry 6334 (class 2604 OID 1737049)
-- Name: site_state id; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.site_state ALTER COLUMN id SET DEFAULT nextval('mrm_private.site_state_id_seq'::regclass);


--
-- TOC entry 6335 (class 2604 OID 1737050)
-- Name: stat_site_commune id; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stat_site_commune ALTER COLUMN id SET DEFAULT nextval('mrm_private.stat_site_communes_id_seq'::regclass);


--
-- TOC entry 6336 (class 2604 OID 1737051)
-- Name: stat_site_departement id; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stat_site_departement ALTER COLUMN id SET DEFAULT nextval('mrm_private.stat_site_departement_id_seq'::regclass);


--
-- TOC entry 6337 (class 2604 OID 1737052)
-- Name: stat_site_region id; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stat_site_region ALTER COLUMN id SET DEFAULT nextval('mrm_private.stat_site_region_id_seq'::regclass);


--
-- TOC entry 6338 (class 2604 OID 1737053)
-- Name: stat_site_territoire id; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stat_site_territoire ALTER COLUMN id SET DEFAULT nextval('mrm_private.stat_site_territoire_id_seq'::regclass);


--
-- TOC entry 6339 (class 2604 OID 1737054)
-- Name: stats_couv_communes fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_couv_communes ALTER COLUMN fid SET DEFAULT nextval('mrm_private.stats_couv_communes_fid_seq'::regclass);


--
-- TOC entry 6340 (class 2604 OID 1737055)
-- Name: stats_couv_departements fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_couv_departements ALTER COLUMN fid SET DEFAULT nextval('mrm_private.stats_couv_departements_fid_seq'::regclass);


--
-- TOC entry 6341 (class 2604 OID 1737056)
-- Name: stats_couv_regions fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_couv_regions ALTER COLUMN fid SET DEFAULT nextval('mrm_private.stats_couv_regions_fid_seq'::regclass);


--
-- TOC entry 6342 (class 2604 OID 1737057)
-- Name: stats_couv_territoires fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_couv_territoires ALTER COLUMN fid SET DEFAULT nextval('mrm_private.stats_couv_territoires_fid_seq'::regclass);


--
-- TOC entry 6344 (class 2604 OID 1737058)
-- Name: stats_nbope_couverture_met ogc_fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_nbope_couverture_met ALTER COLUMN ogc_fid SET DEFAULT nextval('mrm_private.stats_nbope_couverture_met_ogc_fid_seq'::regclass);


--
-- TOC entry 6346 (class 2604 OID 1737059)
-- Name: stats_test_met ogc_fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_test_met ALTER COLUMN ogc_fid SET DEFAULT nextval('mrm_private.stats_test_met_ogc_fid_seq'::regclass);


--
-- TOC entry 6348 (class 2604 OID 1737060)
-- Name: zac_axe_ferre_old fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.zac_axe_ferre_old ALTER COLUMN fid SET DEFAULT nextval('mrm_private.zac_axe_ferre_fid_seq'::regclass);


--
-- TOC entry 6349 (class 2604 OID 1737061)
-- Name: zac_axe_routier_prioritaire_5g_old fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.zac_axe_routier_prioritaire_5g_old ALTER COLUMN fid SET DEFAULT nextval('mrm_private.zac_axe_routier_principale_fid_seq'::regclass);


--
-- TOC entry 6352 (class 2604 OID 1737062)
-- Name: zac_axe_routier_prioritaire_old fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.zac_axe_routier_prioritaire_old ALTER COLUMN fid SET DEFAULT nextval('mrm_private.zac_axe_routier_prioritaire_fid_seq'::regclass);


--
-- TOC entry 6354 (class 2604 OID 1737063)
-- Name: zac_poi_operateurs fid; Type: DEFAULT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.zac_poi_operateurs ALTER COLUMN fid SET DEFAULT nextval('mrm_private.zac_poi_operateurs_fid_seq'::regclass);


--
-- TOC entry 6258 (class 2604 OID 1659167)
-- Name: commune gid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.commune ALTER COLUMN gid SET DEFAULT nextval('mrm_public.commune_gid_seq'::regclass);


--
-- TOC entry 6259 (class 2604 OID 1659168)
-- Name: commune_stb_stm gid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.commune_stb_stm ALTER COLUMN gid SET DEFAULT nextval('mrm_public.commune_stb_stm_gid_seq'::regclass);


--
-- TOC entry 6260 (class 2604 OID 1659169)
-- Name: couverture_theorique fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.couverture_theorique ALTER COLUMN fid SET DEFAULT nextval('mrm_public.couverture_theorique_fid_seq'::regclass);


--
-- TOC entry 6261 (class 2604 OID 1659170)
-- Name: data_date_description id; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.data_date_description ALTER COLUMN id SET DEFAULT nextval('mrm_public.data_date_description_id_seq'::regclass);


--
-- TOC entry 6262 (class 2604 OID 1659171)
-- Name: departement gid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.departement ALTER COLUMN gid SET DEFAULT nextval('mrm_public.departement_gid_seq'::regclass);


--
-- TOC entry 6263 (class 2604 OID 1659172)
-- Name: departement_stb_stm gid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.departement_stb_stm ALTER COLUMN gid SET DEFAULT nextval('mrm_public.departement_stb_stm_gid_seq'::regclass);


--
-- TOC entry 6267 (class 2604 OID 1659173)
-- Name: l_commune_arrondissement ogc_fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.l_commune_arrondissement ALTER COLUMN ogc_fid SET DEFAULT nextval('mrm_public.l_commune_arrondissement_ogc_fid_seq'::regclass);


--
-- TOC entry 6268 (class 2604 OID 1659174)
-- Name: parameters id; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.parameters ALTER COLUMN id SET DEFAULT nextval('mrm_public.parameters_id_seq'::regclass);


--
-- TOC entry 6269 (class 2604 OID 1659175)
-- Name: qos fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos ALTER COLUMN fid SET DEFAULT nextval('mrm_public.qos_fid_seq'::regclass);


--
-- TOC entry 6270 (class 2604 OID 1659176)
-- Name: qos_categorie_transport id; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos_categorie_transport ALTER COLUMN id SET DEFAULT nextval('mrm_public.qos_categorie_transport_id_seq'::regclass);


--
-- TOC entry 6271 (class 2604 OID 1659177)
-- Name: qos_data_source_desc id; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos_data_source_desc ALTER COLUMN id SET DEFAULT nextval('mrm_public.qos_data_source_desc_id_seq'::regclass);


--
-- TOC entry 6275 (class 2604 OID 1659178)
-- Name: qos_test fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos_test ALTER COLUMN fid SET DEFAULT nextval('mrm_public.qos_test_fid_seq'::regclass);


--
-- TOC entry 6276 (class 2604 OID 1659179)
-- Name: region gid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.region ALTER COLUMN gid SET DEFAULT nextval('mrm_public.region_gid_seq'::regclass);


--
-- TOC entry 6277 (class 2604 OID 1659180)
-- Name: region_stb_stm gid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.region_stb_stm ALTER COLUMN gid SET DEFAULT nextval('mrm_public.region_stb_stm_gid_seq'::regclass);


--
-- TOC entry 6278 (class 2604 OID 1659181)
-- Name: site fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.site ALTER COLUMN fid SET DEFAULT nextval('mrm_public.seq_site_fid'::regclass);


--
-- TOC entry 6281 (class 2604 OID 1659182)
-- Name: site_state id; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.site_state ALTER COLUMN id SET DEFAULT nextval('mrm_public.site_state_id_seq'::regclass);


--
-- TOC entry 6282 (class 2604 OID 1659183)
-- Name: stat_site_commune id; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stat_site_commune ALTER COLUMN id SET DEFAULT nextval('mrm_public.stat_site_communes_id_seq'::regclass);


--
-- TOC entry 6283 (class 2604 OID 1659184)
-- Name: stat_site_departement id; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stat_site_departement ALTER COLUMN id SET DEFAULT nextval('mrm_public.stat_site_departement_id_seq'::regclass);


--
-- TOC entry 6284 (class 2604 OID 1659185)
-- Name: stat_site_region id; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stat_site_region ALTER COLUMN id SET DEFAULT nextval('mrm_public.stat_site_region_id_seq'::regclass);


--
-- TOC entry 6285 (class 2604 OID 1659186)
-- Name: stat_site_territoire id; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stat_site_territoire ALTER COLUMN id SET DEFAULT nextval('mrm_public.stat_site_territoire_id_seq'::regclass);


--
-- TOC entry 6286 (class 2604 OID 1659187)
-- Name: stats_couv_communes fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_couv_communes ALTER COLUMN fid SET DEFAULT nextval('mrm_public.stats_couv_communes_fid_seq'::regclass);


--
-- TOC entry 6287 (class 2604 OID 1659188)
-- Name: stats_couv_departements fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_couv_departements ALTER COLUMN fid SET DEFAULT nextval('mrm_public.stats_couv_departements_fid_seq'::regclass);


--
-- TOC entry 6288 (class 2604 OID 1659189)
-- Name: stats_couv_regions fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_couv_regions ALTER COLUMN fid SET DEFAULT nextval('mrm_public.stats_couv_regions_fid_seq'::regclass);


--
-- TOC entry 6289 (class 2604 OID 1659190)
-- Name: stats_couv_territoires fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_couv_territoires ALTER COLUMN fid SET DEFAULT nextval('mrm_public.stats_couv_territoires_fid_seq'::regclass);


--
-- TOC entry 6291 (class 2604 OID 1659191)
-- Name: stats_nbope_couverture_met ogc_fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_nbope_couverture_met ALTER COLUMN ogc_fid SET DEFAULT nextval('mrm_public.stats_nbope_couverture_met_ogc_fid_seq'::regclass);


--
-- TOC entry 6293 (class 2604 OID 1659192)
-- Name: stats_test_met ogc_fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_test_met ALTER COLUMN ogc_fid SET DEFAULT nextval('mrm_public.stats_test_met_ogc_fid_seq'::regclass);


--
-- TOC entry 6295 (class 2604 OID 1659193)
-- Name: zac_axe_ferre_old fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.zac_axe_ferre_old ALTER COLUMN fid SET DEFAULT nextval('mrm_public.zac_axe_ferre_fid_seq'::regclass);


--
-- TOC entry 6296 (class 2604 OID 1659194)
-- Name: zac_axe_routier_prioritaire_5g_old fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.zac_axe_routier_prioritaire_5g_old ALTER COLUMN fid SET DEFAULT nextval('mrm_public.zac_axe_routier_principale_fid_seq'::regclass);


--
-- TOC entry 6299 (class 2604 OID 1659195)
-- Name: zac_axe_routier_prioritaire_old fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.zac_axe_routier_prioritaire_old ALTER COLUMN fid SET DEFAULT nextval('mrm_public.zac_axe_routier_prioritaire_fid_seq'::regclass);


--
-- TOC entry 6301 (class 2604 OID 1659196)
-- Name: zac_poi_operateurs fid; Type: DEFAULT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.zac_poi_operateurs ALTER COLUMN fid SET DEFAULT nextval('mrm_public.zac_poi_operateurs_fid_seq'::regclass);


--
-- TOC entry 6091 (class 2604 OID 784583)
-- Name: qos_data_source_list id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qos_data_source_list ALTER COLUMN id SET DEFAULT nextval('public.qos_data_source_list_id_seq'::regclass);


--
-- TOC entry 7006 (class 2606 OID 1806174)
-- Name: anfr_sup_antenne anfr_sup_antenne_pk; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.anfr_sup_antenne
    ADD CONSTRAINT anfr_sup_antenne_pk PRIMARY KEY (fid);


--
-- TOC entry 7011 (class 2606 OID 1806176)
-- Name: anfr_sup_bande anfr_sup_bande_pk; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.anfr_sup_bande
    ADD CONSTRAINT anfr_sup_bande_pk PRIMARY KEY (fid);


--
-- TOC entry 7014 (class 2606 OID 1806178)
-- Name: anfr_sup_emetteur anfr_sup_emetteur_pk; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.anfr_sup_emetteur
    ADD CONSTRAINT anfr_sup_emetteur_pk PRIMARY KEY (fid);


--
-- TOC entry 7017 (class 2606 OID 1806180)
-- Name: anfr_sup_nature anfr_sup_nature_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.anfr_sup_nature
    ADD CONSTRAINT anfr_sup_nature_pkey PRIMARY KEY (ogc_fid);


--
-- TOC entry 7019 (class 2606 OID 1806182)
-- Name: anfr_sup_station anfr_sup_station_pk; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.anfr_sup_station
    ADD CONSTRAINT anfr_sup_station_pk PRIMARY KEY (fid);


--
-- TOC entry 7029 (class 2606 OID 1806184)
-- Name: anfr_sup_support_log anfr_sup_support_log_pk; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.anfr_sup_support_log
    ADD CONSTRAINT anfr_sup_support_log_pk PRIMARY KEY (fid);


--
-- TOC entry 7023 (class 2606 OID 1806186)
-- Name: anfr_sup_support anfr_sup_support_pk; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.anfr_sup_support
    ADD CONSTRAINT anfr_sup_support_pk PRIMARY KEY (fid);


--
-- TOC entry 7031 (class 2606 OID 1806188)
-- Name: commune commune_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.commune
    ADD CONSTRAINT commune_pkey PRIMARY KEY (gid);


--
-- TOC entry 7037 (class 2606 OID 1806190)
-- Name: commune_stb_stm commune_stb_stm_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.commune_stb_stm
    ADD CONSTRAINT commune_stb_stm_pkey PRIMARY KEY (gid);


--
-- TOC entry 7041 (class 2606 OID 1806192)
-- Name: couverture_theorique couverture_theorique_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.couverture_theorique
    ADD CONSTRAINT couverture_theorique_pkey PRIMARY KEY (fid);


--
-- TOC entry 7045 (class 2606 OID 1806194)
-- Name: data_date_description data_date_description_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.data_date_description
    ADD CONSTRAINT data_date_description_pkey PRIMARY KEY (id);


--
-- TOC entry 7047 (class 2606 OID 1806196)
-- Name: departement departement_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.departement
    ADD CONSTRAINT departement_pkey PRIMARY KEY (gid);


--
-- TOC entry 7051 (class 2606 OID 1806198)
-- Name: departement_stb_stm departement_stb_stm_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.departement_stb_stm
    ADD CONSTRAINT departement_stb_stm_pkey PRIMARY KEY (gid);


--
-- TOC entry 7054 (class 2606 OID 1806200)
-- Name: emetteurs_link emetteurs_link_pk; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.emetteurs_link
    ADD CONSTRAINT emetteurs_link_pk PRIMARY KEY (id);


--
-- TOC entry 7057 (class 2606 OID 1806202)
-- Name: hexa_30m hexa_30m_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.hexa_30m
    ADD CONSTRAINT hexa_30m_pkey PRIMARY KEY (fid);


--
-- TOC entry 7061 (class 2606 OID 1806204)
-- Name: hexa_signalement hexa_signalement_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.hexa_signalement
    ADD CONSTRAINT hexa_signalement_pkey PRIMARY KEY (fid);


--
-- TOC entry 7066 (class 2606 OID 1806206)
-- Name: import_log import_log_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.import_log
    ADD CONSTRAINT import_log_pkey PRIMARY KEY (id);


--
-- TOC entry 7068 (class 2606 OID 1806208)
-- Name: insee_density insee_density_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.insee_density
    ADD CONSTRAINT insee_density_pkey PRIMARY KEY (id);


--
-- TOC entry 7070 (class 2606 OID 1806210)
-- Name: l_commune_arrondissement l_commune_arrondissement_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.l_commune_arrondissement
    ADD CONSTRAINT l_commune_arrondissement_pkey PRIMARY KEY (ogc_fid);


--
-- TOC entry 7072 (class 2606 OID 1806212)
-- Name: operateurs operateurs_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.operateurs
    ADD CONSTRAINT operateurs_pkey PRIMARY KEY (identifiant);


--
-- TOC entry 7074 (class 2606 OID 1806214)
-- Name: parameters parameters_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.parameters
    ADD CONSTRAINT parameters_pkey PRIMARY KEY (id);


--
-- TOC entry 7090 (class 2606 OID 1806216)
-- Name: qos_categorie_transport qos_categorie_transport_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos_categorie_transport
    ADD CONSTRAINT qos_categorie_transport_pkey PRIMARY KEY (id);


--
-- TOC entry 7092 (class 2606 OID 1806218)
-- Name: qos_data_source_desc qos_data_source_desc_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos_data_source_desc
    ADD CONSTRAINT qos_data_source_desc_pkey PRIMARY KEY (id);


--
-- TOC entry 7096 (class 2606 OID 1806220)
-- Name: qos_data_source_list qos_data_source_list_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos_data_source_list
    ADD CONSTRAINT qos_data_source_list_pkey PRIMARY KEY (id);


--
-- TOC entry 7098 (class 2606 OID 1806222)
-- Name: qos_density qos_density_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos_density
    ADD CONSTRAINT qos_density_pkey PRIMARY KEY (id);


--
-- TOC entry 7086 (class 2606 OID 1806224)
-- Name: qos qos_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos
    ADD CONSTRAINT qos_pkey PRIMARY KEY (fid);


--
-- TOC entry 7102 (class 2606 OID 1806226)
-- Name: qos_stat qos_stat_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos_stat
    ADD CONSTRAINT qos_stat_pkey PRIMARY KEY (id);


--
-- TOC entry 7106 (class 2606 OID 1806228)
-- Name: region region_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.region
    ADD CONSTRAINT region_pkey PRIMARY KEY (gid);


--
-- TOC entry 7108 (class 2606 OID 1806230)
-- Name: region_stb_stm region_stb_stm_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.region_stb_stm
    ADD CONSTRAINT region_stb_stm_pkey PRIMARY KEY (gid);


--
-- TOC entry 7120 (class 2606 OID 1806232)
-- Name: signalement signalement_fid__pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.signalement
    ADD CONSTRAINT signalement_fid__pkey PRIMARY KEY (fid);


--
-- TOC entry 7122 (class 2606 OID 1806234)
-- Name: site_a_venir site_a_venir_fid_pk; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.site_a_venir
    ADD CONSTRAINT site_a_venir_fid_pk PRIMARY KEY (fid);


--
-- TOC entry 7124 (class 2606 OID 1806236)
-- Name: site_log site_log_pk; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.site_log
    ADD CONSTRAINT site_log_pk PRIMARY KEY (fid);


--
-- TOC entry 7114 (class 2606 OID 1806238)
-- Name: site site_pk; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.site
    ADD CONSTRAINT site_pk PRIMARY KEY (fid);


--
-- TOC entry 7129 (class 2606 OID 1806240)
-- Name: site_state site_state_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.site_state
    ADD CONSTRAINT site_state_pkey PRIMARY KEY (id);


--
-- TOC entry 7132 (class 2606 OID 1806242)
-- Name: stat_site_commune stat_site_communes_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stat_site_commune
    ADD CONSTRAINT stat_site_communes_pkey PRIMARY KEY (id);


--
-- TOC entry 7135 (class 2606 OID 1806244)
-- Name: stat_site_departement stat_site_departement_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stat_site_departement
    ADD CONSTRAINT stat_site_departement_pkey PRIMARY KEY (id);


--
-- TOC entry 7138 (class 2606 OID 1806246)
-- Name: stat_site_region stat_site_region_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stat_site_region
    ADD CONSTRAINT stat_site_region_pkey PRIMARY KEY (id);


--
-- TOC entry 7141 (class 2606 OID 1806248)
-- Name: stat_site_territoire stat_site_territoire_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stat_site_territoire
    ADD CONSTRAINT stat_site_territoire_pkey PRIMARY KEY (id);


--
-- TOC entry 7145 (class 2606 OID 1806250)
-- Name: stats_couv_communes stats_couv_communes_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_couv_communes
    ADD CONSTRAINT stats_couv_communes_pkey PRIMARY KEY (fid);


--
-- TOC entry 7149 (class 2606 OID 1806252)
-- Name: stats_couv_departements stats_couv_departements_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_couv_departements
    ADD CONSTRAINT stats_couv_departements_pkey PRIMARY KEY (fid);


--
-- TOC entry 7153 (class 2606 OID 1806254)
-- Name: stats_couv_regions stats_couv_regions_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_couv_regions
    ADD CONSTRAINT stats_couv_regions_pkey PRIMARY KEY (fid);


--
-- TOC entry 7157 (class 2606 OID 1806256)
-- Name: stats_couv_territoires stats_couv_territoires_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_couv_territoires
    ADD CONSTRAINT stats_couv_territoires_pkey PRIMARY KEY (fid);


--
-- TOC entry 7163 (class 2606 OID 1806258)
-- Name: stats_nbope_couverture_met stats_nbope_couverture_met_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_nbope_couverture_met
    ADD CONSTRAINT stats_nbope_couverture_met_pkey PRIMARY KEY (ogc_fid);


--
-- TOC entry 7161 (class 2606 OID 1806260)
-- Name: stats_nbope_couverture stats_nbope_couverture_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_nbope_couverture
    ADD CONSTRAINT stats_nbope_couverture_pkey PRIMARY KEY (id);


--
-- TOC entry 7165 (class 2606 OID 1806262)
-- Name: stats_test_met stats_test_met_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.stats_test_met
    ADD CONSTRAINT stats_test_met_pkey PRIMARY KEY (ogc_fid);


--
-- TOC entry 7167 (class 2606 OID 1806264)
-- Name: tbc_2g3g_tiles_cache tbc_2g3g_tiles_cache_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.tbc_2g3g_tiles_cache
    ADD CONSTRAINT tbc_2g3g_tiles_cache_pkey PRIMARY KEY (z, x, y, operateur);


--
-- TOC entry 7172 (class 2606 OID 1806266)
-- Name: tiles_cache_couverture tiles_cache_couverture_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.tiles_cache_couverture
    ADD CONSTRAINT tiles_cache_couverture_pkey PRIMARY KEY (z, x, y, operateur, techno);


--
-- TOC entry 7175 (class 2606 OID 1806268)
-- Name: tiles_cache_couverture_tbc tiles_cache_couverture_tbc_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.tiles_cache_couverture_tbc
    ADD CONSTRAINT tiles_cache_couverture_tbc_pkey PRIMARY KEY (z, x, y, techno);


--
-- TOC entry 7170 (class 2606 OID 1806270)
-- Name: tiles_cache tiles_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.tiles_cache
    ADD CONSTRAINT tiles_pkey PRIMARY KEY (z, x, y, operateur, techno);


--
-- TOC entry 7094 (class 2606 OID 1806272)
-- Name: qos_data_source_desc unique_title; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos_data_source_desc
    ADD CONSTRAINT unique_title UNIQUE (title);


--
-- TOC entry 7179 (class 2606 OID 1806274)
-- Name: zac_axe_ferre_old zac_axe_ferre_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.zac_axe_ferre_old
    ADD CONSTRAINT zac_axe_ferre_pkey PRIMARY KEY (fid);


--
-- TOC entry 7182 (class 2606 OID 1806276)
-- Name: zac_axe_routier_prioritaire_5g_old zac_axe_routier_principale_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.zac_axe_routier_prioritaire_5g_old
    ADD CONSTRAINT zac_axe_routier_principale_pkey PRIMARY KEY (fid);


--
-- TOC entry 7185 (class 2606 OID 1806278)
-- Name: zac_axe_routier_prioritaire_old zac_axe_routier_prioritaire_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.zac_axe_routier_prioritaire_old
    ADD CONSTRAINT zac_axe_routier_prioritaire_pkey PRIMARY KEY (fid);


--
-- TOC entry 7189 (class 2606 OID 1806280)
-- Name: zac_poi_operateurs zac_poi_operateurs_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.zac_poi_operateurs
    ADD CONSTRAINT zac_poi_operateurs_pkey PRIMARY KEY (fid);


--
-- TOC entry 7187 (class 2606 OID 1806282)
-- Name: zac_poi zac_poi_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.zac_poi
    ADD CONSTRAINT zac_poi_pkey PRIMARY KEY (id);


--
-- TOC entry 7193 (class 2606 OID 1806284)
-- Name: zac_site_operateurs zac_site_operateurs_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.zac_site_operateurs
    ADD CONSTRAINT zac_site_operateurs_pkey PRIMARY KEY (fid);


--
-- TOC entry 7191 (class 2606 OID 1806286)
-- Name: zac_site zac_site_pkey; Type: CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.zac_site
    ADD CONSTRAINT zac_site_pkey PRIMARY KEY (id);


--
-- TOC entry 6817 (class 2606 OID 1728296)
-- Name: anfr_sup_antenne anfr_sup_antenne_pk; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.anfr_sup_antenne
    ADD CONSTRAINT anfr_sup_antenne_pk PRIMARY KEY (fid);


--
-- TOC entry 6822 (class 2606 OID 1728298)
-- Name: anfr_sup_bande anfr_sup_bande_pk; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.anfr_sup_bande
    ADD CONSTRAINT anfr_sup_bande_pk PRIMARY KEY (fid);


--
-- TOC entry 6825 (class 2606 OID 1728300)
-- Name: anfr_sup_emetteur anfr_sup_emetteur_pk; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.anfr_sup_emetteur
    ADD CONSTRAINT anfr_sup_emetteur_pk PRIMARY KEY (fid);


--
-- TOC entry 6828 (class 2606 OID 1728302)
-- Name: anfr_sup_nature anfr_sup_nature_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.anfr_sup_nature
    ADD CONSTRAINT anfr_sup_nature_pkey PRIMARY KEY (ogc_fid);


--
-- TOC entry 6830 (class 2606 OID 1728304)
-- Name: anfr_sup_station anfr_sup_station_pk; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.anfr_sup_station
    ADD CONSTRAINT anfr_sup_station_pk PRIMARY KEY (fid);


--
-- TOC entry 6840 (class 2606 OID 1728306)
-- Name: anfr_sup_support_log anfr_sup_support_log_pk; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.anfr_sup_support_log
    ADD CONSTRAINT anfr_sup_support_log_pk PRIMARY KEY (fid);


--
-- TOC entry 6834 (class 2606 OID 1728308)
-- Name: anfr_sup_support anfr_sup_support_pk; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.anfr_sup_support
    ADD CONSTRAINT anfr_sup_support_pk PRIMARY KEY (fid);


--
-- TOC entry 6842 (class 2606 OID 1728310)
-- Name: commune commune_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.commune
    ADD CONSTRAINT commune_pkey PRIMARY KEY (gid);


--
-- TOC entry 6848 (class 2606 OID 1728312)
-- Name: commune_stb_stm commune_stb_stm_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.commune_stb_stm
    ADD CONSTRAINT commune_stb_stm_pkey PRIMARY KEY (gid);


--
-- TOC entry 6852 (class 2606 OID 1728314)
-- Name: couverture_theorique couverture_theorique_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.couverture_theorique
    ADD CONSTRAINT couverture_theorique_pkey PRIMARY KEY (fid);


--
-- TOC entry 6856 (class 2606 OID 1728316)
-- Name: data_date_description data_date_description_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.data_date_description
    ADD CONSTRAINT data_date_description_pkey PRIMARY KEY (id);


--
-- TOC entry 6858 (class 2606 OID 1728318)
-- Name: departement departement_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.departement
    ADD CONSTRAINT departement_pkey PRIMARY KEY (gid);


--
-- TOC entry 6862 (class 2606 OID 1728320)
-- Name: departement_stb_stm departement_stb_stm_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.departement_stb_stm
    ADD CONSTRAINT departement_stb_stm_pkey PRIMARY KEY (gid);


--
-- TOC entry 6865 (class 2606 OID 1728322)
-- Name: emetteurs_link emetteurs_link_pk; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.emetteurs_link
    ADD CONSTRAINT emetteurs_link_pk PRIMARY KEY (id);


--
-- TOC entry 6868 (class 2606 OID 1728324)
-- Name: hexa_30m hexa_30m_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.hexa_30m
    ADD CONSTRAINT hexa_30m_pkey PRIMARY KEY (fid);


--
-- TOC entry 6872 (class 2606 OID 1728326)
-- Name: hexa_signalement hexa_signalement_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.hexa_signalement
    ADD CONSTRAINT hexa_signalement_pkey PRIMARY KEY (fid);


--
-- TOC entry 6877 (class 2606 OID 1728328)
-- Name: import_log import_log_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.import_log
    ADD CONSTRAINT import_log_pkey PRIMARY KEY (id);


--
-- TOC entry 6879 (class 2606 OID 1728330)
-- Name: insee_density insee_density_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.insee_density
    ADD CONSTRAINT insee_density_pkey PRIMARY KEY (id);


--
-- TOC entry 6881 (class 2606 OID 1728332)
-- Name: l_commune_arrondissement l_commune_arrondissement_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.l_commune_arrondissement
    ADD CONSTRAINT l_commune_arrondissement_pkey PRIMARY KEY (ogc_fid);


--
-- TOC entry 6883 (class 2606 OID 1728334)
-- Name: operateurs operateurs_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.operateurs
    ADD CONSTRAINT operateurs_pkey PRIMARY KEY (identifiant);


--
-- TOC entry 6885 (class 2606 OID 1728336)
-- Name: parameters parameters_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.parameters
    ADD CONSTRAINT parameters_pkey PRIMARY KEY (id);


--
-- TOC entry 6901 (class 2606 OID 1728338)
-- Name: qos_categorie_transport qos_categorie_transport_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos_categorie_transport
    ADD CONSTRAINT qos_categorie_transport_pkey PRIMARY KEY (id);


--
-- TOC entry 6903 (class 2606 OID 1728340)
-- Name: qos_data_source_desc qos_data_source_desc_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos_data_source_desc
    ADD CONSTRAINT qos_data_source_desc_pkey PRIMARY KEY (id);


--
-- TOC entry 6907 (class 2606 OID 1728342)
-- Name: qos_data_source_list qos_data_source_list_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos_data_source_list
    ADD CONSTRAINT qos_data_source_list_pkey PRIMARY KEY (id);


--
-- TOC entry 6909 (class 2606 OID 1728344)
-- Name: qos_density qos_density_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos_density
    ADD CONSTRAINT qos_density_pkey PRIMARY KEY (id);


--
-- TOC entry 6897 (class 2606 OID 1728346)
-- Name: qos qos_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos
    ADD CONSTRAINT qos_pkey PRIMARY KEY (fid);


--
-- TOC entry 6913 (class 2606 OID 1728348)
-- Name: qos_stat qos_stat_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos_stat
    ADD CONSTRAINT qos_stat_pkey PRIMARY KEY (id);


--
-- TOC entry 6917 (class 2606 OID 1728350)
-- Name: region region_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.region
    ADD CONSTRAINT region_pkey PRIMARY KEY (gid);


--
-- TOC entry 6919 (class 2606 OID 1728352)
-- Name: region_stb_stm region_stb_stm_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.region_stb_stm
    ADD CONSTRAINT region_stb_stm_pkey PRIMARY KEY (gid);


--
-- TOC entry 6931 (class 2606 OID 1728354)
-- Name: signalement signalement_fid__pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.signalement
    ADD CONSTRAINT signalement_fid__pkey PRIMARY KEY (fid);


--
-- TOC entry 6933 (class 2606 OID 1728356)
-- Name: site_a_venir site_a_venir_fid_pk; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.site_a_venir
    ADD CONSTRAINT site_a_venir_fid_pk PRIMARY KEY (fid);


--
-- TOC entry 6935 (class 2606 OID 1728358)
-- Name: site_log site_log_pk; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.site_log
    ADD CONSTRAINT site_log_pk PRIMARY KEY (fid);


--
-- TOC entry 6925 (class 2606 OID 1728360)
-- Name: site site_pk; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.site
    ADD CONSTRAINT site_pk PRIMARY KEY (fid);


--
-- TOC entry 6940 (class 2606 OID 1728362)
-- Name: site_state site_state_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.site_state
    ADD CONSTRAINT site_state_pkey PRIMARY KEY (id);


--
-- TOC entry 6943 (class 2606 OID 1728364)
-- Name: stat_site_commune stat_site_communes_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stat_site_commune
    ADD CONSTRAINT stat_site_communes_pkey PRIMARY KEY (id);


--
-- TOC entry 6946 (class 2606 OID 1728366)
-- Name: stat_site_departement stat_site_departement_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stat_site_departement
    ADD CONSTRAINT stat_site_departement_pkey PRIMARY KEY (id);


--
-- TOC entry 6949 (class 2606 OID 1728368)
-- Name: stat_site_region stat_site_region_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stat_site_region
    ADD CONSTRAINT stat_site_region_pkey PRIMARY KEY (id);


--
-- TOC entry 6952 (class 2606 OID 1728370)
-- Name: stat_site_territoire stat_site_territoire_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stat_site_territoire
    ADD CONSTRAINT stat_site_territoire_pkey PRIMARY KEY (id);


--
-- TOC entry 6956 (class 2606 OID 1728372)
-- Name: stats_couv_communes stats_couv_communes_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_couv_communes
    ADD CONSTRAINT stats_couv_communes_pkey PRIMARY KEY (fid);


--
-- TOC entry 6960 (class 2606 OID 1728374)
-- Name: stats_couv_departements stats_couv_departements_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_couv_departements
    ADD CONSTRAINT stats_couv_departements_pkey PRIMARY KEY (fid);


--
-- TOC entry 6964 (class 2606 OID 1728376)
-- Name: stats_couv_regions stats_couv_regions_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_couv_regions
    ADD CONSTRAINT stats_couv_regions_pkey PRIMARY KEY (fid);


--
-- TOC entry 6968 (class 2606 OID 1728378)
-- Name: stats_couv_territoires stats_couv_territoires_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_couv_territoires
    ADD CONSTRAINT stats_couv_territoires_pkey PRIMARY KEY (fid);


--
-- TOC entry 6974 (class 2606 OID 1728380)
-- Name: stats_nbope_couverture_met stats_nbope_couverture_met_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_nbope_couverture_met
    ADD CONSTRAINT stats_nbope_couverture_met_pkey PRIMARY KEY (ogc_fid);


--
-- TOC entry 6972 (class 2606 OID 1728382)
-- Name: stats_nbope_couverture stats_nbope_couverture_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_nbope_couverture
    ADD CONSTRAINT stats_nbope_couverture_pkey PRIMARY KEY (id);


--
-- TOC entry 6976 (class 2606 OID 1728384)
-- Name: stats_test_met stats_test_met_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.stats_test_met
    ADD CONSTRAINT stats_test_met_pkey PRIMARY KEY (ogc_fid);


--
-- TOC entry 6978 (class 2606 OID 1728386)
-- Name: tbc_2g3g_tiles_cache tbc_2g3g_tiles_cache_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.tbc_2g3g_tiles_cache
    ADD CONSTRAINT tbc_2g3g_tiles_cache_pkey PRIMARY KEY (z, x, y, operateur);


--
-- TOC entry 6983 (class 2606 OID 1728388)
-- Name: tiles_cache_couverture tiles_cache_couverture_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.tiles_cache_couverture
    ADD CONSTRAINT tiles_cache_couverture_pkey PRIMARY KEY (z, x, y, operateur, techno);


--
-- TOC entry 6986 (class 2606 OID 1728390)
-- Name: tiles_cache_couverture_tbc tiles_cache_couverture_tbc_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.tiles_cache_couverture_tbc
    ADD CONSTRAINT tiles_cache_couverture_tbc_pkey PRIMARY KEY (z, x, y, techno);


--
-- TOC entry 6981 (class 2606 OID 1728392)
-- Name: tiles_cache tiles_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.tiles_cache
    ADD CONSTRAINT tiles_pkey PRIMARY KEY (z, x, y, operateur, techno);


--
-- TOC entry 6905 (class 2606 OID 1728394)
-- Name: qos_data_source_desc unique_title; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos_data_source_desc
    ADD CONSTRAINT unique_title UNIQUE (title);


--
-- TOC entry 6990 (class 2606 OID 1728396)
-- Name: zac_axe_ferre_old zac_axe_ferre_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.zac_axe_ferre_old
    ADD CONSTRAINT zac_axe_ferre_pkey PRIMARY KEY (fid);


--
-- TOC entry 6993 (class 2606 OID 1728398)
-- Name: zac_axe_routier_prioritaire_5g_old zac_axe_routier_principale_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.zac_axe_routier_prioritaire_5g_old
    ADD CONSTRAINT zac_axe_routier_principale_pkey PRIMARY KEY (fid);


--
-- TOC entry 6996 (class 2606 OID 1728400)
-- Name: zac_axe_routier_prioritaire_old zac_axe_routier_prioritaire_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.zac_axe_routier_prioritaire_old
    ADD CONSTRAINT zac_axe_routier_prioritaire_pkey PRIMARY KEY (fid);


--
-- TOC entry 7000 (class 2606 OID 1728402)
-- Name: zac_poi_operateurs zac_poi_operateurs_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.zac_poi_operateurs
    ADD CONSTRAINT zac_poi_operateurs_pkey PRIMARY KEY (fid);


--
-- TOC entry 6998 (class 2606 OID 1728404)
-- Name: zac_poi zac_poi_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.zac_poi
    ADD CONSTRAINT zac_poi_pkey PRIMARY KEY (id);


--
-- TOC entry 7004 (class 2606 OID 1728406)
-- Name: zac_site_operateurs zac_site_operateurs_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.zac_site_operateurs
    ADD CONSTRAINT zac_site_operateurs_pkey PRIMARY KEY (fid);


--
-- TOC entry 7002 (class 2606 OID 1728408)
-- Name: zac_site zac_site_pkey; Type: CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.zac_site
    ADD CONSTRAINT zac_site_pkey PRIMARY KEY (id);


--
-- TOC entry 6364 (class 2606 OID 1050764)
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- TOC entry 6369 (class 2606 OID 1050766)
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- TOC entry 6372 (class 2606 OID 1050768)
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 6366 (class 2606 OID 1050770)
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- TOC entry 6375 (class 2606 OID 1050772)
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- TOC entry 6377 (class 2606 OID 1050774)
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- TOC entry 6380 (class 2606 OID 1050776)
-- Name: axes_accessattempt axes_accessattempt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.axes_accessattempt
    ADD CONSTRAINT axes_accessattempt_pkey PRIMARY KEY (id);


--
-- TOC entry 6386 (class 2606 OID 1050778)
-- Name: axes_accessattempt axes_accessattempt_username_ip_address_user_agent_8ea22282_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.axes_accessattempt
    ADD CONSTRAINT axes_accessattempt_username_ip_address_user_agent_8ea22282_uniq UNIQUE (username, ip_address, user_agent);


--
-- TOC entry 6389 (class 2606 OID 1050780)
-- Name: axes_accessfailurelog axes_accessfailurelog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.axes_accessfailurelog
    ADD CONSTRAINT axes_accessfailurelog_pkey PRIMARY KEY (id);


--
-- TOC entry 6396 (class 2606 OID 1050782)
-- Name: axes_accesslog axes_accesslog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.axes_accesslog
    ADD CONSTRAINT axes_accesslog_pkey PRIMARY KEY (id);


--
-- TOC entry 6403 (class 2606 OID 1050784)
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- TOC entry 6406 (class 2606 OID 1050786)
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- TOC entry 6408 (class 2606 OID 1050788)
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- TOC entry 6410 (class 2606 OID 1050790)
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 6413 (class 2606 OID 1050792)
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- TOC entry 6416 (class 2606 OID 1050794)
-- Name: import_log import_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_log
    ADD CONSTRAINT import_log_pkey PRIMARY KEY (id);


--
-- TOC entry 6418 (class 2606 OID 1050796)
-- Name: operateurs operateurs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operateurs
    ADD CONSTRAINT operateurs_pkey PRIMARY KEY (identifiant);


--
-- TOC entry 6420 (class 2606 OID 1050798)
-- Name: qos_data_source_list qos_data_source_list_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qos_data_source_list
    ADD CONSTRAINT qos_data_source_list_pkey PRIMARY KEY (id);


--
-- TOC entry 6428 (class 2606 OID 1050800)
-- Name: users_groups users_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_groups
    ADD CONSTRAINT users_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 6431 (class 2606 OID 1050802)
-- Name: users_groups users_groups_user_id_group_id_fc7788e8_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_groups
    ADD CONSTRAINT users_groups_user_id_group_id_fc7788e8_uniq UNIQUE (user_id, group_id);


--
-- TOC entry 6422 (class 2606 OID 1050804)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 6434 (class 2606 OID 1050806)
-- Name: users_user_permissions users_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_user_permissions
    ADD CONSTRAINT users_user_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 6437 (class 2606 OID 1050808)
-- Name: users_user_permissions users_user_permissions_user_id_permission_id_3b86cbdf_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_user_permissions
    ADD CONSTRAINT users_user_permissions_user_id_permission_id_3b86cbdf_uniq UNIQUE (user_id, permission_id);


--
-- TOC entry 6425 (class 2606 OID 1050810)
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 7007 (class 1259 OID 1806287)
-- Name: anfr_sup_antenne_sta_nm_anfr_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX anfr_sup_antenne_sta_nm_anfr_idx ON mrm_private.anfr_sup_antenne USING btree (sta_nm_anfr);


--
-- TOC entry 7008 (class 1259 OID 1806288)
-- Name: anfr_sup_antenne_sup_id_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX anfr_sup_antenne_sup_id_idx ON mrm_private.anfr_sup_antenne USING btree (sup_id) WITH (deduplicate_items='true');


--
-- TOC entry 7021 (class 1259 OID 1806289)
-- Name: anfr_sup_support_id_departement_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX anfr_sup_support_id_departement_idx ON mrm_private.anfr_sup_support USING btree (id_departement);


--
-- TOC entry 7024 (class 1259 OID 1806290)
-- Name: anfr_sup_support_sup_id_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX anfr_sup_support_sup_id_idx ON mrm_private.anfr_sup_support USING btree (sup_id);


--
-- TOC entry 7038 (class 1259 OID 1806291)
-- Name: couverture_theorique_geom_geom_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX couverture_theorique_geom_geom_idx ON mrm_private.couverture_theorique USING gist (geom);


--
-- TOC entry 7039 (class 1259 OID 1806292)
-- Name: couverture_theorique_operateur_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX couverture_theorique_operateur_idx ON mrm_private.couverture_theorique USING btree (operateur);


--
-- TOC entry 7042 (class 1259 OID 1806293)
-- Name: couverture_theorique_techno_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX couverture_theorique_techno_idx ON mrm_private.couverture_theorique USING btree (techno);


--
-- TOC entry 7052 (class 1259 OID 1806294)
-- Name: emetteurs_link_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX emetteurs_link_idx ON mrm_private.emetteurs_link USING btree (id);


--
-- TOC entry 7075 (class 1259 OID 1806295)
-- Name: fki_fk_qos_id_data_source_desc; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX fki_fk_qos_id_data_source_desc ON mrm_private.qos USING btree (id_data_source_desc);


--
-- TOC entry 7025 (class 1259 OID 1806296)
-- Name: gist_anfr_sup_support_geom; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX gist_anfr_sup_support_geom ON mrm_private.anfr_sup_support USING gist (geom) WITH (buffering=auto);


--
-- TOC entry 7048 (class 1259 OID 1806297)
-- Name: gist_departement_geom; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX gist_departement_geom ON mrm_private.departement USING gist (geom) WITH (buffering=auto);


--
-- TOC entry 7055 (class 1259 OID 1806298)
-- Name: hexa_30m_geometry_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX hexa_30m_geometry_idx ON mrm_private.hexa_30m USING gist (geometry);


--
-- TOC entry 7058 (class 1259 OID 1806299)
-- Name: i_hexa_30m_fid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE UNIQUE INDEX i_hexa_30m_fid ON mrm_private.hexa_30m USING btree (fid);


--
-- TOC entry 7059 (class 1259 OID 1806300)
-- Name: i_hexa_30m_geometry_centroid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX i_hexa_30m_geometry_centroid ON mrm_private.hexa_30m USING gist (geometry_centroid);


--
-- TOC entry 7103 (class 1259 OID 1806301)
-- Name: idx_geometry_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_geometry_idx ON mrm_private.qos_test USING gist (geometry) WITH (buffering=auto);


--
-- TOC entry 7062 (class 1259 OID 1806302)
-- Name: idx_hexa_signalement_fid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_hexa_signalement_fid ON mrm_private.hexa_signalement USING btree (fid) WITH (deduplicate_items='true');


--
-- TOC entry 7063 (class 1259 OID 1806303)
-- Name: idx_hexa_signalement_geom_gist; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_hexa_signalement_geom_gist ON mrm_private.hexa_signalement USING gist (geometry) WITH (buffering=auto);


--
-- TOC entry 7064 (class 1259 OID 1806304)
-- Name: idx_hexa_signalement_geom_intersect_gist; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_hexa_signalement_geom_intersect_gist ON mrm_private.hexa_signalement USING gist (geometry_intersect) WITH (buffering=auto);


--
-- TOC entry 7116 (class 1259 OID 1806305)
-- Name: idx_id_hexa; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_id_hexa ON mrm_private.signalement USING btree (id_hexa) WITH (deduplicate_items='true');


--
-- TOC entry 7043 (class 1259 OID 1806306)
-- Name: idx_mrm_last_couverture_theorique_id; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_mrm_last_couverture_theorique_id ON mrm_private.couverture_theorique USING btree (fid) WITH (deduplicate_items='true');


--
-- TOC entry 7076 (class 1259 OID 1806307)
-- Name: idx_qos_axis; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_qos_axis ON mrm_private.qos USING btree (axis) WITH (deduplicate_items='true');


--
-- TOC entry 7077 (class 1259 OID 1806308)
-- Name: idx_qos_fid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE UNIQUE INDEX idx_qos_fid ON mrm_private.qos USING btree (fid) WITH (deduplicate_items='true');


--
-- TOC entry 7078 (class 1259 OID 1806309)
-- Name: idx_qos_id_data_source_desc; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_qos_id_data_source_desc ON mrm_private.qos USING btree (id_data_source_desc) WITH (deduplicate_items='true');


--
-- TOC entry 7079 (class 1259 OID 1806310)
-- Name: idx_qos_id_hexa; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_qos_id_hexa ON mrm_private.qos USING btree (id_hexa) WITH (deduplicate_items='true');


--
-- TOC entry 7080 (class 1259 OID 1806311)
-- Name: idx_qos_protocole; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_qos_protocole ON mrm_private.qos USING btree (protocole) WITH (deduplicate_items='true');


--
-- TOC entry 7081 (class 1259 OID 1806312)
-- Name: idx_qos_situation; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_qos_situation ON mrm_private.qos USING btree (situation) WITH (deduplicate_items='true');


--
-- TOC entry 7099 (class 1259 OID 1806313)
-- Name: idx_qos_stat_iddep; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_qos_stat_iddep ON mrm_private.qos_stat USING btree (insee_dep) WITH (deduplicate_items='true');


--
-- TOC entry 7100 (class 1259 OID 1806314)
-- Name: idx_qos_stat_mccmnc; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_qos_stat_mccmnc ON mrm_private.qos_stat USING btree (mccmnc) WITH (deduplicate_items='true');


--
-- TOC entry 7117 (class 1259 OID 1806315)
-- Name: idx_signalement_fid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_signalement_fid ON mrm_private.signalement USING btree (fid) WITH (deduplicate_items='true');


--
-- TOC entry 7118 (class 1259 OID 1806316)
-- Name: idx_signalement_geom_gist; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_signalement_geom_gist ON mrm_private.signalement USING gist (geometry) WITH (buffering=auto);


--
-- TOC entry 7109 (class 1259 OID 1806317)
-- Name: idx_site_geometry; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_site_geometry ON mrm_private.site USING gist (geometry);


--
-- TOC entry 7125 (class 1259 OID 1806318)
-- Name: idx_site_state_geometry; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_site_state_geometry ON mrm_private.site_state USING gist (geometry) WITH (buffering=auto);


--
-- TOC entry 7126 (class 1259 OID 1806319)
-- Name: idx_site_state_id; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE UNIQUE INDEX idx_site_state_id ON mrm_private.site_state USING btree (id) WITH (deduplicate_items='true');


--
-- TOC entry 7127 (class 1259 OID 1806320)
-- Name: idx_site_state_station_anfr; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_site_state_station_anfr ON mrm_private.site_state USING btree (station_anfr) WITH (deduplicate_items='true');


--
-- TOC entry 7130 (class 1259 OID 1806321)
-- Name: idx_stat_site_communes_insee_com; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stat_site_communes_insee_com ON mrm_private.stat_site_commune USING btree (insee_com) WITH (deduplicate_items='true');


--
-- TOC entry 7133 (class 1259 OID 1806322)
-- Name: idx_stat_site_departement_insee_dep; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stat_site_departement_insee_dep ON mrm_private.stat_site_departement USING btree (insee_dep) WITH (deduplicate_items='true');


--
-- TOC entry 7136 (class 1259 OID 1806323)
-- Name: idx_stat_site_region_insee_reg; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stat_site_region_insee_reg ON mrm_private.stat_site_region USING btree (insee_reg) WITH (deduplicate_items='true');


--
-- TOC entry 7139 (class 1259 OID 1806324)
-- Name: idx_stat_site_territoire_insee_territoire; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stat_site_territoire_insee_territoire ON mrm_private.stat_site_territoire USING btree (insee_territoire) WITH (deduplicate_items='true');


--
-- TOC entry 7142 (class 1259 OID 1806325)
-- Name: idx_stats_couv_communes_mcc_mnc; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stats_couv_communes_mcc_mnc ON mrm_private.stats_couv_communes USING btree (mcc_mnc) WITH (deduplicate_items='true');


--
-- TOC entry 7143 (class 1259 OID 1806326)
-- Name: idx_stats_couv_communes_techno; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stats_couv_communes_techno ON mrm_private.stats_couv_communes USING btree (techno) WITH (deduplicate_items='true');


--
-- TOC entry 7146 (class 1259 OID 1806327)
-- Name: idx_stats_couv_departements_mcc_mnc; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stats_couv_departements_mcc_mnc ON mrm_private.stats_couv_departements USING btree (mcc_mnc) WITH (deduplicate_items='true');


--
-- TOC entry 7147 (class 1259 OID 1806328)
-- Name: idx_stats_couv_departements_techno; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stats_couv_departements_techno ON mrm_private.stats_couv_departements USING btree (techno) WITH (deduplicate_items='true');


--
-- TOC entry 7150 (class 1259 OID 1806329)
-- Name: idx_stats_couv_regions_mcc_mnc; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stats_couv_regions_mcc_mnc ON mrm_private.stats_couv_regions USING btree (mcc_mnc) WITH (deduplicate_items='true');


--
-- TOC entry 7151 (class 1259 OID 1806330)
-- Name: idx_stats_couv_regions_techno; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stats_couv_regions_techno ON mrm_private.stats_couv_regions USING btree (techno) WITH (deduplicate_items='true');


--
-- TOC entry 7154 (class 1259 OID 1806331)
-- Name: idx_stats_couv_territoires_mcc_mnc; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stats_couv_territoires_mcc_mnc ON mrm_private.stats_couv_territoires USING btree (mcc_mnc) WITH (deduplicate_items='true');


--
-- TOC entry 7155 (class 1259 OID 1806332)
-- Name: idx_stats_couv_territoires_techno; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stats_couv_territoires_techno ON mrm_private.stats_couv_territoires USING btree (techno) WITH (deduplicate_items='true');


--
-- TOC entry 7158 (class 1259 OID 1806333)
-- Name: idx_stats_nbope_couverture_code; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stats_nbope_couverture_code ON mrm_private.stats_nbope_couverture USING btree (code) WITH (deduplicate_items='true');


--
-- TOC entry 7159 (class 1259 OID 1806334)
-- Name: idx_stats_nbope_couverture_techno; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX idx_stats_nbope_couverture_techno ON mrm_private.stats_nbope_couverture USING btree (techno) WITH (deduplicate_items='true');


--
-- TOC entry 7009 (class 1259 OID 1806335)
-- Name: ix_mrm_last_anfr_sup_antenne_fid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_antenne_fid ON mrm_private.anfr_sup_antenne USING btree (fid);


--
-- TOC entry 7012 (class 1259 OID 1806336)
-- Name: ix_mrm_last_anfr_sup_bande_fid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_bande_fid ON mrm_private.anfr_sup_bande USING btree (fid);


--
-- TOC entry 7015 (class 1259 OID 1806337)
-- Name: ix_mrm_last_anfr_sup_emetteur_fid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_emetteur_fid ON mrm_private.anfr_sup_emetteur USING btree (fid);


--
-- TOC entry 7020 (class 1259 OID 1806338)
-- Name: ix_mrm_last_anfr_sup_station_fid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_station_fid ON mrm_private.anfr_sup_station USING btree (fid);


--
-- TOC entry 7026 (class 1259 OID 1806339)
-- Name: ix_mrm_last_anfr_sup_support_fid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_support_fid ON mrm_private.anfr_sup_support USING btree (fid);


--
-- TOC entry 7027 (class 1259 OID 1806340)
-- Name: ix_mrm_last_anfr_sup_support_sta_nm_anfr; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_support_sta_nm_anfr ON mrm_private.anfr_sup_support USING btree (sta_nm_anfr);


--
-- TOC entry 7032 (class 1259 OID 1806341)
-- Name: ix_mrm_last_commune_geom; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_commune_geom ON mrm_private.commune USING gist (geom) WITH (buffering=auto);


--
-- TOC entry 7033 (class 1259 OID 1806342)
-- Name: ix_mrm_last_commune_gid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_commune_gid ON mrm_private.commune USING btree (gid);


--
-- TOC entry 7034 (class 1259 OID 1806343)
-- Name: ix_mrm_last_commune_insee_com; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_commune_insee_com ON mrm_private.commune USING btree (insee_com) WITH (deduplicate_items='true');


--
-- TOC entry 7035 (class 1259 OID 1806344)
-- Name: ix_mrm_last_commune_nom; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_commune_nom ON mrm_private.commune USING btree (nom);


--
-- TOC entry 7049 (class 1259 OID 1806345)
-- Name: ix_mrm_last_departement_gid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE UNIQUE INDEX ix_mrm_last_departement_gid ON mrm_private.departement USING btree (gid) WITH (deduplicate_items='true');


--
-- TOC entry 7110 (class 1259 OID 1806346)
-- Name: ix_mrm_last_site_fid; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_site_fid ON mrm_private.site USING btree (fid);


--
-- TOC entry 7111 (class 1259 OID 1806347)
-- Name: ix_mrm_last_site_id_station_anfr; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX ix_mrm_last_site_id_station_anfr ON mrm_private.site USING btree (id_station_anfr);


--
-- TOC entry 7082 (class 1259 OID 1806348)
-- Name: qos_axis_name_search_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX qos_axis_name_search_idx ON mrm_private.qos USING gin (axis_name_search public.gin_trgm_ops);


--
-- TOC entry 7087 (class 1259 OID 1806349)
-- Name: qos_categorie_transport_axis_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX qos_categorie_transport_axis_idx ON mrm_private.qos_categorie_transport USING gin (axis public.gin_trgm_ops);


--
-- TOC entry 7088 (class 1259 OID 1806350)
-- Name: qos_categorie_transport_axis_name_search_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX qos_categorie_transport_axis_name_search_idx ON mrm_private.qos_categorie_transport USING gin (axis_name_search public.gin_trgm_ops);


--
-- TOC entry 7083 (class 1259 OID 1806351)
-- Name: qos_geometry_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX qos_geometry_idx ON mrm_private.qos USING gist (geometry);


--
-- TOC entry 7084 (class 1259 OID 1806352)
-- Name: qos_mcc_mnc_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX qos_mcc_mnc_idx ON mrm_private.qos USING btree (mcc_mnc) WITH (deduplicate_items='true');


--
-- TOC entry 7104 (class 1259 OID 1806353)
-- Name: region_geom_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX region_geom_idx ON mrm_private.region USING gist (geom);


--
-- TOC entry 7112 (class 1259 OID 1806354)
-- Name: site_code_op_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX site_code_op_idx ON mrm_private.site USING btree (code_op);


--
-- TOC entry 7115 (class 1259 OID 1806355)
-- Name: site_sup_id_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX site_sup_id_idx ON mrm_private.site USING btree (sup_id);


--
-- TOC entry 7176 (class 1259 OID 1806356)
-- Name: tiles_cache_couverture_tbc_xyzt_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX tiles_cache_couverture_tbc_xyzt_idx ON mrm_private.tiles_cache_couverture_tbc USING btree (z, x, y, techno);


--
-- TOC entry 7173 (class 1259 OID 1806357)
-- Name: tiles_cache_couverture_xyzot_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX tiles_cache_couverture_xyzot_idx ON mrm_private.tiles_cache_couverture USING btree (z, x, y, operateur, techno);


--
-- TOC entry 7168 (class 1259 OID 1806358)
-- Name: tiles_cache_xyzot_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX tiles_cache_xyzot_idx ON mrm_private.tiles_cache USING btree (z, x, y, operateur, techno);


--
-- TOC entry 7177 (class 1259 OID 1806359)
-- Name: zac_axe_ferre_geom_geom_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX zac_axe_ferre_geom_geom_idx ON mrm_private.zac_axe_ferre_old USING gist (geometry);


--
-- TOC entry 7180 (class 1259 OID 1806360)
-- Name: zac_axe_routier_principale_geom_geom_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX zac_axe_routier_principale_geom_geom_idx ON mrm_private.zac_axe_routier_prioritaire_5g_old USING gist (geometry);


--
-- TOC entry 7183 (class 1259 OID 1806361)
-- Name: zac_axe_routier_prioritaire_geom_geom_idx; Type: INDEX; Schema: mrm_private; Owner: -
--

CREATE INDEX zac_axe_routier_prioritaire_geom_geom_idx ON mrm_private.zac_axe_routier_prioritaire_old USING gist (geometry);


--
-- TOC entry 6818 (class 1259 OID 1728409)
-- Name: anfr_sup_antenne_sta_nm_anfr_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX anfr_sup_antenne_sta_nm_anfr_idx ON mrm_public.anfr_sup_antenne USING btree (sta_nm_anfr);


--
-- TOC entry 6819 (class 1259 OID 1728410)
-- Name: anfr_sup_antenne_sup_id_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX anfr_sup_antenne_sup_id_idx ON mrm_public.anfr_sup_antenne USING btree (sup_id) WITH (deduplicate_items='true');


--
-- TOC entry 6832 (class 1259 OID 1728411)
-- Name: anfr_sup_support_id_departement_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX anfr_sup_support_id_departement_idx ON mrm_public.anfr_sup_support USING btree (id_departement);


--
-- TOC entry 6835 (class 1259 OID 1728412)
-- Name: anfr_sup_support_sup_id_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX anfr_sup_support_sup_id_idx ON mrm_public.anfr_sup_support USING btree (sup_id);


--
-- TOC entry 6849 (class 1259 OID 1728413)
-- Name: couverture_theorique_geom_geom_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX couverture_theorique_geom_geom_idx ON mrm_public.couverture_theorique USING gist (geom);


--
-- TOC entry 6850 (class 1259 OID 1728414)
-- Name: couverture_theorique_operateur_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX couverture_theorique_operateur_idx ON mrm_public.couverture_theorique USING btree (operateur);


--
-- TOC entry 6853 (class 1259 OID 1728415)
-- Name: couverture_theorique_techno_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX couverture_theorique_techno_idx ON mrm_public.couverture_theorique USING btree (techno);


--
-- TOC entry 6863 (class 1259 OID 1728416)
-- Name: emetteurs_link_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX emetteurs_link_idx ON mrm_public.emetteurs_link USING btree (id);


--
-- TOC entry 6886 (class 1259 OID 1728417)
-- Name: fki_fk_qos_id_data_source_desc; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX fki_fk_qos_id_data_source_desc ON mrm_public.qos USING btree (id_data_source_desc);


--
-- TOC entry 6836 (class 1259 OID 1728418)
-- Name: gist_anfr_sup_support_geom; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX gist_anfr_sup_support_geom ON mrm_public.anfr_sup_support USING gist (geom) WITH (buffering=auto);


--
-- TOC entry 6859 (class 1259 OID 1728419)
-- Name: gist_departement_geom; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX gist_departement_geom ON mrm_public.departement USING gist (geom) WITH (buffering=auto);


--
-- TOC entry 6866 (class 1259 OID 1728420)
-- Name: hexa_30m_geometry_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX hexa_30m_geometry_idx ON mrm_public.hexa_30m USING gist (geometry);


--
-- TOC entry 6869 (class 1259 OID 1728421)
-- Name: i_hexa_30m_fid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE UNIQUE INDEX i_hexa_30m_fid ON mrm_public.hexa_30m USING btree (fid);


--
-- TOC entry 6870 (class 1259 OID 1728422)
-- Name: i_hexa_30m_geometry_centroid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX i_hexa_30m_geometry_centroid ON mrm_public.hexa_30m USING gist (geometry_centroid);


--
-- TOC entry 6914 (class 1259 OID 1728423)
-- Name: idx_geometry_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_geometry_idx ON mrm_public.qos_test USING gist (geometry) WITH (buffering=auto);


--
-- TOC entry 6873 (class 1259 OID 1728424)
-- Name: idx_hexa_signalement_fid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_hexa_signalement_fid ON mrm_public.hexa_signalement USING btree (fid) WITH (deduplicate_items='true');


--
-- TOC entry 6874 (class 1259 OID 1728425)
-- Name: idx_hexa_signalement_geom_gist; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_hexa_signalement_geom_gist ON mrm_public.hexa_signalement USING gist (geometry) WITH (buffering=auto);


--
-- TOC entry 6875 (class 1259 OID 1728426)
-- Name: idx_hexa_signalement_geom_intersect_gist; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_hexa_signalement_geom_intersect_gist ON mrm_public.hexa_signalement USING gist (geometry_intersect) WITH (buffering=auto);


--
-- TOC entry 6927 (class 1259 OID 1728427)
-- Name: idx_id_hexa; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_id_hexa ON mrm_public.signalement USING btree (id_hexa) WITH (deduplicate_items='true');


--
-- TOC entry 6854 (class 1259 OID 1728428)
-- Name: idx_mrm_last_couverture_theorique_id; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_mrm_last_couverture_theorique_id ON mrm_public.couverture_theorique USING btree (fid) WITH (deduplicate_items='true');


--
-- TOC entry 6887 (class 1259 OID 1728429)
-- Name: idx_qos_axis; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_qos_axis ON mrm_public.qos USING btree (axis) WITH (deduplicate_items='true');


--
-- TOC entry 6888 (class 1259 OID 1728430)
-- Name: idx_qos_fid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE UNIQUE INDEX idx_qos_fid ON mrm_public.qos USING btree (fid) WITH (deduplicate_items='true');


--
-- TOC entry 6889 (class 1259 OID 1728431)
-- Name: idx_qos_id_data_source_desc; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_qos_id_data_source_desc ON mrm_public.qos USING btree (id_data_source_desc) WITH (deduplicate_items='true');


--
-- TOC entry 6890 (class 1259 OID 1728433)
-- Name: idx_qos_id_hexa; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_qos_id_hexa ON mrm_public.qos USING btree (id_hexa) WITH (deduplicate_items='true');


--
-- TOC entry 6891 (class 1259 OID 1728439)
-- Name: idx_qos_protocole; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_qos_protocole ON mrm_public.qos USING btree (protocole) WITH (deduplicate_items='true');


--
-- TOC entry 6892 (class 1259 OID 1728440)
-- Name: idx_qos_situation; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_qos_situation ON mrm_public.qos USING btree (situation) WITH (deduplicate_items='true');


--
-- TOC entry 6910 (class 1259 OID 1728457)
-- Name: idx_qos_stat_iddep; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_qos_stat_iddep ON mrm_public.qos_stat USING btree (insee_dep) WITH (deduplicate_items='true');


--
-- TOC entry 6911 (class 1259 OID 1728458)
-- Name: idx_qos_stat_mccmnc; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_qos_stat_mccmnc ON mrm_public.qos_stat USING btree (mccmnc) WITH (deduplicate_items='true');


--
-- TOC entry 6928 (class 1259 OID 1728459)
-- Name: idx_signalement_fid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_signalement_fid ON mrm_public.signalement USING btree (fid) WITH (deduplicate_items='true');


--
-- TOC entry 6929 (class 1259 OID 1728460)
-- Name: idx_signalement_geom_gist; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_signalement_geom_gist ON mrm_public.signalement USING gist (geometry) WITH (buffering=auto);


--
-- TOC entry 6920 (class 1259 OID 1728461)
-- Name: idx_site_geometry; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_site_geometry ON mrm_public.site USING gist (geometry);


--
-- TOC entry 6936 (class 1259 OID 1728462)
-- Name: idx_site_state_geometry; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_site_state_geometry ON mrm_public.site_state USING gist (geometry) WITH (buffering=auto);


--
-- TOC entry 6937 (class 1259 OID 1728463)
-- Name: idx_site_state_id; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE UNIQUE INDEX idx_site_state_id ON mrm_public.site_state USING btree (id) WITH (deduplicate_items='true');


--
-- TOC entry 6938 (class 1259 OID 1728464)
-- Name: idx_site_state_station_anfr; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_site_state_station_anfr ON mrm_public.site_state USING btree (station_anfr) WITH (deduplicate_items='true');


--
-- TOC entry 6941 (class 1259 OID 1728465)
-- Name: idx_stat_site_communes_insee_com; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stat_site_communes_insee_com ON mrm_public.stat_site_commune USING btree (insee_com) WITH (deduplicate_items='true');


--
-- TOC entry 6944 (class 1259 OID 1728466)
-- Name: idx_stat_site_departement_insee_dep; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stat_site_departement_insee_dep ON mrm_public.stat_site_departement USING btree (insee_dep) WITH (deduplicate_items='true');


--
-- TOC entry 6947 (class 1259 OID 1728467)
-- Name: idx_stat_site_region_insee_reg; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stat_site_region_insee_reg ON mrm_public.stat_site_region USING btree (insee_reg) WITH (deduplicate_items='true');


--
-- TOC entry 6950 (class 1259 OID 1728468)
-- Name: idx_stat_site_territoire_insee_territoire; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stat_site_territoire_insee_territoire ON mrm_public.stat_site_territoire USING btree (insee_territoire) WITH (deduplicate_items='true');


--
-- TOC entry 6953 (class 1259 OID 1728469)
-- Name: idx_stats_couv_communes_mcc_mnc; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stats_couv_communes_mcc_mnc ON mrm_public.stats_couv_communes USING btree (mcc_mnc) WITH (deduplicate_items='true');


--
-- TOC entry 6954 (class 1259 OID 1728470)
-- Name: idx_stats_couv_communes_techno; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stats_couv_communes_techno ON mrm_public.stats_couv_communes USING btree (techno) WITH (deduplicate_items='true');


--
-- TOC entry 6957 (class 1259 OID 1728471)
-- Name: idx_stats_couv_departements_mcc_mnc; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stats_couv_departements_mcc_mnc ON mrm_public.stats_couv_departements USING btree (mcc_mnc) WITH (deduplicate_items='true');


--
-- TOC entry 6958 (class 1259 OID 1728472)
-- Name: idx_stats_couv_departements_techno; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stats_couv_departements_techno ON mrm_public.stats_couv_departements USING btree (techno) WITH (deduplicate_items='true');


--
-- TOC entry 6961 (class 1259 OID 1728473)
-- Name: idx_stats_couv_regions_mcc_mnc; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stats_couv_regions_mcc_mnc ON mrm_public.stats_couv_regions USING btree (mcc_mnc) WITH (deduplicate_items='true');


--
-- TOC entry 6962 (class 1259 OID 1728474)
-- Name: idx_stats_couv_regions_techno; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stats_couv_regions_techno ON mrm_public.stats_couv_regions USING btree (techno) WITH (deduplicate_items='true');


--
-- TOC entry 6965 (class 1259 OID 1728475)
-- Name: idx_stats_couv_territoires_mcc_mnc; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stats_couv_territoires_mcc_mnc ON mrm_public.stats_couv_territoires USING btree (mcc_mnc) WITH (deduplicate_items='true');


--
-- TOC entry 6966 (class 1259 OID 1728476)
-- Name: idx_stats_couv_territoires_techno; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stats_couv_territoires_techno ON mrm_public.stats_couv_territoires USING btree (techno) WITH (deduplicate_items='true');


--
-- TOC entry 6969 (class 1259 OID 1728477)
-- Name: idx_stats_nbope_couverture_code; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stats_nbope_couverture_code ON mrm_public.stats_nbope_couverture USING btree (code) WITH (deduplicate_items='true');


--
-- TOC entry 6970 (class 1259 OID 1728478)
-- Name: idx_stats_nbope_couverture_techno; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX idx_stats_nbope_couverture_techno ON mrm_public.stats_nbope_couverture USING btree (techno) WITH (deduplicate_items='true');


--
-- TOC entry 6820 (class 1259 OID 1728479)
-- Name: ix_mrm_last_anfr_sup_antenne_fid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_antenne_fid ON mrm_public.anfr_sup_antenne USING btree (fid);


--
-- TOC entry 6823 (class 1259 OID 1728480)
-- Name: ix_mrm_last_anfr_sup_bande_fid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_bande_fid ON mrm_public.anfr_sup_bande USING btree (fid);


--
-- TOC entry 6826 (class 1259 OID 1728481)
-- Name: ix_mrm_last_anfr_sup_emetteur_fid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_emetteur_fid ON mrm_public.anfr_sup_emetteur USING btree (fid);


--
-- TOC entry 6831 (class 1259 OID 1728482)
-- Name: ix_mrm_last_anfr_sup_station_fid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_station_fid ON mrm_public.anfr_sup_station USING btree (fid);


--
-- TOC entry 6837 (class 1259 OID 1728483)
-- Name: ix_mrm_last_anfr_sup_support_fid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_support_fid ON mrm_public.anfr_sup_support USING btree (fid);


--
-- TOC entry 6838 (class 1259 OID 1728484)
-- Name: ix_mrm_last_anfr_sup_support_sta_nm_anfr; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_anfr_sup_support_sta_nm_anfr ON mrm_public.anfr_sup_support USING btree (sta_nm_anfr);


--
-- TOC entry 6843 (class 1259 OID 1728485)
-- Name: ix_mrm_last_commune_geom; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_commune_geom ON mrm_public.commune USING gist (geom) WITH (buffering=auto);


--
-- TOC entry 6844 (class 1259 OID 1728486)
-- Name: ix_mrm_last_commune_gid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_commune_gid ON mrm_public.commune USING btree (gid);


--
-- TOC entry 6845 (class 1259 OID 1728487)
-- Name: ix_mrm_last_commune_insee_com; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_commune_insee_com ON mrm_public.commune USING btree (insee_com) WITH (deduplicate_items='true');


--
-- TOC entry 6846 (class 1259 OID 1728488)
-- Name: ix_mrm_last_commune_nom; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_commune_nom ON mrm_public.commune USING btree (nom);


--
-- TOC entry 6860 (class 1259 OID 1728489)
-- Name: ix_mrm_last_departement_gid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE UNIQUE INDEX ix_mrm_last_departement_gid ON mrm_public.departement USING btree (gid) WITH (deduplicate_items='true');


--
-- TOC entry 6921 (class 1259 OID 1728490)
-- Name: ix_mrm_last_site_fid; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_site_fid ON mrm_public.site USING btree (fid);


--
-- TOC entry 6922 (class 1259 OID 1728491)
-- Name: ix_mrm_last_site_id_station_anfr; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX ix_mrm_last_site_id_station_anfr ON mrm_public.site USING btree (id_station_anfr);


--
-- TOC entry 6893 (class 1259 OID 1728492)
-- Name: qos_axis_name_search_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX qos_axis_name_search_idx ON mrm_public.qos USING gin (axis_name_search public.gin_trgm_ops);


--
-- TOC entry 6898 (class 1259 OID 1728493)
-- Name: qos_categorie_transport_axis_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX qos_categorie_transport_axis_idx ON mrm_public.qos_categorie_transport USING gin (axis public.gin_trgm_ops);


--
-- TOC entry 6899 (class 1259 OID 1728494)
-- Name: qos_categorie_transport_axis_name_search_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX qos_categorie_transport_axis_name_search_idx ON mrm_public.qos_categorie_transport USING gin (axis_name_search public.gin_trgm_ops);


--
-- TOC entry 6894 (class 1259 OID 1728495)
-- Name: qos_geometry_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX qos_geometry_idx ON mrm_public.qos USING gist (geometry);


--
-- TOC entry 6895 (class 1259 OID 1728496)
-- Name: qos_mcc_mnc_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX qos_mcc_mnc_idx ON mrm_public.qos USING btree (mcc_mnc) WITH (deduplicate_items='true');


--
-- TOC entry 6915 (class 1259 OID 1728504)
-- Name: region_geom_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX region_geom_idx ON mrm_public.region USING gist (geom);


--
-- TOC entry 6923 (class 1259 OID 1728505)
-- Name: site_code_op_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX site_code_op_idx ON mrm_public.site USING btree (code_op);


--
-- TOC entry 6926 (class 1259 OID 1728511)
-- Name: site_sup_id_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX site_sup_id_idx ON mrm_public.site USING btree (sup_id);


--
-- TOC entry 6987 (class 1259 OID 1728520)
-- Name: tiles_cache_couverture_tbc_xyzt_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX tiles_cache_couverture_tbc_xyzt_idx ON mrm_public.tiles_cache_couverture_tbc USING btree (z, x, y, techno);


--
-- TOC entry 6984 (class 1259 OID 1728521)
-- Name: tiles_cache_couverture_xyzot_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX tiles_cache_couverture_xyzot_idx ON mrm_public.tiles_cache_couverture USING btree (z, x, y, operateur, techno);


--
-- TOC entry 6979 (class 1259 OID 1728522)
-- Name: tiles_cache_xyzot_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX tiles_cache_xyzot_idx ON mrm_public.tiles_cache USING btree (z, x, y, operateur, techno);


--
-- TOC entry 6988 (class 1259 OID 1728523)
-- Name: zac_axe_ferre_geom_geom_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX zac_axe_ferre_geom_geom_idx ON mrm_public.zac_axe_ferre_old USING gist (geometry);


--
-- TOC entry 6991 (class 1259 OID 1728524)
-- Name: zac_axe_routier_principale_geom_geom_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX zac_axe_routier_principale_geom_geom_idx ON mrm_public.zac_axe_routier_prioritaire_5g_old USING gist (geometry);


--
-- TOC entry 6994 (class 1259 OID 1728525)
-- Name: zac_axe_routier_prioritaire_geom_geom_idx; Type: INDEX; Schema: mrm_public; Owner: -
--

CREATE INDEX zac_axe_routier_prioritaire_geom_geom_idx ON mrm_public.zac_axe_routier_prioritaire_old USING gist (geometry);


--
-- TOC entry 6362 (class 1259 OID 1051170)
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- TOC entry 6367 (class 1259 OID 1051171)
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- TOC entry 6370 (class 1259 OID 1051172)
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- TOC entry 6373 (class 1259 OID 1051173)
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- TOC entry 6378 (class 1259 OID 1051174)
-- Name: axes_accessattempt_ip_address_10922d9c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accessattempt_ip_address_10922d9c ON public.axes_accessattempt USING btree (ip_address);


--
-- TOC entry 6381 (class 1259 OID 1051175)
-- Name: axes_accessattempt_user_agent_ad89678b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accessattempt_user_agent_ad89678b ON public.axes_accessattempt USING btree (user_agent);


--
-- TOC entry 6382 (class 1259 OID 1051176)
-- Name: axes_accessattempt_user_agent_ad89678b_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accessattempt_user_agent_ad89678b_like ON public.axes_accessattempt USING btree (user_agent varchar_pattern_ops);


--
-- TOC entry 6383 (class 1259 OID 1051177)
-- Name: axes_accessattempt_username_3f2d4ca0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accessattempt_username_3f2d4ca0 ON public.axes_accessattempt USING btree (username);


--
-- TOC entry 6384 (class 1259 OID 1051178)
-- Name: axes_accessattempt_username_3f2d4ca0_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accessattempt_username_3f2d4ca0_like ON public.axes_accessattempt USING btree (username varchar_pattern_ops);


--
-- TOC entry 6387 (class 1259 OID 1051179)
-- Name: axes_accessfailurelog_ip_address_2e9f5a7f; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accessfailurelog_ip_address_2e9f5a7f ON public.axes_accessfailurelog USING btree (ip_address);


--
-- TOC entry 6390 (class 1259 OID 1051180)
-- Name: axes_accessfailurelog_user_agent_ea145dda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accessfailurelog_user_agent_ea145dda ON public.axes_accessfailurelog USING btree (user_agent);


--
-- TOC entry 6391 (class 1259 OID 1051181)
-- Name: axes_accessfailurelog_user_agent_ea145dda_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accessfailurelog_user_agent_ea145dda_like ON public.axes_accessfailurelog USING btree (user_agent varchar_pattern_ops);


--
-- TOC entry 6392 (class 1259 OID 1051182)
-- Name: axes_accessfailurelog_username_a8b7e8a4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accessfailurelog_username_a8b7e8a4 ON public.axes_accessfailurelog USING btree (username);


--
-- TOC entry 6393 (class 1259 OID 1051183)
-- Name: axes_accessfailurelog_username_a8b7e8a4_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accessfailurelog_username_a8b7e8a4_like ON public.axes_accessfailurelog USING btree (username varchar_pattern_ops);


--
-- TOC entry 6394 (class 1259 OID 1051184)
-- Name: axes_accesslog_ip_address_86b417e5; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accesslog_ip_address_86b417e5 ON public.axes_accesslog USING btree (ip_address);


--
-- TOC entry 6397 (class 1259 OID 1051185)
-- Name: axes_accesslog_user_agent_0e659004; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accesslog_user_agent_0e659004 ON public.axes_accesslog USING btree (user_agent);


--
-- TOC entry 6398 (class 1259 OID 1051186)
-- Name: axes_accesslog_user_agent_0e659004_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accesslog_user_agent_0e659004_like ON public.axes_accesslog USING btree (user_agent varchar_pattern_ops);


--
-- TOC entry 6399 (class 1259 OID 1051187)
-- Name: axes_accesslog_username_df93064b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accesslog_username_df93064b ON public.axes_accesslog USING btree (username);


--
-- TOC entry 6400 (class 1259 OID 1051188)
-- Name: axes_accesslog_username_df93064b_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX axes_accesslog_username_df93064b_like ON public.axes_accesslog USING btree (username varchar_pattern_ops);


--
-- TOC entry 6401 (class 1259 OID 1051189)
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- TOC entry 6404 (class 1259 OID 1051190)
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- TOC entry 6411 (class 1259 OID 1051191)
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- TOC entry 6414 (class 1259 OID 1051192)
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- TOC entry 6426 (class 1259 OID 1051193)
-- Name: users_groups_group_id_2f3517aa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_groups_group_id_2f3517aa ON public.users_groups USING btree (group_id);


--
-- TOC entry 6429 (class 1259 OID 1051194)
-- Name: users_groups_user_id_f500bee5; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_groups_user_id_f500bee5 ON public.users_groups USING btree (user_id);


--
-- TOC entry 6432 (class 1259 OID 1051195)
-- Name: users_user_permissions_permission_id_6d08dcd2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_user_permissions_permission_id_6d08dcd2 ON public.users_user_permissions USING btree (permission_id);


--
-- TOC entry 6435 (class 1259 OID 1051196)
-- Name: users_user_permissions_user_id_92473840; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_user_permissions_user_id_92473840 ON public.users_user_permissions USING btree (user_id);


--
-- TOC entry 6423 (class 1259 OID 1051197)
-- Name: users_username_e8658fc8_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_username_e8658fc8_like ON public.users USING btree (username varchar_pattern_ops);


--
-- TOC entry 7216 (class 2606 OID 1806362)
-- Name: anfr_sup_support_log fk_anfr_sup_support_log_departement; Type: FK CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.anfr_sup_support_log
    ADD CONSTRAINT fk_anfr_sup_support_log_departement FOREIGN KEY (id_departement) REFERENCES mrm_private.departement(gid);


--
-- TOC entry 7217 (class 2606 OID 1806367)
-- Name: qos fk_qos_id_data_source_desc; Type: FK CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos
    ADD CONSTRAINT fk_qos_id_data_source_desc FOREIGN KEY (id_data_source_desc) REFERENCES mrm_private.qos_data_source_desc(id) NOT VALID;


--
-- TOC entry 7218 (class 2606 OID 1806372)
-- Name: qos fk_qos_mcc_mnc; Type: FK CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.qos
    ADD CONSTRAINT fk_qos_mcc_mnc FOREIGN KEY (mcc_mnc) REFERENCES public.operateurs(identifiant) NOT VALID;


--
-- TOC entry 7215 (class 2606 OID 1806377)
-- Name: anfr_sup_support fk_support_departement; Type: FK CONSTRAINT; Schema: mrm_private; Owner: -
--

ALTER TABLE ONLY mrm_private.anfr_sup_support
    ADD CONSTRAINT fk_support_departement FOREIGN KEY (id_departement) REFERENCES mrm_private.departement(gid) NOT VALID;


--
-- TOC entry 7212 (class 2606 OID 1728526)
-- Name: anfr_sup_support_log fk_anfr_sup_support_log_departement; Type: FK CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.anfr_sup_support_log
    ADD CONSTRAINT fk_anfr_sup_support_log_departement FOREIGN KEY (id_departement) REFERENCES mrm_public.departement(gid);


--
-- TOC entry 7213 (class 2606 OID 1728531)
-- Name: qos fk_qos_id_data_source_desc; Type: FK CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos
    ADD CONSTRAINT fk_qos_id_data_source_desc FOREIGN KEY (id_data_source_desc) REFERENCES mrm_public.qos_data_source_desc(id) NOT VALID;


--
-- TOC entry 7214 (class 2606 OID 1728536)
-- Name: qos fk_qos_mcc_mnc; Type: FK CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.qos
    ADD CONSTRAINT fk_qos_mcc_mnc FOREIGN KEY (mcc_mnc) REFERENCES public.operateurs(identifiant) NOT VALID;


--
-- TOC entry 7211 (class 2606 OID 1728541)
-- Name: anfr_sup_support fk_support_departement; Type: FK CONSTRAINT; Schema: mrm_public; Owner: -
--

ALTER TABLE ONLY mrm_public.anfr_sup_support
    ADD CONSTRAINT fk_support_departement FOREIGN KEY (id_departement) REFERENCES mrm_public.departement(gid) NOT VALID;


--
-- TOC entry 7194 (class 2606 OID 1051278)
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 7195 (class 2606 OID 1051283)
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 7196 (class 2606 OID 1051288)
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 7197 (class 2606 OID 1051293)
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 7198 (class 2606 OID 1051298)
-- Name: django_admin_log django_admin_log_user_id_c564eba6_fk_users_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_users_id FOREIGN KEY (user_id) REFERENCES public.users(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 7199 (class 2606 OID 1051303)
-- Name: users_groups users_groups_group_id_2f3517aa_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_groups
    ADD CONSTRAINT users_groups_group_id_2f3517aa_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 7200 (class 2606 OID 1051308)
-- Name: users_groups users_groups_user_id_f500bee5_fk_users_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_groups
    ADD CONSTRAINT users_groups_user_id_f500bee5_fk_users_id FOREIGN KEY (user_id) REFERENCES public.users(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 7201 (class 2606 OID 1051313)
-- Name: users_user_permissions users_user_permissio_permission_id_6d08dcd2_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_user_permissions
    ADD CONSTRAINT users_user_permissio_permission_id_6d08dcd2_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 7202 (class 2606 OID 1051318)
-- Name: users_user_permissions users_user_permissions_user_id_92473840_fk_users_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_user_permissions
    ADD CONSTRAINT users_user_permissions_user_id_92473840_fk_users_id FOREIGN KEY (user_id) REFERENCES public.users(id) DEFERRABLE INITIALLY DEFERRED;


-- Completed on 2026-07-02 14:22:09 CEST

--
-- PostgreSQL database dump complete
--

\unrestrict ztDR9eryx7GgGH9dMtPH6Xtx1S3e60yOhaucfAicJwgrCOujm6gafeGY6a6udDm

