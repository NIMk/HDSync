bin_PROGRAMS = netcat broadcaster hdsync avremote

netcat_SOURCES = \
	core.c \
	flagset.c \
	misc.c \
	netcat.c \
	network.c \
	telnet.c \
	udphelper.c

broadcaster_SOURCES = broadcaster.cpp

hdsync_SOURCES = avremote.c avremote.h hdsync_cli.c parsers.c parsers.h

avremote_SOURCES = avremote.c avremote.h avremote_cli.c parsers.c parsers.h

netcat_nc = $(DESTDIR)$(bindir)/nc

install-exec-hook:
	@if [ ! -L $(netcat_nc) -a ! -e $(netcat_nc) ]; then \
		echo "Creating symlink to the shorter executable name"; \
		ln -s netcat $(netcat_nc); \
	fi

uninstall-hook:
	@if [ -L $(netcat_nc) ]; then \
		echo "Removing symlink to the shorter executable name"; \
		rm -f $(netcat_nc); \
	fi
