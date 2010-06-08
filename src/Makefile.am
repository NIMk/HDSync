bin_PROGRAMS = netcat broadcaster
netcat_SOURCES = \
	core.c \
	flagset.c \
	misc.c \
	netcat.c \
	network.c \
	telnet.c \
	udphelper.c

broadcaster_SOURCES = broadcaster.cpp

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
