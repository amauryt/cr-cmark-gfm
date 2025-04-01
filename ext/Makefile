CMARK = cmark-gfm
SOURCES = $(wildcard $(CMARK)/src/*.c) $(wildcard $(CMARK)/src/*.h)
COMPILED_EXT = so

OS := $(shell uname)
ifeq ($(OS),Darwin)
	COMPILED_EXT = dylib
endif

all: build

build: $(CMARK) $(SOURCES)
	mkdir -p $(CMARK)/build
	cd $(CMARK)/build && cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=.. \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON
	cd $(CMARK)/build && make

	cp $(CMARK)/build/src/libcmark-gfm.a .
	cp $(CMARK)/build/src/libcmark-gfm.$(COMPILED_EXT)* .
	cp $(CMARK)/build/extensions/libcmark-gfm-extensions.a .
	cp $(CMARK)/build/extensions/libcmark-gfm-extensions.$(COMPILED_EXT)* .

$(CMARK):
	git clone --depth 1 --branch 0.29.0.gfm.8 https://github.com/github/cmark-gfm.git

clean:
	rm -rf cmark-*

distclean: clean
	rm -rf *.a
	rm -rf *.$(COMPILED_EXT)*
