--
-- PostgreSQL database dump
--

\restrict zljJn5Hch4qTCHeQ5xqhExbzxAU7HJRXNbIhOLY1QBgXv1oBwEEXPVxtAb7LMCk

-- Dumped from database version 15.17
-- Dumped by pg_dump version 15.17

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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: cajas_estado_enum; Type: TYPE; Schema: public; Owner: gestouser
--

CREATE TYPE public.cajas_estado_enum AS ENUM (
    'ABIERTA',
    'CERRADA'
);


ALTER TYPE public.cajas_estado_enum OWNER TO gestouser;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auditoria; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.auditoria (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    bar_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    rol_nombre character varying(50) NOT NULL,
    accion character varying(100) NOT NULL,
    modulo character varying(50) NOT NULL,
    detalles jsonb,
    ip_address character varying(45),
    dispositivo character varying(150),
    fecha timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.auditoria OWNER TO gestouser;

--
-- Name: bares; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.bares (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nombre character varying NOT NULL,
    ciudad character varying,
    direccion character varying,
    timezone character varying DEFAULT 'UTC'::character varying NOT NULL,
    moneda_simbolo character varying DEFAULT 'Bs'::character varying NOT NULL,
    moneda_iso character varying DEFAULT 'BOB'::character varying NOT NULL,
    logo_url character varying,
    whatsapp character varying,
    link_ubicacion character varying,
    facebook character varying,
    instagram character varying,
    tiktok character varying,
    slug character varying NOT NULL,
    estado boolean DEFAULT true NOT NULL,
    owner_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    comision_porcentaje numeric(5,2) DEFAULT '50'::numeric NOT NULL
);


ALTER TABLE public.bares OWNER TO gestouser;

--
-- Name: cajas; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.cajas (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    bar_id uuid NOT NULL,
    apertura_usuario_id uuid NOT NULL,
    cierre_usuario_id uuid,
    fecha_apertura timestamp without time zone DEFAULT now() NOT NULL,
    fecha_cierre timestamp without time zone,
    monto_inicial numeric(12,2) NOT NULL,
    monto_final numeric(12,2),
    estado public.cajas_estado_enum DEFAULT 'ABIERTA'::public.cajas_estado_enum NOT NULL
);


ALTER TABLE public.cajas OWNER TO gestouser;

--
-- Name: categorias; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.categorias (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    bar_id uuid NOT NULL,
    nombre character varying NOT NULL,
    orden integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.categorias OWNER TO gestouser;

--
-- Name: detalle_ventas; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.detalle_ventas (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    venta_id uuid NOT NULL,
    variante_id uuid NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(12,2) NOT NULL,
    es_precio_b boolean DEFAULT false NOT NULL,
    dama_id uuid,
    comision_dama numeric(12,2) DEFAULT '0'::numeric NOT NULL,
    es_invitacion boolean DEFAULT false NOT NULL
);


ALTER TABLE public.detalle_ventas OWNER TO gestouser;

--
-- Name: permisos; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.permisos (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE public.permisos OWNER TO gestouser;

--
-- Name: productos; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.productos (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    bar_id uuid NOT NULL,
    categoria_id uuid NOT NULL,
    foto_url character varying,
    nombre character varying NOT NULL,
    descripcion character varying
);


ALTER TABLE public.productos OWNER TO gestouser;

--
-- Name: rol_permisos; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.rol_permisos (
    rol_id uuid NOT NULL,
    permiso_id uuid NOT NULL
);


ALTER TABLE public.rol_permisos OWNER TO gestouser;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    bar_id uuid,
    nombre character varying NOT NULL
);


ALTER TABLE public.roles OWNER TO gestouser;

--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.usuarios (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    username character varying NOT NULL,
    password character varying NOT NULL,
    foto_url character varying,
    nombre character varying NOT NULL,
    apellido character varying NOT NULL,
    identificacion character varying,
    nacionalidad character varying,
    celular character varying,
    direccion character varying,
    estado boolean DEFAULT true NOT NULL,
    rol_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    bar_id uuid
);


ALTER TABLE public.usuarios OWNER TO gestouser;

--
-- Name: variantes; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.variantes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    producto_id uuid NOT NULL,
    nombre character varying NOT NULL,
    precio_a numeric(12,2) NOT NULL,
    precio_b numeric(12,2) NOT NULL,
    disponible boolean DEFAULT true NOT NULL
);


ALTER TABLE public.variantes OWNER TO gestouser;

--
-- Name: ventas; Type: TABLE; Schema: public; Owner: gestouser
--

CREATE TABLE public.ventas (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    bar_id uuid NOT NULL,
    caja_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    total numeric(12,2) NOT NULL,
    metodo_pago character varying(50) NOT NULL,
    fecha timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.ventas OWNER TO gestouser;

--
-- Data for Name: auditoria; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.auditoria (id, bar_id, usuario_id, rol_nombre, accion, modulo, detalles, ip_address, dispositivo, fecha) FROM stdin;
\.


--
-- Data for Name: bares; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.bares (id, nombre, ciudad, direccion, timezone, moneda_simbolo, moneda_iso, logo_url, whatsapp, link_ubicacion, facebook, instagram, tiktok, slug, estado, owner_id, created_at, comision_porcentaje) FROM stdin;
9e12552b-ffa8-45d2-a3d5-67a2830e4173	El Templo del Oro	Santa Cruz	Av. San Martín, Equipetrol	America/La_Paz	Bs	BOB	\N	\N	\N	\N	\N	\N	templo-oro	t	751e80e5-77ce-4e9c-92cd-b70b160244fd	2026-05-17 02:47:50.614844	50.00
\.


--
-- Data for Name: cajas; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.cajas (id, bar_id, apertura_usuario_id, cierre_usuario_id, fecha_apertura, fecha_cierre, monto_inicial, monto_final, estado) FROM stdin;
\.


--
-- Data for Name: categorias; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.categorias (id, bar_id, nombre, orden) FROM stdin;
\.


--
-- Data for Name: detalle_ventas; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.detalle_ventas (id, venta_id, variante_id, cantidad, precio_unitario, es_precio_b, dama_id, comision_dama, es_invitacion) FROM stdin;
\.


--
-- Data for Name: permisos; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.permisos (id, nombre) FROM stdin;
1f9f4519-9693-467e-8944-21a8ed1877bd	bares.gestionar
8cc0b097-050d-490b-8e48-4b0425c067ad	usuarios.gestionar
d379b427-2ba4-4434-b9a7-05e65d35cd2e	roles.gestionar
023e8626-d471-4558-9db9-0a35dc23a1df	productos.gestionar
fad97f26-7bb8-461f-a62f-f70e7d42d403	ventas.registrar
e6015689-59c9-4212-98d4-5845426cd210	caja.gestionar
77da4783-487f-474f-8ec0-bcf5e3004c08	comisiones.ver_propias
3cf2bd61-fd35-4792-8ff6-8feaea80f85a	reportes.ver
ae3f0dc2-3f04-4918-8852-b4d73922bf41	revision.lectura
\.


--
-- Data for Name: productos; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.productos (id, bar_id, categoria_id, foto_url, nombre, descripcion) FROM stdin;
\.


--
-- Data for Name: rol_permisos; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.rol_permisos (rol_id, permiso_id) FROM stdin;
9b8da945-4c25-4114-a9b3-94bf177e530c	1f9f4519-9693-467e-8944-21a8ed1877bd
9b8da945-4c25-4114-a9b3-94bf177e530c	8cc0b097-050d-490b-8e48-4b0425c067ad
9b8da945-4c25-4114-a9b3-94bf177e530c	3cf2bd61-fd35-4792-8ff6-8feaea80f85a
f323aea6-a46b-4fd3-891c-dcc6587b8031	8cc0b097-050d-490b-8e48-4b0425c067ad
f323aea6-a46b-4fd3-891c-dcc6587b8031	d379b427-2ba4-4434-b9a7-05e65d35cd2e
f323aea6-a46b-4fd3-891c-dcc6587b8031	023e8626-d471-4558-9db9-0a35dc23a1df
f323aea6-a46b-4fd3-891c-dcc6587b8031	e6015689-59c9-4212-98d4-5845426cd210
f323aea6-a46b-4fd3-891c-dcc6587b8031	3cf2bd61-fd35-4792-8ff6-8feaea80f85a
ce1cae0a-2ef4-4aa0-9320-796775523508	fad97f26-7bb8-461f-a62f-f70e7d42d403
ce1cae0a-2ef4-4aa0-9320-796775523508	e6015689-59c9-4212-98d4-5845426cd210
58b59a57-c558-4cf8-99f5-4ba2df1e723f	77da4783-487f-474f-8ec0-bcf5e3004c08
36f19cf2-6f3f-4456-87d7-686aa2024a32	ae3f0dc2-3f04-4918-8852-b4d73922bf41
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.roles (id, bar_id, nombre) FROM stdin;
9b8da945-4c25-4114-a9b3-94bf177e530c	\N	SUPERADMIN
f323aea6-a46b-4fd3-891c-dcc6587b8031	\N	ADMIN
ce1cae0a-2ef4-4aa0-9320-796775523508	\N	BARMAN
58b59a57-c558-4cf8-99f5-4ba2df1e723f	\N	DAMA
36f19cf2-6f3f-4456-87d7-686aa2024a32	\N	REVIEWER
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.usuarios (id, username, password, foto_url, nombre, apellido, identificacion, nacionalidad, celular, direccion, estado, rol_id, created_at, bar_id) FROM stdin;
751e80e5-77ce-4e9c-92cd-b70b160244fd	superadmin	$2b$10$vPdTu9v88uLVamBMV5h2KOjhCknINa7ZrrhDixA2XJ9cukd1VINM2	\N	Super	Admin	\N	\N	\N	\N	t	9b8da945-4c25-4114-a9b3-94bf177e530c	2026-05-17 02:47:50.565564	\N
b7ce59c3-eefd-4309-816c-e1761c58efaf	admin	$2b$10$n7YSxJYoKz3ylzGLUo4.f.hOuZM33Qfy7xmN0ZwGOD91Kh1U1pS4K	\N	Juan	Administrador	\N	\N	\N	\N	t	f323aea6-a46b-4fd3-891c-dcc6587b8031	2026-05-17 02:47:50.681195	9e12552b-ffa8-45d2-a3d5-67a2830e4173
b9a01ecc-0080-45e9-917b-749fa444c672	barman	$2b$10$1DRv73jAVtmlBsAc9/.YGempTMLRG4yt/SaHzLK/crG30npFwRyui	\N	Carlos	Cajero	\N	\N	\N	\N	t	ce1cae0a-2ef4-4aa0-9320-796775523508	2026-05-17 02:47:50.738464	9e12552b-ffa8-45d2-a3d5-67a2830e4173
17dfe6dd-fc90-40db-8143-c493a4352994	dama	$2b$10$xKj85JEDICf7aTHbDcIjku6p49/qN3NXeOLppeX9bAD6FqFjQ3eEm	\N	Gabriela	Compañía	\N	\N	77012345	\N	t	58b59a57-c558-4cf8-99f5-4ba2df1e723f	2026-05-17 02:47:50.795381	9e12552b-ffa8-45d2-a3d5-67a2830e4173
\.


--
-- Data for Name: variantes; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.variantes (id, producto_id, nombre, precio_a, precio_b, disponible) FROM stdin;
\.


--
-- Data for Name: ventas; Type: TABLE DATA; Schema: public; Owner: gestouser
--

COPY public.ventas (id, bar_id, caja_id, usuario_id, total, metodo_pago, fecha) FROM stdin;
\.


--
-- Name: productos PK_04f604609a0949a7f3b43400766; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT "PK_04f604609a0949a7f3b43400766" PRIMARY KEY (id);


--
-- Name: variantes PK_1167a190c8965c02f8c406d7d88; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.variantes
    ADD CONSTRAINT "PK_1167a190c8965c02f8c406d7d88" PRIMARY KEY (id);


--
-- Name: auditoria PK_135fe98308816fe3a2d458e6637; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT "PK_135fe98308816fe3a2d458e6637" PRIMARY KEY (id);


--
-- Name: permisos PK_3127bd9cfeb13ae76186d0d9b38; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT "PK_3127bd9cfeb13ae76186d0d9b38" PRIMARY KEY (id);


--
-- Name: categorias PK_3886a26251605c571c6b4f861fe; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT "PK_3886a26251605c571c6b4f861fe" PRIMARY KEY (id);


--
-- Name: detalle_ventas PK_3f017a7ffaa120b5fad5990521d; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.detalle_ventas
    ADD CONSTRAINT "PK_3f017a7ffaa120b5fad5990521d" PRIMARY KEY (id);


--
-- Name: cajas PK_92b27e5f4ab36a544f37bf45e09; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.cajas
    ADD CONSTRAINT "PK_92b27e5f4ab36a544f37bf45e09" PRIMARY KEY (id);


--
-- Name: bares PK_a781660e1b54c86e7bcde68c51a; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.bares
    ADD CONSTRAINT "PK_a781660e1b54c86e7bcde68c51a" PRIMARY KEY (id);


--
-- Name: ventas PK_b8b73abe8561829c019531d9a2e; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT "PK_b8b73abe8561829c019531d9a2e" PRIMARY KEY (id);


--
-- Name: roles PK_c1433d71a4838793a49dcad46ab; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT "PK_c1433d71a4838793a49dcad46ab" PRIMARY KEY (id);


--
-- Name: rol_permisos PK_d0cf98bfca05b7f290ea73bd734; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.rol_permisos
    ADD CONSTRAINT "PK_d0cf98bfca05b7f290ea73bd734" PRIMARY KEY (rol_id, permiso_id);


--
-- Name: usuarios PK_d7281c63c176e152e4c531594a8; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT "PK_d7281c63c176e152e4c531594a8" PRIMARY KEY (id);


--
-- Name: permisos UQ_0fea7aa2110562d76c2bc927eae; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT "UQ_0fea7aa2110562d76c2bc927eae" UNIQUE (nombre);


--
-- Name: usuarios UQ_9f78cfde576fc28f279e2b7a9cb; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT "UQ_9f78cfde576fc28f279e2b7a9cb" UNIQUE (username);


--
-- Name: bares UQ_c42428b5e920c01a2ebf5a1d3e2; Type: CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.bares
    ADD CONSTRAINT "UQ_c42428b5e920c01a2ebf5a1d3e2" UNIQUE (slug);


--
-- Name: IDX_25e38115872406619b03e46cce; Type: INDEX; Schema: public; Owner: gestouser
--

CREATE INDEX "IDX_25e38115872406619b03e46cce" ON public.rol_permisos USING btree (permiso_id);


--
-- Name: IDX_4d6354d8c6fecd074abd3183f4; Type: INDEX; Schema: public; Owner: gestouser
--

CREATE INDEX "IDX_4d6354d8c6fecd074abd3183f4" ON public.rol_permisos USING btree (rol_id);


--
-- Name: rol_permisos FK_25e38115872406619b03e46cced; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.rol_permisos
    ADD CONSTRAINT "FK_25e38115872406619b03e46cced" FOREIGN KEY (permiso_id) REFERENCES public.permisos(id);


--
-- Name: auditoria FK_2e21e19afb55c47c71244f671d4; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT "FK_2e21e19afb55c47c71244f671d4" FOREIGN KEY (bar_id) REFERENCES public.bares(id) ON DELETE CASCADE;


--
-- Name: roles FK_3d1c77e91d15ce0c606f4b31ea8; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT "FK_3d1c77e91d15ce0c606f4b31ea8" FOREIGN KEY (bar_id) REFERENCES public.bares(id);


--
-- Name: rol_permisos FK_4d6354d8c6fecd074abd3183f40; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.rol_permisos
    ADD CONSTRAINT "FK_4d6354d8c6fecd074abd3183f40" FOREIGN KEY (rol_id) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: productos FK_5aaee6054b643e7c778477193a3; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT "FK_5aaee6054b643e7c778477193a3" FOREIGN KEY (categoria_id) REFERENCES public.categorias(id) ON DELETE RESTRICT;


--
-- Name: ventas FK_5c564fe8d2b5182a37211405827; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT "FK_5c564fe8d2b5182a37211405827" FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: productos FK_6b431a714e6efb78968b5784221; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT "FK_6b431a714e6efb78968b5784221" FOREIGN KEY (bar_id) REFERENCES public.bares(id) ON DELETE CASCADE;


--
-- Name: categorias FK_7f19b1c7d055e0cbf8435fe256e; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT "FK_7f19b1c7d055e0cbf8435fe256e" FOREIGN KEY (bar_id) REFERENCES public.bares(id) ON DELETE CASCADE;


--
-- Name: variantes FK_88c6aba4ba24923828e09cbac6d; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.variantes
    ADD CONSTRAINT "FK_88c6aba4ba24923828e09cbac6d" FOREIGN KEY (producto_id) REFERENCES public.productos(id) ON DELETE CASCADE;


--
-- Name: cajas FK_9b47de721e4923b5116952d949e; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.cajas
    ADD CONSTRAINT "FK_9b47de721e4923b5116952d949e" FOREIGN KEY (bar_id) REFERENCES public.bares(id) ON DELETE CASCADE;


--
-- Name: usuarios FK_9e519760a660751f4fa21453d3e; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT "FK_9e519760a660751f4fa21453d3e" FOREIGN KEY (rol_id) REFERENCES public.roles(id);


--
-- Name: ventas FK_a5ef18f1e91c2709fb99dd03d5a; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT "FK_a5ef18f1e91c2709fb99dd03d5a" FOREIGN KEY (caja_id) REFERENCES public.cajas(id);


--
-- Name: cajas FK_a809fbccfe188fb7dbe0258ab18; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.cajas
    ADD CONSTRAINT "FK_a809fbccfe188fb7dbe0258ab18" FOREIGN KEY (cierre_usuario_id) REFERENCES public.usuarios(id);


--
-- Name: detalle_ventas FK_b579b8c4a3df0233c963c20548f; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.detalle_ventas
    ADD CONSTRAINT "FK_b579b8c4a3df0233c963c20548f" FOREIGN KEY (variante_id) REFERENCES public.variantes(id);


--
-- Name: cajas FK_be010fa0fec48671d74aebf0cfc; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.cajas
    ADD CONSTRAINT "FK_be010fa0fec48671d74aebf0cfc" FOREIGN KEY (apertura_usuario_id) REFERENCES public.usuarios(id);


--
-- Name: bares FK_c26e0c5bd289c2c64fdc1f2e4e9; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.bares
    ADD CONSTRAINT "FK_c26e0c5bd289c2c64fdc1f2e4e9" FOREIGN KEY (owner_id) REFERENCES public.usuarios(id);


--
-- Name: ventas FK_d3b5404a7ee2bba772f40bedab3; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT "FK_d3b5404a7ee2bba772f40bedab3" FOREIGN KEY (bar_id) REFERENCES public.bares(id);


--
-- Name: auditoria FK_e3351946be53c7cd3286ed4c49d; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT "FK_e3351946be53c7cd3286ed4c49d" FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;


--
-- Name: detalle_ventas FK_ebfe4ddaa56d1a98410cb4b7f67; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.detalle_ventas
    ADD CONSTRAINT "FK_ebfe4ddaa56d1a98410cb4b7f67" FOREIGN KEY (venta_id) REFERENCES public.ventas(id) ON DELETE CASCADE;


--
-- Name: detalle_ventas FK_ed0e5697c2045d5bd9c332096b6; Type: FK CONSTRAINT; Schema: public; Owner: gestouser
--

ALTER TABLE ONLY public.detalle_ventas
    ADD CONSTRAINT "FK_ed0e5697c2045d5bd9c332096b6" FOREIGN KEY (dama_id) REFERENCES public.usuarios(id);


--
-- PostgreSQL database dump complete
--

\unrestrict zljJn5Hch4qTCHeQ5xqhExbzxAU7HJRXNbIhOLY1QBgXv1oBwEEXPVxtAb7LMCk

