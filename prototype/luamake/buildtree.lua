-- Moss favors explicit definition over automatic discovery.  The build tree is
-- a structure used to explicitly define how software is built.  Large, complex
-- builds can be composed from build nodes.  Each build node defines an
-- artifact within the build tree along with the configuration for any traits
-- used to build that artifact.

function build(form)
    if(type(form) == "string") then
        print("build directory: " .. form);
    else
        print("build form: " .. form.name);
    end
    return function(e) return function() return form end end
end

math_lib = build(staticlib) {
    name = "fastmath.lib";
    source = [[ math1.c math2.c ]];
}

main_image = build(executable) {
    name = "main.exe";
    -- main_image requires math_lib within it's build
    libs = {math_lib};
};

build("output") {
    [executable] = {
        form = clangld;
        translate = clangcc;
    };
    [staticlib] = {
        form = clangar;
        translate = clangcc;
    };

    [clangcc] = { cflags = "-Wall" };

    -- Traits cannot be expanded within a build unless they have been
    -- configured.  Traits are superior to global variables in that offer
    -- better scope control and are less brittle.  Specific traits can be
    -- overriden too: myconfig.trait = { }
    [myconfig] = {
        memory_model = "large";
        debug = false;
    };

    build("debug") {
        [clangcc] = { cflags = "-Og -DDEBUG" };

        -- Each artifact produced within a build node
        -- must be explicitly enumerated.
        math_lib, main_image
    };

    build("release") {
        [clangcc] = { cflags = "-O3" };
        [myconfig] = { debug = true };

        main_image,
        -- Explicit configuration for this build of math_lib
        math_lib {
            [clangcc] = { cflags = "-Mfpu" };
        };
    };

    -- In-place build artifact
    build(zipfile) {
        name = "release.zip";

        -- TODO: how do we select which main_image to use?
        source = {
            "release/main.exe",
            "debug/main.exe",
            "help.doc",
            "release-notes.txt"
        };
    };
};
