
CC = gcc

INCLUDES = /usr/include/bash /usr/include/bash/builtins
DEFINES = _GNU_SOURCE

LIBFLAGS = -shared -fPIC
CWARN = -Wall
COPT = -O0
CDEBUG = -ggdb3
CINCLUDES = $(foreach d,$(INCLUDES),-I$(d))
CDEFINES = $(foreach d,$(DEFINES),-D$(d))

CFLAGS = $(CWARN) $(COPT) $(CINCLUDES) $(CDEFINES) $(LIBFLAGS) $(CDEBUG)

booze.so: booze.c
	$(CC) $(CFLAGS) `pkg-config fuse --cflags --libs` -shared -o $@ $<