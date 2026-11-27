from pathlib import Path
import json
from lua_comments import strip,clean_tree

root=Path(__file__).resolve().parents[1]
core=root/'HeadLockMenu_Core.lua'
text=core.read_text()

def installer(filename):
    source=strip((root/filename).read_text())
    source=source[source.index('return function'):]
    return '('+source[len('return '):].rstrip()+')'

start=text.index('function SC.installVehicles()')
if 'function SC.installVehicleSync(ctx)' in text:
    start=text.index('function SC.installVehicleSync(ctx)')
end=text.index('\naddCategory("Vehicles",',start)
payload='function SC.installVehicleSync(ctx)\nreturn '+installer('HeadLockMenu_VehicleSync.lua')+'(ctx)\nend\n'
relay=json.loads((root/'vehicle-relay.json').read_text())['url']
assert relay=='' or relay.startswith('https://')
payload+='SC.vehicleRelayURL='+json.dumps(relay)+'\n'
payload+='function SC.installVehicles()\nreturn '+installer('HeadLockMenu_Vehicles.lua')+'(SC)\nend\n'
payload+=installer('HeadLockMenu_AutoWin.lua')+'''(SC,{Players=Players,Run=RS,player=player,connect=connect,make=make,button=textButton,black=BLACK,white=WHITE,
 stopMovement=SC.stopConflictingMovement,stopFly=stopCFly,startFly=startCFly,
 ensureFire=ensureFireHook,ensureRecoil=ensureNoRecoilHook,ensureSpread=ensureNoSpreadHook,
 updateJuggernaut=updateJuggernaut,getJuggernaut=function()return juggernautPlayer end})
'''
core.write_text(strip(text[:start]+payload+text[end:]))
clean_tree(root)
print('Built Lua files')
