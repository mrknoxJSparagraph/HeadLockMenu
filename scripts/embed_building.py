from pathlib import Path
import json
from lua_comments import strip
root=Path(__file__).resolve().parents[1]
def install(name):
 source=strip((root/name).read_text());source=source[source.index('return function'):];return '('+source[len('return '):].rstrip()+')'
p=root/'HeadLockMenu_Core.lua';s=p.read_text()
start=s.find('function SC.installBuilding()')
if start<0:start=s.index('function SC.refreshOwnerCategories()')
end=s.index('function SC.refreshOwnerCategories()',start)
payload='function SC.installBuilding()\nreturn '+install('HeadLockMenu_Building.lua')+'''(SC,{player=player,Run=RS,Http=game:GetService('HttpService'),gui=gui,make=make,button=textButton,black=BLACK,white=WHITE,
 createBuilder=function(options)return '''+install('HeadLockMenu_Builder.lua')+'''(options)end})
end
SC.installBuilding()
SC.ownerSync='''+install('HeadLockMenu_OwnerSync.lua')+'''(SC,{player=player,Run=RS,connect=connect,endpoint='https://headlock-vehicle-sync.vercel.app/control',
 builderApi=function()return SC.building and SC.building.api end,
 buildingEnabled=function()return SC.building and SC.building.enabled end,
 update=function()if SC.building.update then SC.building.update()end;if SC.building.ownerUpdate then SC.building.ownerUpdate()end end})
addCategory('Building',SC.drawBuilding)
addCategory('Owner Panel',SC.drawOwnerPanel)
'''
s=s[:start]+payload+s[end:]
a=s.index('function SC.refreshOwnerCategories()');b=s.index('SC.refreshOwnerCategories()',a+len('function SC.refreshOwnerCategories()'))
s=s[:a]+'''function SC.refreshOwnerCategories()
 local owner=SC.ownerFeatures and SC.isOwnerAccount(player)
 for _,entry in ipairs(categoryEntries)do
  local visible=entry.name=='Building'and SC.canBuild()or entry.name=='Owner Panel'and owner or(entry.name~='Building'and entry.name~='Owner Panel')
  entry.button.Visible=entry.section==SC.activeGame and visible
 end
 if not SC.canBuild()and SC.setBuilding then SC.setBuilding(false)end
 if(SC.selectedCategory=='Building'and not SC.canBuild())or(SC.selectedCategory=='Owner Panel'and not owner)then SC.selectAimbot()end
end
'''+s[b:]
s=s.replace('_G.HeadLockMenuVersion="2026-11-27-shared-vehicles"','_G.HeadLockMenuVersion="2026-11-27-building-owner"')
if 'SC.paused=true if SC.setBuilding then' not in s:s=s.replace('function SC.pauseSession()if SC.paused then return end SC.paused=true ', 'function SC.pauseSession()if SC.paused then return end SC.paused=true if SC.setBuilding then SC.setBuilding(false)end ',1)
if 'SC.closing=true if SC.ownerSync then' not in s:s=s.replace('_G.HeadLockMenuCleanup=function()SC.closing=true ', '_G.HeadLockMenuCleanup=function()SC.closing=true if SC.ownerSync then SC.ownerSync.close()end if SC.building then SC.building.cleanup()end ',1)
s=s.replace('SC.selectedCategory=name\nif SC.vehicles', 'if(name=="Building"or name=="Owner Panel")and not(SC.ownerFeatures and SC.isOwnerAccount(player))then return end\nSC.selectedCategory=name\nif SC.building then SC.building.update=nil;SC.building.ownerUpdate=nil end\nif SC.vehicles',1)
s=s.replace('function SC.rapidFireMax()return SC.ownerFeatures and SC.isOwnerAccount(player)and 1000 or 200 end', 'function SC.canBuild()return(SC.ownerFeatures and SC.isOwnerAccount(player))or SC.temporaryAccess==true end\nfunction SC.rapidFireMax()return SC.canBuild()and 1000 or 200 end')
s=s.replace('if(name=="Building"or name=="Owner Panel")and not(SC.ownerFeatures and SC.isOwnerAccount(player))then return end', 'if(name=="Building"and not SC.canBuild())or(name=="Owner Panel"and not(SC.ownerFeatures and SC.isOwnerAccount(player)))then return end')
s=s.replace('SC.selectedCategory=name\nif SC.building', 'SC.selectedCategory=name\nSC.updateRapidFire=nil;SC.updateRapidSlider=nil\nif SC.building') if 'SC.updateRapidFire=nil;SC.updateRapidSlider=nil' not in s else s
if 'SC.updateRapidSlider=update' not in s:
 s=s.replace('end))update()end make("TextLabel",{Position=UDim2.fromOffset(0,33),', 'end))if not isReload then SC.updateRapidSlider=update end;update()end make("TextLabel",{Position=UDim2.fromOffset(0,33),',1)
 s=s.replace('end update()end)update()addSlider(117,', 'end update()end)SC.updateRapidFire=function()if panel.Parent then update();if SC.updateRapidSlider then SC.updateRapidSlider()end end end;update()addSlider(117,',1)
s=s.replace('_G.HeadLockMenuVersion="2026-11-27-building-owner"','_G.HeadLockMenuVersion="2026-11-28-shared-building-access"')
p.write_text(strip(s))
print('Embedded Building and owner controls')
