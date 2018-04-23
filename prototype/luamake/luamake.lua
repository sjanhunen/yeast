-- Lua fuctions to be used from luamake.mk

proc = function(msg1, msg2)
	local welcome = "Welcome from Lua: ";
	return welcome .. msg1 .. "," .. msg2;
end

eval = function(code)
    return load("return " .. code)()
end

function moss_form(class, name, recipe)
    print(name .. ": form " .. class .. " using recipe " .. recipe);
end

function moss_translate(src, dst, name, recipe)
    print(name .. ": translate " .. src .. "->" .. dst .. " using recipe " .. recipe);
end

function moss_compile(src, name, recipe)
    print(name .. ": compile " .. src .. " using recipe " .. recipe);
end

function seed(s)
    -- Seed creation returns a function that is evaluated two ways
    -- 1) With m as table to specify configuration
    -- 2) With m as string to resolve option (returns another function)
    return function(m) return m; end
end

function executable(t)
    return function(q) return t; end;
end

function library(t)
    return t
end

function files(f)
    -- Split files into table here
    return f
end

function list(f)
    -- Split files into table here
    return f
end

function flag(f)
    return f
end

function choice(c)
    return c
end

function export(variables)
end
