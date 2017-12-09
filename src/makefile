SHELL=/bin/bash
CFLAGS=--std=c99

prefix=/usr
bindir=$(prefix)/bin
sharedir=$(prefix)/share
localedir=$(sharedir)/locale
launcherdir=$(sharedir)/applications
mandir=$(sharedir)/man
man1dir=$(mandir)/man1

app_name=sanity

extralibpath = -X -Wl,-rpath,libs

all:

	$(info arch is $(arch))
	
	#binary
	valac  -X -D'GETTEXT_PACKAGE="${app_name}"' --Xcc="-lm" \
		$(extralibpath) \
		--thread \
		${app_name}.vala \
		Utility/TeeJee.FileSystem.vala \
		Utility/TeeJee.Logging.vala \
		Utility/TeeJee.Misc.vala \
		Utility/TeeJee.Process.vala \
		Utility/TeeJee.System.vala \
		-o ${app_name} --pkg glib-2.0 --pkg gio-unix-2.0 --pkg posix --pkg gee-0.8
		#-X -static \

clean:
	rm -rfv ../release/{source,i386,amd64,armel,armhf}
	rm -rfv ../release/*.{run,deb}
	rm -rfv *.c *.o *.mo
	rm -fv ${app_name}
	rm -fv share/${app_name}/files/${app_name}.{i386,amd64}
	
install:

	#dirs
	mkdir -p "$(DESTDIR)$(bindir)"
	mkdir -p "$(DESTDIR)$(sharedir)"
	mkdir -p "$(DESTDIR)$(mandir)"
	mkdir -p "$(DESTDIR)$(man1dir)"
	mkdir -p "$(DESTDIR)$(sharedir)/${app_name}"
	mkdir -p "$(DESTDIR)$(sharedir)/pixmaps"
	mkdir -p "$(DESTDIR)/var/log/${app_name}"
	#mkdir -p "$(DESTDIR)$(localedir)/de/LC_MESSAGES"
	
	#binary
	install -m 0755 ${app_name} "$(DESTDIR)$(bindir)"

	#shared files
	#cp -dpr --no-preserve=ownership -t "$(DESTDIR)$(sharedir)/${app_name}" ./share/${app_name}/*
	#chmod --recursive 0755 $(DESTDIR)$(sharedir)/${app_name}/*

install-all:

	#dirs
	mkdir -p "$(DESTDIR)$(bindir)"
	mkdir -p "$(DESTDIR)$(sharedir)"
	mkdir -p "$(DESTDIR)$(mandir)"
	mkdir -p "$(DESTDIR)$(man1dir)"
	mkdir -p "$(DESTDIR)$(sharedir)/${app_name}"
	mkdir -p "$(DESTDIR)$(sharedir)/pixmaps"
	mkdir -p "$(DESTDIR)/var/log/${app_name}"
	#mkdir -p "$(DESTDIR)$(localedir)/de/LC_MESSAGES"
	
	#binary
	install -m 0755 ${app_name} "$(DESTDIR)$(bindir)"

	#shared files
	cp -dpr --no-preserve=ownership -t "$(DESTDIR)$(sharedir)/${app_name}" ./share/${app_name}/*
	chmod --recursive 0755 $(DESTDIR)$(sharedir)/${app_name}/*
	
uninstall:

	#binary
	rm -f "$(DESTDIR)$(bindir)/${app_name}"

	#shared files
	rm -rf "$(DESTDIR)$(sharedir)/${app_name}"
