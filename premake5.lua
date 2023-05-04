newoption {
    trigger = "sdl-config",
    value = "PATH",
    description = "Path to sdl2-config script"
}

newoption {
    trigger = "test",
    description = "Generate make files for libvxt tests"
}

newoption {
    trigger = "scrambler",
    description = "Generate make files for scrambler"
}

newoption {
    trigger = "modules",
    description = "Generate make files for all modules"
}

newoption {
    trigger = "validator",
    description = "Enable the PI8088 hardware validator"
}

newoption {
    trigger = "i286",
    description = "Provide some 286 support when running with a V20"
}

newaction {
    trigger = "check",
    description = "Run CppCheck on libvxt",
    execute = function ()
        return os.execute("cppcheck --enable=style -I lib/vxt/include lib/vxt")
    end
}

newaction {
    trigger = "doc",
    description = "Generate libvxt API documentation",
    execute = function ()
        return os.execute("cd lib/vxt/include && doxygen .doxygen")
    end
}

workspace "virtualxt"
    configurations { "release", "debug" }
    platforms { "native", "web" }
    language "C"
    cdialect "C11"

    filter "configurations:debug"
        symbols "On"

    filter "configurations:release"
        defines "NDEBUG"
        optimize "On"

    filter "options:i286"
        defines "VXT_CPU_286"

    filter "options:validator"
        defines "PI8088"
        links "gpiod"

    filter "system:windows"
        defines { "_CRT_SECURE_NO_WARNINGS", "_WINSOCK_DEPRECATED_NO_WARNINGS" }
        links "Ws2_32"

    filter "toolset:clang or gcc"
        buildoptions { "-pedantic", "-Wall", "-Wextra", "-Werror", "-Wno-implicit-fallthrough", "-Wno-unused-result" }

    local modules = {}
    local module_names = {}

    if _OPTIONS["modules"] then
        defines "VXTU_MODULES"
        local files = os.matchfiles("modules/**/premake5.lua")
        for _,v in ipairs(files) do
            defines { "VXTU_MODULE_" .. string.upper(path.getname(path.getdirectory(v))) }
        end
        
        for _,v in ipairs(files) do
            module_root = path.getdirectory(v)
            module_name = path.getname(module_root)
    
            local libname = module_name .. "-module"
            table.insert(modules, libname)
            table.insert(module_names, module_name)

            project(libname)
                kind "StaticLib"
                basedir "."
                includedirs "lib/vxt/include"
                defines { "VXTU_MODULE_NAME=" .. module_name }
    
            dofile(v)
        end
    end

    project "inih"
        kind "StaticLib"
        files { "lib/inih/ini.h", "lib/inih/ini.c" }

    project "microui"
        kind "StaticLib"
        files { "lib/microui/src/microui.h", "lib/microui/src/microui.c" }

    project "miniz"
        kind "StaticLib"
        pic "On"
        files { "lib/miniz/miniz.h", "lib/miniz/miniz.c" }
        
        filter "toolset:clang or gcc"
            buildoptions "-Wno-error=type-limits"

    project "fat16"
        kind "StaticLib"
        pic "On"
        files {
            "lib/fat16/fat16.h",
            "lib/fat16/blockdev.h",
            "lib/fat16/fat16_internal.h",
            "lib/fat16/fat16.c"
        }

    project "vxt"
        kind "StaticLib"

        files { "lib/vxt/**.h", "lib/vxt/*.c" }
        includedirs "lib/vxt/include"
        removefiles { "lib/vxt/testing.h", "lib/vxt/testsuit.c" }
        
        filter "toolset:clang or gcc"
            buildoptions { "-nostdinc" }

    project "vxtp"
        kind "StaticLib"

        files { "lib/vxtp/*.h", "lib/vxtp/*.c" }
        includedirs { "lib/vxtp", "lib/vxt/include"}

        filter "toolset:gcc"
            buildoptions { "-Wno-format-truncation", "-Wno-stringop-truncation", "-Wno-stringop-overflow" }

    project "libretro-frontend"
        kind "SharedLib"
        targetname "virtualxt_libretro"
        targetprefix ""
        targetdir "build/lib"
        pic "On"

        includedirs "lib/libretro"
        files { "front/libretro/*.h", "front/libretro/*.c" }
        
        defines { "VXTU_CGA_RED=2", "VXTU_CGA_GREEN=1", "VXTU_CGA_BLUE=0", "VXTU_CGA_ALPHA=3" }
        includedirs "lib/vxt/include"
        files { "lib/vxt/**.h", "lib/vxt/*.c" }
        removefiles { "lib/vxt/testing.h", "lib/vxt/testsuit.c" }

        includedirs "lib/vxtp"
        files { "lib/vxtp/**.h", "lib/vxtp/joystick.c" }

        links { "miniz", "fat16" }
        includedirs { "lib/miniz", "lib/fat16" }
        defines "ZIP2IMG"

        cleancommands {
            "{RMDIR} build/lib",
            "make clean %{cfg.buildcfg}"
        }

        filter "toolset:clang or gcc"
            buildoptions { "-Wno-atomic-alignment", "-Wno-deprecated-declarations" }

        -- TODO: Remove this filter! This is here to fix an issue with the GitHub builder.
        filter "not system:windows"
            postbuildcommands "{COPYFILE} front/libretro/virtualxt_libretro.info build/lib/"

    project "web-frontend"
        kind "ConsoleApp"
        toolset "clang"
        targetname "virtualxt"
        targetprefix ""
        targetextension ".wasm"
        targetdir "build/web"

        includedirs { "lib/vxt/include", "lib/vxtp", "lib/printf" }
        files { "front/web/*.h", "front/web/*.c" }

        files { "lib/vxt/**.h", "lib/vxt/*.c" }
        removefiles { "lib/vxt/testing.h", "lib/vxt/testsuit.c" }

        files { "lib/vxtp/ctrl.c" }

        files { "lib/printf/printf.h", "lib/printf/printf.c" }

        -- Perhaps move this to options?
        local page_size = 0x10000
        local memory = {
            initial = 350 * page_size,   -- Initial size of the linear memory (1 page = 64kB)
            max = 350 * page_size,       -- Maximum size of the linear memory
            base = 6560                  -- Offset in linear memory to place global data
        }

        buildoptions { "--target=wasm32", "-mbulk-memory", "-flto" }
        linkoptions { "--target=wasm32", "-nostdlib", "-Wl,--allow-undefined", "-Wl,--lto-O3", "-Wl,--no-entry", "-Wl,--export-all", "-Wl,--import-memory" }
        linkoptions { "-Wl,--initial-memory=" .. tostring(memory.initial), "-Wl,--max-memory=" .. tostring(memory.max), "-Wl,--global-base=" .. tostring(memory.base) }

        postbuildcommands {
            "{COPYFILE} front/web/index.html build/web/",
            "{COPYFILE} front/web/script.js build/web/",
            "{COPYFILE} front/web/favicon.ico build/web/",
            "{COPYFILE} front/web/disk.png build/web/",
            "{COPYFILE} boot/freedos_web_hd.img build/web/",
            "{COPYDIR} lib/simple-keyboard/build/ build/web/kb/"
        }

        cleancommands {
            "{RMDIR} build/web",
            "make clean %{cfg.buildcfg}"
        }

    project "sdl2-frontend"
        kind "ConsoleApp"
        targetname "virtualxt"
        targetdir "build/bin"

        files { "front/sdl/*.h", "front/sdl/*.c" }

        links { "vxt", "vxtp", "inih", "microui" }
        includedirs { "lib/vxt/include", "lib/vxtp", "lib/inih", "lib/microui/src" }

        files "modules/modules.h"
        includedirs "modules"

        if _OPTIONS["modules"] then
            links(modules)
        end

        local sdl_cfg = path.join(_OPTIONS["sdl-config"], "sdl2-config")
        buildoptions { string.format("`%s --cflags`", sdl_cfg) }
        linkoptions { string.format("`%s --libs`", sdl_cfg) }

        cleancommands {
            "{RMDIR} build/bin",
            "make clean %{cfg.buildcfg}"
        }

        filter "options:validator"
            files { "tools/validator/pi8088/pi8088.c", "tools/validator/pi8088/udmask.h" }

        filter "toolset:clang or gcc"
            buildoptions { "-Wno-unused-parameter", "-Wno-pedantic" } -- no-pedantic, bacause of a problem with conversion from funcion pointers.

        filter "toolset:clang"
            buildoptions { "-Wno-missing-field-initializers", "-Wno-missing-braces" }

        filter "toolset:gcc"
            buildoptions "-Wno-maybe-uninitialized"

