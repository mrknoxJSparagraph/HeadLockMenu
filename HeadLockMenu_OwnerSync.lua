return function(SC,ctx)
local Http=game:GetService('HttpService')
local state={enabled=false,connected=false,owner=false,canBuild=false,temporary=false,closed=false,busy=false,queue={},versions={},docs={},roster={},published={},lastDesired=0,replicas={},nextTick=0,elapsed=0,error='Connecting',buildOwner=ctx.player.UserId}
local send=type(request)=='function'and request or type(http_request)=='function'and http_request or type(syn)=='table'and syn.request or type(http)=='table'and http.request
state.close=function()state.closed=true end
local function report(text)state.error=text;if ctx.update then ctx.update()end end
if type(send)~='function'then report('Shared connection unavailable');return state end
if type(game.JobId)~='string'or #game.JobId<8 then report('Shared needs a live server');return state end
local function guid()return(Http:GenerateGUID(false):gsub('[{}%-]',''))end
state.enabled=true;state.session=guid();local secret=guid();local room=tostring(game.PlaceId)..':'..game.JobId;state.room=room
local access=_G.HeadLockOwnerAccess
if SC.isOwnerAccount(ctx.player)and(type(access)~='table'or type(access.key)~='string')and type(readfile)=='function'then
 local ok,value=pcall(function()return Http:JSONDecode(readfile('HeadLockOwnerAccess_v1.json'))end)
 if ok and type(value)=='table'and type(value.key)=='string'then access=value;_G.HeadLockOwnerAccess=value end
end
local function rpc(op,fields)
 local body={room=room,session=state.session,secret=secret,user=ctx.player.UserId,username=ctx.player.Name,op=op,versions=state.versions,actual={paused=SC.paused==true,soundsPaused=SC.soundsPaused==true},ack=state.lastDesired}
 if op=='join'and SC.isOwnerAccount(ctx.player)and type(access)=='table'then body.ownerKey=access.key end
 for key,value in pairs(fields or{})do body[key]=value end
 local response=send({Url=ctx.endpoint,Method='POST',Headers={['Content-Type']='application/json'},Body=Http:JSONEncode(body),Timeout=6})
 assert(type(response)=='table','Shared connection unavailable')
 local ok,data=pcall(function()return Http:JSONDecode(response.Body)end)
 assert(ok and type(data)=='table','Shared response unavailable')
 assert((response.StatusCode or response.Status)==200 and data.ok,data.error or'Shared connection unavailable')
 return data
end
local shared=Instance.new('Folder');shared.Name='HeadLockSharedBuilds';shared.Parent=workspace
local function fingerprint(p)
 local surface={};for _,name in ipairs({'TopSurface','BottomSurface','LeftSurface','RightSurface','FrontSurface','BackSurface'})do table.insert(surface,p.surfaces and p.surfaces[name]or'Smooth')end
 return Http:JSONEncode({p.class,p.name,p.shape or'Block',p.size,p.cf,p.color,p.material,p.materialVariant or'',p.transparency or 0,p.reflectance or 0,p.canCollide~=false,p.canTouch~=false,p.canQuery~=false,p.castShadow~=false,surface,p.physics or{}})
end
local function sigs(doc)
 local out={};for _,part in ipairs(doc.parts or{})do out[part.id]=fingerprint(part)end;return out
