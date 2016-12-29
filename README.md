# gnumake-molds

TODO: rename repository from gnumake-molds to yeast

Goals
=====

Yeast streamlines creation of cross-compiled libraries and executables from
large code bases for a variety of architectures and toolchains using only GNU
make.

Yeast is a build system that is intended for use on a code base stored and
versioned within a single repository. Yeast is not a package manager that
brings together source code and libraries from multiple repositories across
multiple versions. Integration of multiple code bases must either be solved at
a lower level in the repository (e.g. using git submodules) or at a higher
level using a package management system (e.g. Debian packages).

While the final releasable output from a yeast build will likely be a single
library or executable, there are often many intermediate and secondary targets
required to produce this target such as 3rd-party libraries, unit test
executables, special debug and test builds, and so on. Yeast streamlines the
creation and management of these targets.

Features
========

Cross-compiling
---------------

- Cross-compile embedded applications for different architectures with a single Makefile
- Out-of-the-box support for gcc and clang x86/ARM
- Create libaraies with different complier options (e.g. ARM vs Thumb code)

Target generation
-----------------

- Build the same source file with different compiler settings
- Create multiple executable and library target outputs with ease
- Separate definition of program source and structure from creating rules

Large projects
--------------

- Manage large projects with multiple "sub-components"
- Combine components from different parts of a filesystem (re-use installed library source in multiple projects)
- Create release directory structures with libraries, binaries, and includes
- Build against libraries either from source or from released package

Languages
---------

The initial vision is to support core languages in the GCC/LLVM toolchains:

- C
- C++
- Objective C

A longer term vision might be to expand this support to include languages such as

- Rust
- Swift
- Go

Usability
---------

- Tab auto-completion works with targets defined by Mold
- Makes it easier to debug by dumping full commands with options
- Unit testable for validation and performance testing
- Work with in-place object files for the smallest projects
- Support for automatic dependency generation

Core Concepts
=============

Toolchain
---------

A toolchain is a set of tools that are used to translate source code into binary form for execution on a specific architecture.

Code generated by one toolchain cannot be linked or combined with code generated for another toolchain.

Examples: gcc, clang, gcc-debug, clang-release, clang-debug.

While a toolchain must include all tools required to produce an executable binary or library output, the name of the toolchain is generally based upon the compiler.

Generally, debug versus release build variants are handled at the toolchain level due to the significant impact that may be present on generated code.

- `YEAST.TOOLS`: All available toolchains
- `YEAST.TOOL`: Current toolchain

Architecture
------------

A build architecture is defined by a specific CPU type and associated instruction set.

Examples: host, amd64, cortex-m4, cortex-r7, avr, mipsel, etc.

Code generated for different architectures does not interoperate and cannot be linked together.

- `YEAST.ARCHS`: All available architectures for current toolchain
- `YEAST.ARCH`: Current architecture for current toolchain

Good discussion on architecture naming here: http://clang.llvm.org/docs/CrossCompilation.html

Language
--------

Each toolchain supports at least one language that is used by source files.
Many toolchains support multiple languages (e.g. GCC and LLVM).

Globally, language options are configured using the syntax `YEAST.<language>.<option> = <value>`.

Language options can be configured specifically for each spore with the syntax
`<spore>.<language>.<option> = <value>`. For example:

	util.c.defines = POSIX_2001
	util.c.include = util/inc

The spore specific options override any global options. To include the global
yeast options for a specific spore when overriding, simply include the global
options as part of the spore-specific options. For example:

	util.c.defines = $(YEAST.c.defines) UTIL_OPTION_X=1

Spores
------

All outputs are generated from individual units of source code called spores.
Each spore may produce one or more products as outputs during the build
process. Yeast manages a list of all spores through the variable
`YEAST.SPORES`. If a new spore is created, it must be added to this list.

For example:

	YEAST.SPORES += util
	util.name = utility
	util.depends = common
	util.products = shared_lib static_lib headers

Spores are defined with the following key variables:

- `<spore>.name` - base name used as part of output products
- `<spore>.depends` - other spores required as dependencies of this spore
- `<spore>.products` - the list of final output products produced by this spore
- `<spore>.source` - the list of source files required to generate products
- `<spore>.headers` - the list of header files to be released with products

Products
--------

Four types of yeast products are currently supported:

- Executable: a fully-linked binary executable
- Static Library: a library for static linking into one or more executables
- Shared Library: a dynamic library for use with one or more executable products
- Headers: a set of header files for stand-alone use or use with a library

Global product options may be configured using the syntax
`YEAST.<product>.<option> = <value>`. For example:

    YEAST.headers.path = include
	YEAST.executable.path = bin/$(YEAST.ARCH)
	YEAST.executable.suffix = .exe
	YEAST.shared_lib.path = lib/$(YEAST.ARCH)
	YEAST.shared_lib.suffix = .so

Spore-specific product options are configured using the syntax `<spore>.<product>.<option> = <value>`.

Build Tree Structure
====================

All yeast build object files and products are placed in a yeast build tree
structure called `yeast.build` by default.

Build objects and products are placed according to the following guidelines:

- headers -> `YEAST.HEADER.PATH`
- static and shared libraries -> `YEAST.LIBRARY.PATH`
- object files -> `YEAST.OBJECT.PATH`
- executables -> `YEAST.EXECUTABLE.PATH`

Headers located in `YEAST.HEADER.PATH` are automatically included as part of
the system include path when building spore products. Libraries located in
`YEAST.LIB.PATH` are included as part of the library search path when linking
spore products.

An example `yeast.build` structure might look something like this:

	yeast.build/
		include/
			freertos/
				task.h
				mutex.h
				...
			core/
				stuff.h
				...
			crypto/
				hash.h
				...
		obj/
			armv5.gcc-release/
				crypto/
					src/
						sha1.crypto.o
						md5.crypto.o
				...
			armv5.gcc-debug/
				crypto/
					src/
						sha1.crypto.o
						md5.crypto.o
				...
		bin/
			armv5.gcc-release/
				...
			armv5.gcc-debug/
				...
		lib/
			armv5.gcc-release/
				libfreertos.a
				libcore.a
				libcrypto.a
			armv5.gcc-debug/
				libfreertos.a
				libcore.a
				libcrypto.a

Yeast assumes that header files are shared across all architectures and
toolchains. Any architecture-specific header files are an internal
implementation detail of the source code for a spore that defines them.
