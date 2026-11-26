"""Embed the readable feature installers into the single-download menu core."""
from pathlib import Path
import re

root=Path(__file__).resolve().parents[1]
core=root/'HeadLockMenu_Core.lua'
text=core.read_text()

def installer(filename):
    source=(root/filename).read_text()
    source=source[source.index('return function'):]
    return '('+source[len('return '):].rstrip()+')'

payloads={
 'VEHICLES':'function SC.installVehicles()\n return '+installer('HeadLockMenu_Vehicles.lua')+'(SC)\nend\n',
 'AUTOWIN':installer('HeadLockMenu_AutoWin.lua')+'''(SC,{Players=Players,Run=RS,player=player,connect=connect,make=make,button=textButton,black=BLACK,white=WHITE,
 stopMovement=SC.stopConflictingMovement,stopFly=stopCFly,startFly=startCFly,
 ensureFire=ensureFireHook,ensureRecoil=ensureNoRecoilHook,ensureSpread=ensureNoSpreadHook,
 updateJuggernaut=updateJuggernaut,getJuggernaut=function()return juggernautPlayer end})
'''
}
for name,payload in payloads.items():
    pattern=r'(-- INTEGRATED_'+name+r'_BEGIN\n).*?(-- INTEGRATED_'+name+r'_END)'
    text,count=re.subn(pattern,lambda m:m[1]+payload+m[2],text,flags=re.S)
    assert count==1,f'Expected one {name} embedding, found {count}'
core.write_text(text)
print('Embedded AutoWin and Vehicles')