if _OPTIONS["scrambler"] then
    project "scrambler"
        kind "ConsoleApp"
        targetname "scrambler"
        targetdir "build/bin"
        links "gpiod"
        defines { "PI8088", "VXT_CPU_286" }

        files { "tools/validator/pi8088/scrambler.c", "tools/validator/pi8088/pi8088.c", "tools/validator/pi8088/udmask.h" }
        
        includedirs "lib/vxt/include"
        files { "lib/vxt/**.h", "lib/vxt/*.c" }
        removefiles { "lib/vxt/testing.h", "lib/vxt/testsuit.c" }

        cleancommands {
            "{RMDIR} build/bin",
            "make clean %{cfg.buildcfg}"
        }
end

if _OPTIONS["test"] then
    project "test"
        kind "ConsoleApp"
        targetdir "test"
        includedirs "lib/vxt/include"
        defines { "TESTING", "VXT_CPU_286" }
        files { "test/test.c", "lib/vxt/**.h", "lib/vxt/*.c" }
        optimize "Off"
        symbols "On"

        postbuildcommands "./test/test"
        cleancommands "{RMDIR} test"

        filter { "toolset:clang or gcc" }
            buildoptions { "-Wno-unused-function", "-Wno-unused-variable", "--coverage" }
            linkoptions "--coverage"
    
    io.writefile("test/test.c", (function()
        local test_names = {}
        for _,file in pairs(os.matchfiles("lib/vxt/*.c")) do
            for line in io.lines(file) do
                if string.startswith(line, "TEST(") then
                    table.insert(test_names, string.sub(line, 6, -2))
                end
            end
        end

        local head = '#include <stdio.h>\n#include "../lib/vxt/testing.h"\n\n'
        head = head .. '#define RUN_TEST(t) { ok += run_test(t) ? 1 : 0; num++; }\n\n'
        local body = "\t(void)argc; (void)argv;\n\tint ok = 0, num = 0;\n\n"
        for _,name in ipairs(test_names) do
            head = string.format("%sextern int test_%s(struct Test T);\n", head, name)
            body = string.format("%s\tRUN_TEST(test_%s);\n", body, name)
        end
        body = string.format('%s\n\tprintf("%%d/%%d tests passed!\\n", ok, num);\n\treturn (num - ok) ? -1 : 0;\n', body)
        return string.format("%s\nint main(int argc, char *argv[]) {\n%s}\n", head, body)
    end)())
end

io.writefile("modules/modules.h", (function()
    local str = "#include <vxt/vxtu.h>\n\nstruct vxtu_module_entry {\n\tconst char *name;\n\tvxtu_module_entry_func *(*entry)(void);\n};\n\n#ifdef VXTU_MODULES\n"
    for _,mod in ipairs(module_names) do
        str = string.format("%s\nextern vxtu_module_entry_func *_vxtu_module_%s_entry(void);\n", str, mod)
    end
    str = string.format("%s\nconst struct vxtu_module_entry vxtu_module_table[%d] = {\n", str, #module_names + 1)
    for _,mod in ipairs(module_names) do
        str = string.format('%s\t{ "%s", _vxtu_module_%s_entry },\n', str, mod, mod)
    end
    return string.format("%s\t{ NULL, NULL }\n};\n\n#else\n\nconst struct vxtu_module_entry vxtu_module_table[1] = { { NULL, NULL } };\n\n#endif\n", str)
end)())