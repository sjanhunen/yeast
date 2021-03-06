# Implementation Alternatives

This document is a journal of implementation considerations, alternatives, and decisions encountered during the implementation of Moss.

## Table Definition

A significant challenge in writing large makefiles is structuring and scoping the large number of variable definitions required. Adding structure to this via tables can help significantly, since individual artifacts or components can be defined separately without concern for table members with the same name.

### Explicit Table Definition

All approaches to managing this in make boil down to some form of use of prefixes to create a namespace convention. For example:

```makefile
util.name = utility
util.source = util.c helper.c
util.depends = common
```

This particular approach leads to significant duplication and also means that cloning the definiton requires coping each individual definition, as they are all separate variables at this point.

### Implicit Table Definition

A more interesting approach keeps tables defined (implicitly) inside of a multi-line variable definition for as long as possible. For example:


```makefile
define util
$1.name = utility
$1.source = util.c helper.c
$1.depends = common
endef
```

This eliminates duplication of the table name and is quite readable.
Expansion is performed as late as possible in the build process to ensure that tables can be compied and composed as a single variable definitoin. Error handling may be more difficult or cryptic, since syntax errors during evaluation won't be tracable back to a specific line in the definition. This disadvantage must be weighed against the advantages of the approach.

Cloning the table is as simple as assigning the variable:

```makefile
another_util = $(util)
```

### Lua Table Definition

Another approach to table definition is to actually use a domain-specific language to define tables outside of makefiles entirely.

For exmaple, Lua's table definition syntax is compact and readable:

```lua
util = {
	name = 'utility',
    source = { 'util.c', 'helper.c', },
    depends = common
}
```

Some string-to-table helpers could make this even more compact:

```lua
util = {
	name = 'utility',
    source = [[ util.c helper.c ]],
    depends = common
}
```

It would be necessary to define an approach for including these definitions into a makefile. For example, a gnumake extension (e.g. `$(lua ...)`) might be used to include an external Lua module with table definitions.

The disadvantage here is that the solutoin cannot be implemented in pure gnumake, which was one of the stated goals of the project. However, there are significant advantages in terms of syntax checking and flexibility. From a pure character count metric, the approach may be slightly (but not significantly) more compact.

### YAML Table Definition

As an alternative, YAML files could be used as a way to create table and variable definitions with a very compact and readable syntax.
A special gnumake extension (e.g. `$(yaml ...)`) could then be created to load YAML files as namespaced variable definitions.
Table and template definition could then be expressed almost fully in YAML files.
Final table composition for artifact definition would still take place in makefiles.

## Dependency Generation

The most reliable way to get dependencies right with minimal maintenance is to use the compiler iteself with the same options as an actual build.
Otherwise, there is a risk that preprocessor macros will not be evaluated correctly.

Reference build performance with no dependencies:

```
Not parallel: 14.229s
Parallel (-j4): 0m4.096s
```

Alternatives:

1. Generate dependencies first, one at a time

	```
	Not parallel: 0m21.822s
	Parallel (-j4): 0m6.318s
	```

2. Generate dependencies after compile, one at a time

	```
	Not parallel: 0m19.663s
	Parallel (-j4): 0m6.329s
	```

3. Generate dependencies during compile, one at a time

	```
	Not parallel: 0m14.578s
	Parallel (-j4): 0m4.217s
	```

4. Generate bulk dependencies for spore first: Not feasable without extra
   post-processing due to the fact that each target needs custom name

Option 3 is the clear winner. For compilers that support dependency generation
during compile (e.g. gcc), this is nearly as fast as a straight build with no
dependency generation. For compilers that don''t support this, the dependency
generation step can be implemented as a separate invocation of the compiler or
other tool during the same recipe for compilation.

One remaining challenge in this design is the performance of make with nothing
to do for large code bases (e.g 10,000 files). Include the per-file dependency
information can take a significant amount of time. For example:

```
make: Nothing to be done for 'all'. (no dependencies)

real    0m0.969s
user    0m0.312s
sys     0m0.656s
```

```
make: Nothing to be done for 'all'. (using individual .d files for dependencies)

real    0m7.629s
user    0m1.484s
sys     0m3.406s
```

The make with nothing to do slows down by nearly an order of magnitude when
full dependency information is used. An experiment was performed to rule out
the performance of include. All dependency files were concatenated into a
single all.d with the following result:

```
make: Nothing to be done for 'all'. (using single all.d for dependencies)

real    0m1.030s
user    0m0.281s
sys     0m0.734s
```

This is a significant performance improvement over including individual
dependency files and represents one path forward for high-performance
dependency generation.


## Build Tree Structure

All Moss build object files and artifacts are placed in a Moss build tree
structure called `moss.build` by default.

Build objects and artifacts are placed according to the following guidelines:

- headers -> `M.HEADER.PATH`
- static and shared libraries -> `M.LIBRARY.PATH`
- object files -> `M.OBJECT.PATH`
- executables -> `M.EXECUTABLE.PATH`

Headers located in `M.HEADER.PATH` are automatically included as part of
the system include path when building spore artifacts. Libraries located in
`M.LIB.PATH` are included as part of the library search path when linking
spore artifacts.

An example `moss.build` structure might look something like this:

	moss.build/
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

Moss assumes that header files are shared across all platforms and
toolchains. Any platform-specific header files are an internal
implementation detail of the source code for a spore that defines them.

## Recursive vs Inclusive

There are some high-level considerations to make. Do we use any amount of
recursive make to help with iteration over toolchains, platforms, or
possibly even individual spores? It may simplify some things, but the
performance tradeoffs are unknown. As little recursion as possible is the
general design goal.

For example, instead of expanding rules for spores using foreach into a flat
Makefile, it would be possible to invoke a child process to build each spore
using the same rules with variables expanded within each process sandbox. This
could take place in parallel once the spore interdependencies have been
resolved at the top level. An added benefit is that on multi-core machines,
dependency checks for leaf components could take place in parallel.

If we make use of target-specific variables for toolchain settings, we need to invoke make once recursively on each spore for that target to ensure dependencies are right.

If we simply set toolchain in a top-level invocation of make, we can use that variable in any invocation.

We could also generate spore targets for all toolchains in a single top level invocation.

For example, spore crypto could spawn

	armv5/crypto armv7/crypto host/crypto

By default, linking armv7/app would pick up armv7/crypto. However, this could be overridden with

	armv7/app.depends = armv5/crypto

Toolchain specific dependencies would automatically inherit the appropriate toolchain prefix.

Some use cases may require that toolchain be specialized for certain spores by platforms. That is, a given spore might have to be built a special way for a particular platform. I think this could be done via target specific variables.
