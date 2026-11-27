from pathlib import Path
import ctypes
import ctypes.util
import os

os.chdir(Path(__file__).resolve().parents[1])
library=ctypes.util.find_library('lua5.4')
if not library:
    raise SystemExit('This check requires liblua5.4.')
lua=ctypes.CDLL(library)
lua.luaL_newstate.restype=ctypes.c_void_p
lua.luaL_openlibs.argtypes=[ctypes.c_void_p]
lua.luaL_loadfilex.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p]
lua.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lua.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]
lua.lua_tolstring.restype=ctypes.c_char_p
lua.lua_close.argtypes=[ctypes.c_void_p]
state=lua.luaL_newstate()
lua.luaL_openlibs(state)
result=lua.luaL_loadfilex(state,b'tests/vehicle_physics.lua',None)
if not result:
    result=lua.lua_pcallk(state,0,0,0,0,None)
if result:
    print(lua.lua_tolstring(state,-1,None).decode())
lua.lua_close(state)
raise SystemExit(bool(result))
