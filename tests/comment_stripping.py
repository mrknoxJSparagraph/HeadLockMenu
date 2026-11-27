import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from lua_comments import strip,segments

cases=[
    ('return "https://example/--asset" -- note\n','return "https://example/--asset"  \n'),
    ('local a=[=[-- text ]=]--[[note]]\nreturn a','local a=[=[-- text ]=] \nreturn a'),
    ('return 1- -- note\n -2','return 1-  \n -2'),
    ('''return 'a\\\'--b', `--label` -- tail''','''return 'a\\\'--b', `--label`  '''),
    ('a--[=[line\none]=]b','a \nb')
]
for source,expected in cases:
    actual=strip(source)
    assert actual==expected,(actual,expected)
    assert not any(c for c,_ in segments(actual))
print('PASS comment stripping preserves program text and token boundaries')
for path in Path(__file__).resolve().parents[1].rglob('*'):
    if path.suffix in ('.lua','.luau') and 'node_modules' not in path.parts and '.git' not in path.parts:
        assert not any(comment for comment,_ in segments(path.read_text())),str(path)
print('PASS published Lua has no comments')
