CFLAGS += -std=c99 -g -Wall -Werror
CPPFLAGS += -I$(ERL_EI_INCLUDE_DIR) -I/usr/local/include
LDFLAGS += -L$(ERL_EI_LIBDIR) -L/usr/local/lib
LDLIBS = -lpthread
PRIV = priv/
RM = rm -Rf

ifeq ($(EI_INCOMPLETE),YES)
  LDLIBS += -lerl_interface
  CFLAGS += -DEI_INCOMPLETE
endif

LDLIBS += -lei -lm -lmagic


all: priv/libmagic_port

priv/libmagic_port: src/libmagic_port.c
	mkdir -p priv
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $< $(LDLIBS) -o $@

clean:
	$(RM) $(PRIV)

.PHONY: clean
