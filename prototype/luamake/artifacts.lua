function artifact(arg)
    return arg;
end

executable = artifact {
    name = "Executable";
    source = {};
    translate = {};
    form = {};
};

staticlib = artifact {
    name = "Static Library";
    source = {};
    translate = {};
    form = {};
};

zipfile = artifact {
    name = "Zip File";
    form = form("zip") "gzip -vf $@ $<";
    source = {};
};