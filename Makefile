MODULE_big = pg_bigm
OBJS = bigm_op.o bigm_gin.o

EXTENSION = pg_bigm
DATA = pg_bigm--1.0.sql

REGRESS = pg_bigm

ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = contrib/pg_bigm
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif
