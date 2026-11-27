return function(SC,ctx)
local Http=game:GetService('HttpService')
local state={enabled=false,connected=false,owner=false,closed=false,busy=false,queue={},versions={},docs={},roster={},published={},lastDesired=0,replicas={},nextTick=0,elapsed=0,error='Connecting'}
local send=type(request)=='function'and request or type(http_request)=='function'and http_request or type(syn)=='table'and syn.request or type(http)=='table'and http.request
state.close=function()state.closed=true end
local function report(text)state.error=text;if ctx.update then ctx.update()end end
if type(send)~='function'then report('Shared connection unavailable');return state end
if type(game.JobId)~='string'or #game.JobId<8 then report('Shared needs a live server');return state end
local function guid()return(Http:GenerateGUID(false):gsub('[{}%-]',''))end
state.enabled=true;state.session=guid();local secret=guid();local room=tostring(game.PlaceId)..':'..game.JobId
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
 local localApi=ctx.builderApi()
 if build.owner==ctx.player.UserId and localApi then
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
local function receive(data)
 if state.closed then return end
 state.connected=true;state.owner=data.self and data.self.owner==true or false;state.error=state.owner and'Connected'or(SC.isOwnerAccount(ctx.player)and'Private owner access required'or'Connected')
 if type(data.roster)=='table'then state.roster=data.roster end
 for _,build in ipairs(data.builds or{})do
  if type(build)=='table'and type(build.owner)=='number'and type(build.doc)=='table'and build.doc.placeId==game.PlaceId then
   local key=tostring(build.owner);state.versions[key]=build.revision;state.docs[key]=build.doc
   if build.owner==ctx.player.UserId then state.published=sigs(build.doc);state.publishedName=build.doc.name end
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
 local key=tostring(ctx.player.UserId);state.docs[key]=doc;state.published=sigs(doc);state.publishedName=doc.name
end
function state.tick()
 if state.closed or not state.enabled then return end
 local item=state.connected and table.remove(state.queue,1)or nil
 local op=not state.connected and'join'or item and item.op or'poll';local fields=item and item.fields or{}
 local snapshot
 if op=='poll'and state.owner and(ctx.buildingEnabled()or state.pendingBuild)and not state.publishBlocked then
  local api=ctx.builderApi()
  if api then
   snapshot=api.document();local current=sigs(snapshot);local upsert,removed={},{}
   for _,part in ipairs(snapshot.parts)do if current[part.id]~=state.published[part.id]then table.insert(upsert,part)end end
   for id in pairs(state.published)do if not current[id]then table.insert(removed,id)end end
   if #upsert>0 or #removed>0 or snapshot.name~=state.publishedName then op='publish';fields={baseVersion=state.versions[tostring(ctx.player.UserId)]or 0,upsert=upsert,removed=removed,name=snapshot.name}end
  end
 end
 local ok,data=pcall(rpc,op,fields)
 if state.closed then return end
 if not ok then
  state.connected=false;report(tostring(data):gsub('^.-:%d+: ',''))
  if item and item.callback then item.callback(false,state.error)end
  return
 end
 if data.publication then
  local pub=data.publication;local key=tostring(ctx.player.UserId)
  state.versions[key]=pub.revision
  if pub.conflict then
   state.docs[key]=pub.doc;state.published=sigs(pub.doc);state.publishedName=pub.doc.name;state.publishBlocked=true
  elseif snapshot then state.published=sigs(snapshot);state.publishedName=snapshot.name;state.pendingBuild=false end
 end
 receive(data)
 if data.publication and data.publication.conflict then report('Shared build changed. Toggle Building off/on to reload.')end
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
 state.elapsed+=dt;if state.elapsed<.2 or state.busy or os.clock()<state.nextTick then return end
 state.elapsed=0;state.busy=true;state.nextTick=os.clock()+(ctx.buildingEnabled()and .65 or 1.8)
 task.spawn(function()local ok,err=pcall(state.tick);state.busy=false;if not ok then state.connected=false;report(tostring(err))end;if not state.connected then state.nextTick=os.clock()+3 end end)
end)
return state
end