end
local function render(build)
 if build.owner==state.editingOwner and ctx.builderApi()then
  local old=state.replicas[tostring(build.owner)];if old then old.folder:Destroy();state.replicas[tostring(build.owner)]=nil end
  return
 end
 local key=tostring(build.owner);local r=state.replicas[key]
 if not r then local folder=Instance.new('Folder');folder.Name='Build_'..key;folder.Parent=shared;r={folder=folder,parts={},signatures={}};state.replicas[key]=r end
 local seen={}
 for _,d in ipairs(build.doc.parts or{})do
  seen[d.id]=true;local signature=fingerprint(d)
  if r.signatures[d.id]~=signature then
   local part=r.parts[d.id]
   if part and part.ClassName~=d.class then part:Destroy();part=nil end
   if not part then part=Instance.new(d.class);r.parts[d.id]=part end
   local ok=pcall(function()
    part.Name=d.name;part.Anchored=true;part.Size=Vector3.new(table.unpack(d.size));part.CFrame=CFrame.new(table.unpack(d.cf));part.Color=Color3.new(table.unpack(d.color))
    part.Material=Enum.Material[d.material];part.MaterialVariant=d.materialVariant or'';part.Transparency=d.transparency;part.Reflectance=d.reflectance
    part.CanCollide=d.canCollide;part.CanTouch=d.canTouch;part.CanQuery=d.canQuery;part.CastShadow=d.castShadow
    if part:IsA('Part')then part.Shape=Enum.PartType[d.shape or'Block']end
    for surface,value in pairs(d.surfaces or{})do part[surface]=Enum.SurfaceType[value]end
    part.CustomPhysicalProperties=d.physics and PhysicalProperties.new(table.unpack(d.physics))or nil
    part.Parent=r.folder
   end)
   if ok then r.signatures[d.id]=signature else part:Destroy();r.parts[d.id]=nil end
  end
 end
 for id,part in pairs(r.parts)do if not seen[id]then part:Destroy();r.parts[id]=nil;r.signatures[id]=nil end end
end
local function reconcile(doc,reference)
 local api=ctx.builderApi()
 if state.editingOwner==state.buildOwner and api then
  if api.isBusy()then state.deferred={doc=doc,reference=state.deferred and state.deferred.reference or reference};return end
  local current=api.document();local currentSigs=sigs(current);local base=reference.parts;local parts={}
  for _,part in ipairs(doc.parts)do parts[part.id]=part end
  for id in pairs(base)do if not currentSigs[id]then parts[id]=nil end end
  for _,part in ipairs(current.parts)do if currentSigs[part.id]~=base[part.id]then parts[part.id]=part end end
  local merged={format=doc.format,version=doc.version,placeId=doc.placeId,name=current.name~=reference.name and current.name or doc.name,parts={}}
  for _,part in pairs(parts)do table.insert(merged.parts,part)end
  api.sync(merged)
 end
 state.published=sigs(doc);state.publishedName=doc.name;state.deferred=nil
end
function state.attach()
 state.editingOwner=state.buildOwner;state.deferred=nil
 local doc=state.docs[tostring(state.buildOwner)]
 state.published=doc and sigs(doc)or{};state.publishedName=doc and doc.name or nil
 local replica=state.replicas[tostring(state.buildOwner)];if replica then replica.folder:Destroy();state.replicas[tostring(state.buildOwner)]=nil end
end
function state.detach()
 state.editingOwner=nil;state.deferred=nil;state.pendingBuild=false;state.published={};state.publishedName=nil
 for key,doc in pairs(state.docs)do render({owner=tonumber(key),doc=doc})end
end
local function receive(data,sent)
 if state.closed then return end
 local identity=data.self or{};local was=state.buildOwner
 state.connected=true;state.owner=identity.owner==true;state.canBuild=identity.building==true or state.owner;state.temporary=identity.temporary==true
 state.buildOwner=identity.buildOwner or ctx.player.UserId;state.permissionUntil=os.clock()+10
 if SC.setTemporaryAccess then SC.setTemporaryAccess(state.temporary,state.buildOwner)end
 if was~=state.buildOwner then state.deferred=nil end
 state.error=state.owner and'Connected'or(state.temporary and'Temporary access'or(SC.isOwnerAccount(ctx.player)and'Private owner access required'or'Connected'))
 if type(data.roster)=='table'then state.roster=data.roster end
 local reference=sent and{parts=sigs(sent),name=sent.name}or{parts=state.published,name=state.publishedName}
 local publication=data.publication
 if publication then
  state.versions[tostring(state.buildOwner)]=publication.revision
  if publication.doc then
   state.docs[tostring(state.buildOwner)]=publication.doc
   reconcile(publication.doc,publication.conflict and{parts=state.published,name=state.publishedName}or reference)
  elseif sent and not publication.conflict then state.published=sigs(sent);state.publishedName=sent.name end
  if not publication.conflict then state.pendingBuild=false end
 end
 for _,build in ipairs(data.builds or{})do
  if type(build)=='table'and type(build.owner)=='number'and type(build.doc)=='table'and build.doc.placeId==game.PlaceId then
   local key=tostring(build.owner);state.versions[key]=build.revision;state.docs[key]=build.doc
   if build.owner==state.buildOwner and not(publication and publication.doc)then reconcile(build.doc,reference)end
   render(build)
  end
 end
 local desired=data.desired
 if type(desired)=='table'and type(desired.revision)=='number'and desired.revision>state.lastDesired then
  if not SC.isOwnerAccount(ctx.player)then
   if type(desired.paused)=='boolean'then if desired.paused then SC.pauseSession()else SC.unlockSession()end end
   if type(desired.soundsPaused)=='boolean'then SC.setSoundsPaused(desired.soundsPaused)end
   if type(desired.kick)=='string'and state.lastKick~=desired.kick then state.lastKick=desired.kick;ctx.player:Kick('Disconnected by script owner. You can rejoin.')end
  end
  state.lastDesired=desired.revision
 end
 if ctx.update then ctx.update()end
