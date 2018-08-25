-- Fundamental moss concepts:
--  Artifact: a completed build output (definition vs product)
--  Build Pipeline: a series of build functions that transform definition into product
--  Tool: build function that translats source files or forms products
--  Spore: collection of artifact definitions and build functions

require("lambda")

local clang_debug_tools = lambda { cflags = append("-g") }
local clang_release_tools = lambda { cflags = append("-O3") }
local clang_with_fpu = lambda { cflags = append("-ffpu") }

local debug = lambda { cflags = append("-DDEBUG") }
local fast = lambda { cflags = append("-DLOG_NONE") }
local verbose = lambda { cflags = append("-DLOG_VERBOSE") }

local directory = lambda { forms = append("DIR") }
local staticlib = lambda { forms = append("LIB") }
local executable = lambda { forms = append("EXE") }
local zipfile = lambda { forms = append("ZIP") }

-- Debug build pipeline
local debug_build = build(clang_debug_tools, debug, verbose)

-- Release build pipeline
local release_build = build(clang_release_tools, fast)

math_lib = build(staticlib) {
    name = "fastmath.lib";
    source = {"math1.c", "math2.c"};
};

main_image = build(executable) {
    name = "main.exe";
    source = "main.c";
    -- main_image requires math_lib within its build
    libs = "fastmath";
};

local output = build(directory) {
    name = "output";

    build(directory, debug_build) {
        name = "debug";

        math_lib;
        main_image;
    };

    build(directory, release_build) {
        name = "release";

        main_image;
        build(clang_with_fpu)(math_lib);
    };

    -- In-place build artifact
    build(zipfile) {
        name = "release.zip";

        files = {
            -- We can refer to artifacts directly by path
            "release/main.exe",
            "debug/main.exe",
            "help.doc",
            "release-notes.txt"
        };
    };
};

dumpbuild(output)
