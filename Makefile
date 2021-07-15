
CC = gcc

INCLUDES = # /usr/include/bash /usr/include/bash/builtins
# DEFINES = _GNU_SOURCE

LIBFLAGS = -gfull -dynamic -fPIC -bundle -bundle_loader bash
CWARN = -Wall -Wextra
COPT = -O0
ifneq ($(DEBUG),)
	CDEBUG = -ggdb3
else
	CDEBUG =
endif
CINCLUDES = $(foreach d,$(INCLUDES),-I$(d))
CDEFINES = $(foreach d,$(DEFINES),-D$(d))

CFLAGS = $(CWARN) $(COPT) $(CINCLUDES) $(CDEFINES) $(LIBFLAGS) $(CDEBUG)

FUSEFLAGS = $(shell pkg-config fuse --cflags --libs)
BASHFLAGS = $(shell pkg-config bash --cflags --libs)

booze.so: booze.c
	$(CC) -v $(CFLAGS) $(FUSEFLAGS) $(BASHFLAGS) -o $@ $<
