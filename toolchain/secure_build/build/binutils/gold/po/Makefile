# Makefile for program source directory in GNU NLS utilities package.
# Copyright (C) 1995, 1996, 1997 by Ulrich Drepper <drepper@gnu.ai.mit.edu>
# Copyright 2003, 2006, 2007, 2009 Free Software Foundation, Inc.
#
# This file may be copied and used freely without restrictions.  It can
# be used in projects which are not available under the GNU Public License
# but which still want to provide support for the GNU gettext functionality.
# Please note that the actual code is *not* freely available.

PACKAGE = gold
VERSION = 0.1

SHELL = /bin/sh


srcdir = /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/po
top_srcdir = /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold
VPATH = /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/po
top_builddir = ..

prefix = /home/freddie/JohnOfPatmos/toolchain/secure_build/toolchain
exec_prefix = ${prefix}
datadir = $(prefix)/
localedir = $(datadir)/locale
gnulocaledir = $(prefix)/share/locale
gettextsrcdir = $(prefix)/share/gettext/po
subdir = po

DESTDIR =

INSTALL = /usr/bin/install -c
INSTALL_DATA = /usr/bin/install -c -m 644
MKINSTALLDIRS = /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/../mkinstalldirs

CC = gcc
GENCAT = 
GMSGFMT = PATH=../src:$$PATH /usr/bin/msgfmt
MSGFMT = /usr/bin/msgfmt
XGETTEXT = PATH=../src:$$PATH /usr/bin/xgettext
MSGMERGE = PATH=../src:$$PATH msgmerge

DEFS = -DHAVE_CONFIG_H
CFLAGS = -O2 -fstack-protector-strong -fPIC -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security
CPPFLAGS = 

INCLUDES = -I.. -I$(top_srcdir)/intl

COMPILE = $(CC) -c $(DEFS) $(INCLUDES) $(CPPFLAGS) $(CFLAGS) $(XCFLAGS)

SOURCES = cat-id-tbl.c
POFILES = 
GMOFILES = 
DISTFILES = ChangeLog Makefile.in.in POTFILES.in $(PACKAGE).pot \
stamp-cat-id $(POFILES) $(GMOFILES) $(SOURCES)

POTFILES = \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/archive.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/archive.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/arm-reloc-property.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/arm-reloc-property.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/arm.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/attributes.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/attributes.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/binary.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/binary.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/common.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/common.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/compressed_output.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/compressed_output.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/copy-relocs.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/copy-relocs.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/cref.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/cref.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/defstd.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/defstd.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/descriptors.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/descriptors.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/dirsearch.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/dirsearch.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/dwarf_reader.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/dwarf_reader.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/dynobj.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/dynobj.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/ehframe.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/ehframe.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/errors.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/errors.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/expression.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/fileread.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/fileread.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/freebsd.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/gc.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/gc.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/gold-threads.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/gold-threads.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/gold.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/gold.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/i386.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/icf.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/icf.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/incremental.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/int_encoding.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/int_encoding.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/layout.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/layout.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/mapfile.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/mapfile.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/merge.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/merge.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/object.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/object.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/options.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/options.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/output.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/output.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/parameters.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/parameters.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/plugin.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/plugin.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/powerpc.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/readsyms.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/readsyms.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/reduced_debug_output.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/reduced_debug_output.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/reloc-types.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/reloc.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/reloc.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/resolve.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/script-c.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/script-sections.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/script-sections.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/script.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/script.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/sparc.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/stringpool.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/stringpool.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/symtab.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/symtab.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/target-reloc.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/target-select.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/target-select.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/target.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/target.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/timer.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/timer.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/tls.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/token.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/version.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/workqueue-internal.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/workqueue-threads.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/workqueue.cc \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/workqueue.h \
     /home/freddie/JohnOfPatmos/toolchain/secure_build/binutils-2.23.1/gold/x86_64.cc

CATALOGS = 
CATOBJEXT = 
INSTOBJEXT = 

.SUFFIXES:
.SUFFIXES: .c .o .po .pox .gmo .mo .msg .cat

.c.o:
	$(COMPILE) $<

.po.pox:
	$(MAKE) $(PACKAGE).pot
	$(MSGMERGE) $< $(srcdir)/$(PACKAGE).pot -o $*.pox

.po.mo:
	$(MSGFMT) -o $@ $<

