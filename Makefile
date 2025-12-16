CFLAGS += -std=c99 -g -Wall

# Allow overriding libmagic location via environment
LIBMAGIC_PREFIX ?=

# Auto-detect Homebrew libmagic on macOS if not specified
ifeq ($(LIBMAGIC_PREFIX),)
  UNAME_S := $(shell uname -s)
  ifeq ($(UNAME_S),Darwin)
    LIBMAGIC_PREFIX := $(shell brew --prefix libmagic 2>/dev/null)
  endif
endif

# Build include/lib paths - always include /usr/local as fallback
CPPFLAGS += -I$(ERL_EI_INCLUDE_DIR) -I/usr/local/include
LDFLAGS += -L$(ERL_EI_LIBDIR) -L/usr/local/lib

# Add Homebrew paths if detected
ifneq ($(LIBMAGIC_PREFIX),)
  CPPFLAGS += -I$(LIBMAGIC_PREFIX)/include
  LDFLAGS += -L$(LIBMAGIC_PREFIX)/lib
endif
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
