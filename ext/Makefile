CMARK = cmark-gfm
SOURCES = $(wildcard $(CMARK)/src/*.c) $(wildcard $(CMARK)/src/*.h)

all: libcmark-gfm.a

libcmark-gfm.a: $(CMARK) $(SOURCES)
	cd $(CMARK) && INSTALL_PREFIX=.. make cmake_build
	cp $(CMARK)/build/src/*.a .
	cp $(CMARK)/build/extensions/*.a .

$(CMARK):
	git clone --depth 1 --branch 0.29.0.gfm.2 https://github.com/github/cmark-gfm.git

clean:
	rm -rf cmark-*

distclean: clean
	rm -rf *.a