end
function state.enqueue(op,fields,callback)
 if state.closed then return false end
 if not state.connected or not state.owner then report('Private owner access required');if callback then callback(false,state.error)end;return false end
 table.insert(state.queue,{op=op,fields=fields,callback=callback});state.nextTick=0;return true
end
function state.command(target,action)
 if not SC.ownerFeatures or not SC.isOwnerAccount(ctx.player)then return false end
 return state.enqueue('command',{target=target,action=action,requestId=guid()})
end
function state.adopt(doc)
 local key=tostring(state.buildOwner);state.docs[key]=doc;state.published=sigs(doc);state.publishedName=doc.name
end
local function expire()
 if state.temporary and os.clock()>=(state.permissionUntil or 0)then
  state.temporary=false;state.canBuild=false;if SC.setTemporaryAccess then SC.setTemporaryAccess(false,ctx.player.UserId)end
  report('Temporary access needs a connection')
 end
end
function state.tick()
 if state.closed or not state.enabled then return end
 expire()
 local api=ctx.builderApi()
 if state.deferred and api and not api.isBusy()then reconcile(state.deferred.doc,state.deferred.reference)end
 local item=state.connected and table.remove(state.queue,1)or nil
 local op=not state.connected and'join'or item and item.op or'poll';local fields=item and item.fields or{}
 local snapshot
 if op=='poll'and state.canBuild and(ctx.buildingEnabled()or state.pendingBuild)and state.editingOwner==state.buildOwner and api and not api.isBusy()then
  snapshot=api.document();local current=sigs(snapshot);local upsert,removed={},{}
  for _,part in ipairs(snapshot.parts)do if current[part.id]~=state.published[part.id]then table.insert(upsert,part)end end
  for id in pairs(state.published)do if not current[id]then table.insert(removed,id)end end
  if #upsert>0 or #removed>0 or snapshot.name~=state.publishedName then
   op='publish';fields={baseVersion=state.versions[tostring(state.buildOwner)]or 0,buildOwner=state.buildOwner,merge=true,upsert=upsert,removed=removed}
   if snapshot.name~=state.publishedName then fields.name=snapshot.name end
  else snapshot=nil;state.pendingBuild=false end
 end
 local ok,data=pcall(rpc,op,fields)
 if state.closed then return end
 if not ok then
  state.connected=false;report(tostring(data):gsub('^.-:%d+: ',''))
  if item and item.callback then item.callback(false,state.error)end
  return
 end
 receive(data,snapshot)
 if item and item.callback then item.callback(true,data)end
end
function state.close()
 if state.closed then return end
 state.closed=true;state.connected=false;shared:Destroy()
 for _,item in ipairs(state.queue)do if item.callback then pcall(item.callback,false,'Closed')end end;table.clear(state.queue)
 task.spawn(function()pcall(rpc,'leave')end)
end
state.sharedFolder=shared;state.receive=receive
ctx.connect(ctx.Run.Heartbeat,function(dt)
 if state.closed or not SC.authenticated then return end
 expire();state.elapsed+=dt;if state.elapsed<.2 or state.busy or os.clock()<state.nextTick then return end
 state.elapsed=0;state.busy=true;state.nextTick=os.clock()+(ctx.buildingEnabled()and .65 or 1.8)
 task.spawn(function()local ok,err=pcall(state.tick);state.busy=false;if not ok then state.connected=false;report(tostring(err))end;if not state.connected then state.nextTick=os.clock()+3 end end)
end)
return state
end