.po.gmo:
	file=`echo $* | sed 's,.*/,,'`.gmo \
	  && rm -f $$file && $(GMSGFMT) -o $$file $<

.po.cat:
	sed -f ../intl/po2msg.sed < $< > $*.msg \
	  && rm -f $@ && $(GENCAT) $@ $*.msg


all: all-no

all-yes: $(CATALOGS) # $(PACKAGE).pot
all-no:

$(srcdir)/$(PACKAGE).pot: $(POTFILES)
	$(XGETTEXT) --default-domain=$(PACKAGE) --directory=$(top_srcdir) \
	  --add-comments -C --keyword=_ --keyword=N_ \
	  --msgid-bugs-address=bug-binutils@gnu.org \
	  --files-from=$(srcdir)/POTFILES.in
	rm -f $(srcdir)/$(PACKAGE).pot
	mv $(PACKAGE).po $(srcdir)/$(PACKAGE).pot

$(srcdir)/cat-id-tbl.c: stamp-cat-id; @:
$(srcdir)/stamp-cat-id: $(PACKAGE).pot
	rm -f cat-id-tbl.tmp
	sed -f ../intl/po2tbl.sed $(srcdir)/$(PACKAGE).pot \
		| sed -e "s/@PACKAGE NAME@/$(PACKAGE)/" > cat-id-tbl.tmp
	if cmp -s cat-id-tbl.tmp $(srcdir)/cat-id-tbl.c; then \
	  rm cat-id-tbl.tmp; \
	else \
	  echo cat-id-tbl.c changed; \
	  rm -f $(srcdir)/cat-id-tbl.c; \
	  mv cat-id-tbl.tmp $(srcdir)/cat-id-tbl.c; \
	fi
	cd $(srcdir) && rm -f stamp-cat-id && echo timestamp > stamp-cat-id


install: install-exec install-data
install-exec:
install-info:
install-html:
install-pdf:
install-data: install-data-no
install-data-no: all
install-data-yes: all
	if test -r $(MKINSTALLDIRS); then \
	  $(MKINSTALLDIRS) $(DESTDIR)$(datadir); \
	else \
	  $(top_srcdir)/../mkinstalldirs $(DESTDIR)$(datadir); \
	fi
	@catalogs='$(CATALOGS)'; \
	for cat in $$catalogs; do \
	  cat=`basename $$cat`; \
	  case "$$cat" in \
	    *.gmo) destdir=$(gnulocaledir);; \
	    *)     destdir=$(localedir);; \
	  esac; \
	  lang=`echo $$cat | sed 's/\$(CATOBJEXT)$$//'`; \
	  dir=$(DESTDIR)$$destdir/$$lang/LC_MESSAGES; \
	  if test -r $(MKINSTALLDIRS); then \
	    $(MKINSTALLDIRS) $$dir; \
	  else \
	    $(top_srcdir)/mkinstalldirs $$dir; \
	  fi; \
	  if test -r $$cat; then \
	    $(INSTALL_DATA) $$cat $$dir/$(PACKAGE)$(INSTOBJEXT); \
	    echo "installing $$cat as $$dir/$(PACKAGE)$(INSTOBJEXT)"; \
	  else \
	    $(INSTALL_DATA) $(srcdir)/$$cat $$dir/$(PACKAGE)$(INSTOBJEXT); \
	    echo "installing $(srcdir)/$$cat as" \
		 "$$dir/$(PACKAGE)$(INSTOBJEXT)"; \
	  fi; \
	  if test -r $$cat.m; then \
	    $(INSTALL_DATA) $$cat.m $$dir/$(PACKAGE)$(INSTOBJEXT).m; \
	    echo "installing $$cat.m as $$dir/$(PACKAGE)$(INSTOBJEXT).m"; \
	  else \
	    if test -r $(srcdir)/$$cat.m ; then \
	      $(INSTALL_DATA) $(srcdir)/$$cat.m \
		$$dir/$(PACKAGE)$(INSTOBJEXT).m; \
	      echo "installing $(srcdir)/$$cat as" \
		   "$$dir/$(PACKAGE)$(INSTOBJEXT).m"; \
	    else \
	      true; \
	    fi; \
	  fi; \
	done
	if test "$(PACKAGE)" = "gettext"; then \
	  if test -r $(MKINSTALLDIRS); then \
	    $(MKINSTALLDIRS) $(DESTDIR)$(gettextsrcdir); \
	  else \
	    $(top_srcdir)/mkinstalldirs $(DESTDIR)$(gettextsrcdir); \
	  fi; \
	  $(INSTALL_DATA) $(srcdir)/Makefile.in.in \
			  $(DESTDIR)$(gettextsrcdir)/Makefile.in.in; \
	else \
	  : ; \
	fi

