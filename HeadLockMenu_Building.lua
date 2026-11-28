return function(SC,ctx)
local state={enabled=false,saves={},selected=nil,status='',saveBusy=false,listBusy=false}
SC.building=state
local function ownerAllowed()return SC.isOwnerAccount(ctx.player)and SC.ownerFeatures and not SC.closing and not SC.paused end
local function allowed()return SC.canBuild()and not SC.closing and not SC.paused end
local function update()if state.update then state.update()end;if state.ownerUpdate then state.ownerUpdate()end end
local function report(text)state.status=text or'';update()end
local function api()
 if not state.api then
  assert(SC.canBuild(),'Building access required')
  state.api=ctx.createBuilder({enabled=false,hideShortcut=true})
 end
 return state.api
end
local function localSaves()
 local data=_G.HeadLockNamedBuilds
 if type(data)~='table'and type(readfile)=='function'then local ok,value=pcall(function()return ctx.Http:JSONDecode(readfile('HeadLockNamedBuilds_v1.json'))end);if ok then data=value end end
 if type(data)~='table'then data={}end
 _G.HeadLockNamedBuilds=data;return data
end
local function cacheSave(saved,doc)
 local all=localSaves();local key=tostring(ctx.player.UserId)..':'..tostring(game.PlaceId)
 all[key]=all[key]or{};all[key][saved.id]={id=saved.id,name=saved.name,updatedAt=saved.updatedAt,parts=#doc.parts,doc=doc}
 if type(writefile)=='function'then pcall(writefile,'HeadLockNamedBuilds_v1.json',ctx.Http:JSONEncode(all))end
end
function SC.setBuilding(value)
 value=value==true and allowed()
 if not value then if state.enabled and SC.ownerSync then SC.ownerSync.pendingBuild=true end;state.enabled=false;if state.api then state.api.setEnabled(false)end;if state.prompt then state.prompt:Destroy();state.prompt=nil end;update();return false end
 local ok,why=pcall(function()
  local builder=api();local net=SC.ownerSync;local principal=net and net.buildOwner or ctx.player.UserId;local shared=net and net.docs[tostring(principal)]
  if shared and(net.editingOwner~=principal or #builder.document().parts==0)then builder.sync(shared,true)
  elseif SC.temporaryAccess and(not net or net.editingOwner~=principal)then builder.sync({format='HeadLockTrack',version=1,placeId=game.PlaceId,name='Build',parts={}},true)end
  if net then net.attach()end
  builder.setEnabled(true);builder.openMenu();state.enabled=true
 end)
 if not ok then report(tostring(why));return false end
 update();return true
end
function SC.setTemporaryAccess(value,principal)
 value=value==true and not SC.isOwnerAccount(ctx.player)
 local before=SC.temporaryAccess==true
 if before==value and state.accessPrincipal==principal then return end
 if before and(not value or state.accessPrincipal~=principal)then
  SC.setBuilding(false)
  if state.api then state.api.sync({format='HeadLockTrack',version=1,placeId=game.PlaceId,name='Build',parts={}},true)end
  if SC.ownerSync then SC.ownerSync.detach()end
  SC.rapidFirePower=100;SC.rapidFireEnabled=false
  if SC.setAutoWin then SC.setAutoWin(false)end
 end
 SC.temporaryAccess=value;state.accessPrincipal=principal
 if SC.refreshOwnerCategories then SC.refreshOwnerCategories()end
 if SC.updateRapidFire then SC.updateRapidFire()end
 update()
end
function state.save(name,saveId)
 if not ownerAllowed()or state.saveBusy then return end
 name=tostring(name or''):match('^%s*(.-)%s*$'):gsub('%c',''):sub(1,80)
 if name==''then report('Enter a name');return end
 local net=SC.ownerSync;if not net or not net.owner then report('Private owner access required');return end
 local ok,doc=pcall(function()return api().document()end);if not ok then report(tostring(doc));return end
 doc.name=name;saveId=saveId or ctx.Http:GenerateGUID(false):gsub('[{}%-]','')
 state.saveBusy=true;report('Saving')
 net.enqueue('save',{saveId=saveId,name=name,doc=doc},function(success,data)
  state.saveBusy=false
  if success then cacheSave(data.saved,doc);state.selected=data.saved;report('Saved '..name);if state.prompt then state.prompt:Destroy();state.prompt=nil end;state.list()
  else report('Save failed: '..tostring(data))end
 end)
end
function state.list()
 if not ownerAllowed()or state.listBusy then return end
 local net=SC.ownerSync;if not net or not net.owner then report('Private owner access required');return end
 state.listBusy=true
 net.enqueue('list',{},function(success,data)
  state.listBusy=false
  if success then state.saves=data.saves or{};state.status=''else state.status='Saves unavailable: '..tostring(data)end
  update()
 end)
end
function state.load(chosen)
 if not ownerAllowed()or state.saveBusy then return end
 chosen=type(chosen)=='table'and chosen or state.selected;if not chosen then report('Choose a save');return end
 local net=SC.ownerSync
 if not net or not net.owner then report('Private owner access required');return end
 state.saveBusy=true;report('Loading')
 net.enqueue('load',{saveId=chosen.id},function(success,data)
  state.saveBusy=false
  if not success then report('Load failed: '..tostring(data));return end
  if not ownerAllowed()then return end
  local ok,why=pcall(function()local builder=api();local shared=net.docs[tostring(net.buildOwner)];if net.editingOwner~=net.buildOwner and shared then builder.sync(shared,true)end;net.attach();builder.import(data.doc)end)
  if ok then net.pendingBuild=true;report('Loaded '..chosen.name)else report('Load failed: '..tostring(why))end
 end)
end
function state.loadPrompt(chosen)
 if not ownerAllowed()or state.saveBusy then return end
 chosen=chosen or state.selected;if not chosen then report('Choose a save');return end
 if state.prompt then state.prompt:Destroy()end
 local make,button=ctx.make,ctx.button
 local frame=make('Frame',{Name='BuildLoadPrompt',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(300,178),BackgroundColor3=ctx.black,ZIndex=25,Active=true},ctx.gui);state.prompt=frame
 make('UIStroke',{Color=ctx.white,Thickness=1},frame)
 make('TextLabel',{Text='Would you like to load this save?',Position=UDim2.fromOffset(12,10),Size=UDim2.new(1,-24,0,48),BackgroundTransparency=1,TextWrapped=true,TextColor3=ctx.white,TextSize=16,Font=Enum.Font.Code,ZIndex=26},frame)
 make('TextLabel',{Text=chosen.name,Position=UDim2.fromOffset(12,62),Size=UDim2.new(1,-24,0,34),BackgroundTransparency=1,TextTruncate=Enum.TextTruncate.AtEnd,TextColor3=ctx.white,TextSize=14,Font=Enum.Font.Code,ZIndex=26},frame)
 local yes=button('Yes',frame);yes.Name='ConfirmLoadBuild';yes.Position=UDim2.fromOffset(12,124);yes.Size=UDim2.fromOffset(130,34);yes.ZIndex=26
 local cancel=button('Cancel',frame);cancel.Position=UDim2.fromOffset(158,124);cancel.Size=UDim2.fromOffset(130,34);cancel.ZIndex=26
 local function close()frame:Destroy();if state.prompt==frame then state.prompt=nil end end
 yes.Activated:Connect(function()if state.prompt~=frame then return end;close();state.load(chosen)end)
 cancel.Activated:Connect(close)
end
function state.namePrompt()
 if not ownerAllowed()then return end
 if state.prompt then state.prompt:Destroy()end
 local make,button=ctx.make,ctx.button
 local frame=make('Frame',{Name='BuildNamePrompt',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(300,156),BackgroundColor3=ctx.black,ZIndex=25,Active=true},ctx.gui);state.prompt=frame
 make('UIStroke',{Color=ctx.white,Thickness=1},frame)
 make('TextLabel',{Text='Build name',Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,26),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=16,Font=Enum.Font.Code,ZIndex=26},frame)
 local name=make('TextBox',{Name='BuildSaveName',Text='',PlaceholderText='Name',ClearTextOnFocus=false,Position=UDim2.fromOffset(12,44),Size=UDim2.new(1,-24,0,34),BackgroundColor3=ctx.black,TextColor3=ctx.white,TextSize=15,Font=Enum.Font.Code,ZIndex=26},frame);make('UIStroke',{Color=ctx.white,Thickness=1},name)
 local save=button('Save',frame);save.Position=UDim2.fromOffset(12,100);save.Size=UDim2.fromOffset(130,34);save.ZIndex=26
 local cancel=button('Cancel',frame);cancel.Position=UDim2.fromOffset(158,100);cancel.Size=UDim2.fromOffset(130,34);cancel.ZIndex=26
 local existing
 name:GetPropertyChangedSignal('Text'):Connect(function()existing=nil;save.Text='Save'end)
 save.Activated:Connect(function()
  local text=name.Text:match('^%s*(.-)%s*$');local match
  for _,item in ipairs(state.saves)do if item.name:lower()==text:lower()then match=item;break end end
  if match and existing~=match.id then existing=match.id;save.Text='Overwrite';return end
  state.save(text,match and match.id or nil)
 end)
 cancel.Activated:Connect(function()frame:Destroy();if state.prompt==frame then state.prompt=nil end end)
 name:CaptureFocus()
end
function SC.drawBuilding(container)
 if not allowed()then return end
 local make,button=ctx.make,ctx.button
 local panel=make('ScrollingFrame',{Name='BuildingSettings',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,500)},container)
 make('TextLabel',{Text='Building',Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)
 local toggle=button('OFF',panel);toggle.Name='BuildingToggle';toggle.Position=UDim2.fromOffset(0,38);toggle.Size=UDim2.fromOffset(105,36)
 local save=button('Save Build',panel);save.Name='SaveBuild';save.Position=UDim2.fromOffset(0,90);save.Size=UDim2.new(.5,-3,0,34)
 local saves=button('Saves',panel);saves.Position=UDim2.new(.5,3,0,90);saves.Size=UDim2.new(.5,-3,0,34)
 local list=make('ScrollingFrame',{Name='BuildSaves',Position=UDim2.fromOffset(0,134),Size=UDim2.new(1,-3,0,232),CanvasSize=UDim2.new(),BorderSizePixel=0,ScrollBarThickness=3,BackgroundTransparency=1,Visible=false},panel)
 local load=button('Load Build',panel);load.Name='LoadBuild';load.Position=UDim2.fromOffset(0,376);load.Size=UDim2.new(1,0,0,34)
 local status=make('TextLabel',{Name='BuildingStatus',Position=UDim2.fromOffset(0,420),Size=UDim2.new(1,0,0,64),BackgroundTransparency=1,TextWrapped=true,TextColor3=ctx.white,TextSize=13,Font=Enum.Font.Code},panel)
 local cloud=ownerAllowed();save.Visible=cloud;saves.Visible=cloud;load.Visible=cloud
 local rows={};local last=''
 state.update=function()
  if not panel.Parent then state.update=nil;return end
  toggle.Text=state.enabled and'ON'or'OFF';toggle.BackgroundColor3=state.enabled and ctx.white or ctx.black;toggle.TextColor3=state.enabled and ctx.black or ctx.white
  status.Text=state.status~=''and state.status or(SC.ownerSync and SC.ownerSync.error or'')
  local key=ctx.Http:JSONEncode(state.saves)..':'..tostring(state.selected and state.selected.id)
  if key~=last then
   last=key;for _,row in ipairs(rows)do row:Destroy()end;rows={}
   for i,item in ipairs(state.saves)do
    local row=button(item.name,list);row.Name='BuildSave_'..item.id;row.Position=UDim2.fromOffset(0,(i-1)*38);row.Size=UDim2.new(1,-6,0,34);row.TextXAlignment=Enum.TextXAlignment.Left;row.TextTruncate=Enum.TextTruncate.AtEnd
    local selected=state.selected and state.selected.id==item.id;row.BackgroundColor3=selected and ctx.white or ctx.black;row.TextColor3=selected and ctx.black or ctx.white
    row.Activated:Connect(function()state.selected=item;update();state.loadPrompt(item)end);table.insert(rows,row)
   end
   list.CanvasSize=UDim2.fromOffset(0,#state.saves*38)
  end
 end
 toggle.Activated:Connect(function()SC.setBuilding(not state.enabled)end)
 save.Activated:Connect(function()state.namePrompt()end)
 saves.Activated:Connect(function()list.Visible=not list.Visible;if list.Visible then state.list()end end)
 load.Activated:Connect(function()state.loadPrompt()end)
 state.update();if state.enabled and state.api then state.api.openMenu()end
end
function SC.drawOwnerPanel(container)
 if not ownerAllowed()then return end
 local make,button=ctx.make,ctx.button
 local panel=make('Frame',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},container)
 make('TextLabel',{Text='Owner Panel',Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=20,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},panel)
 local status=make('TextLabel',{Name='OwnerStatus',Position=UDim2.fromOffset(0,34),Size=UDim2.new(1,0,0,38),TextWrapped=true,BackgroundTransparency=1,TextColor3=ctx.white,TextSize=12,Font=Enum.Font.Code},panel)
 local list=make('ScrollingFrame',{Name='OwnerUsers',Position=UDim2.fromOffset(0,80),Size=UDim2.new(1,0,1,-80),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.new()},panel)
 local last='';local rows={}
 state.ownerUpdate=function()
  if not panel.Parent then state.ownerUpdate=nil;return end
  local net=SC.ownerSync;status.Text=net and net.error or'Connecting'
  local users=net and net.roster or{};local visible={}
  for _,user in ipairs(users)do table.insert(visible,{user.session,user.username,user.owner,user.actual.paused,user.actual.soundsPaused,user.pending,user.access})end
  local fingerprint=ctx.Http:JSONEncode(visible)
  if fingerprint==last then return end;last=fingerprint
  for _,row in ipairs(rows)do row:Destroy()end;rows={}
  local count=0
  for _,user in ipairs(users)do if not user.owner then
   local frame=make('Frame',{Name='OwnerUser_'..user.session,Position=UDim2.fromOffset(0,count*128),Size=UDim2.new(1,-6,0,122),BackgroundTransparency=1},list);table.insert(rows,frame);count+=1
   make('TextLabel',{Text=user.username,Position=UDim2.fromOffset(0,0),Size=UDim2.new(.62,0,0,28),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,BackgroundTransparency=1,TextColor3=ctx.white,TextSize=14,Font=Enum.Font.Code},frame)
   local flags=(user.actual.paused and'Paused'or'Active')..(user.actual.soundsPaused and' / Muted'or'')..(user.pending and' …'or'')
   make('TextLabel',{Text=flags,Position=UDim2.new(.62,0,0,0),Size=UDim2.new(.38,0,0,28),BackgroundTransparency=1,TextColor3=ctx.white,TextSize=10,Font=Enum.Font.Code},frame)
   for i,item in ipairs({{'Pause','pause'},{'Resume','resume'},{'Mute','mute'},{'Unmute','unmute'},{'Kick','kick'}})do
    local b=button(item[1],frame);b.Name='Owner_'..item[2];b.Position=UDim2.new((i-1)/5,0,0,36);b.Size=UDim2.new(.2,-3,0,34);b.TextSize=11
    b.Activated:Connect(function()if ownerAllowed()and net then net.command(user.session,item[2])end end)
   end
   local access=button(user.access and'Revoke Access'or'Give Access',frame);access.Name='Owner_access';access.Position=UDim2.fromOffset(0,76);access.Size=UDim2.new(1,-3,0,32);access.TextSize=12
   access.Activated:Connect(function()if ownerAllowed()and net then net.command(user.session,user.access and'revoke'or'grant')end end)
   if user.room~=net.room and not user.access then access.Text='Different server';access.Active=false end
  end end
  list.CanvasSize=UDim2.fromOffset(0,count*128)
 end
 state.ownerUpdate()
end
function state.cleanup()
 state.update=nil;state.ownerUpdate=nil
 if state.prompt then state.prompt:Destroy();state.prompt=nil end
 if state.api then state.api.cleanup();state.api=nil end
end
return state
end
