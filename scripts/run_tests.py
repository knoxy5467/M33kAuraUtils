# scripts/run_tests.py: Cross-platform runner using Python + Lupa (LuaJIT/Lua runtime)
import os
import sys
import lupa
from lupa import LuaRuntime

def run_tests():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..")).replace("\\", "/")
    os.chdir(project_root)

    lua = LuaRuntime(unpack_returned_tuples=True)

    # Set Lua package path
    lua_code_setup = f"""
    package.path = package.path .. ";{project_root}/?.lua;{project_root}/tests/?.lua;{project_root}/Locales/?.lua"
    """
    lua.execute(lua_code_setup)

    with open(os.path.join(project_root, "scripts", "run_tests.lua"), "r", encoding="utf-8") as f:
        test_script = f.read()

    try:
        lua.execute(test_script)
    except lupa.LuaError as e:
        print(f"\n[EXECUTION ERROR] Lua test execution failed:\n{e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