# Define this as empty until I found a useful application.
installcheck:

uninstall:
	catalogs='$(CATALOGS)'; \
	for cat in $$catalogs; do \
	  cat=`basename $$cat`; \
	  lang=`echo $$cat | sed 's/\$(CATOBJEXT)$$//'`; \
	  rm -f $(DESTDIR)$(localedir)/$$lang/LC_MESSAGES/$(PACKAGE)$(INSTOBJEXT); \
	  rm -f $(DESTDIR)$(localedir)/$$lang/LC_MESSAGES/$(PACKAGE)$(INSTOBJEXT).m; \
	  rm -f $(DESTDIR)$(gnulocaledir)/$$lang/LC_MESSAGES/$(PACKAGE)$(INSTOBJEXT); \
	  rm -f $(DESTDIR)$(gnulocaledir)/$$lang/LC_MESSAGES/$(PACKAGE)$(INSTOBJEXT).m; \
	done
	rm -f $(DESTDIR)$(gettextsrcdir)/po-Makefile.in.in

check: all

cat-id-tbl.o: ../intl/libgettext.h

html dvi pdf ps info tags TAGS ID:

mostlyclean:
	rm -f core core.* *.pox $(PACKAGE).po *.old.po cat-id-tbl.tmp
	rm -fr *.o

clean: mostlyclean

distclean: clean
	rm -f Makefile Makefile.in POTFILES *.mo *.msg *.cat *.cat.m

maintainer-clean: distclean
	@echo "This command is intended for maintainers to use;"
	@echo "it deletes files that may require special tools to rebuild."
	rm -f $(GMOFILES)

distdir = ../$(PACKAGE)-$(VERSION)/$(subdir)
dist distdir: update-po $(DISTFILES)
	dists="$(DISTFILES)"; \
	for file in $$dists; do \
	  ln $(srcdir)/$$file $(distdir) 2> /dev/null \
	    || cp -p $(srcdir)/$$file $(distdir); \
	done

update-po: Makefile
	$(MAKE) $(PACKAGE).pot
	PATH=`pwd`/../src:$$PATH; \
	cd $(srcdir); \
	catalogs='$(CATALOGS)'; \
	for cat in $$catalogs; do \
	  cat=`basename $$cat`; \
	  lang=`echo $$cat | sed 's/\$(CATOBJEXT)$$//'`; \
	  mv $$lang.po $$lang.old.po; \
	  echo "$$lang:"; \
	  if $(MSGMERGE) $$lang.old.po $(PACKAGE).pot -o $$lang.po; then \
	    rm -f $$lang.old.po; \
	  else \
	    echo "msgmerge for $$cat failed!"; \
	    rm -f $$lang.po; \
	    mv $$lang.old.po $$lang.po; \
	  fi; \
	done

POTFILES: POTFILES.in
	( if test 'x$(srcdir)' != 'x.'; then \
	    posrcprefix='$(top_srcdir)/'; \
	  else \
	    posrcprefix="../"; \
	  fi; \
	  rm -f $@-t $@ \
	    && (sed -e '/^#/d' -e '/^[ 	]*$$/d' \
		    -e "s@.*@	$$posrcprefix& \\\\@" < $(srcdir)/$@.in \
		| sed -e '$$s/\\$$//') > $@-t \
	    && chmod a-w $@-t \
	    && mv $@-t $@ )

POTFILES.in: # ../Makefile
	cd .. && $(MAKE) po/POTFILES.in

Makefile: Make-in ../config.status POTFILES
	cd .. \
	  && CONFIG_FILES=$(subdir)/Makefile.in:$(subdir)/Make-in \
	     CONFIG_HEADERS= $(SHELL) ./config.status

# Tell versions [3.59,3.63) of GNU make not to export all variables.
# Otherwise a system limit (for SysV at least) may be exceeded.
.NOEXPORT:
