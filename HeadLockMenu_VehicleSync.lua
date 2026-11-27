return function(ctx)
local Http=ctx.Http
local net={enabled=true,connected=false,vehicles={},records={},queue={},closed=false,pending=false,nextClaim=0}
if type(ctx.endpoint)~='string' or not ctx.endpoint:match('^https://') then
    net.enabled=false;net.error='Shared unavailable';return net
end
local send=type(request)=='function' and request or type(http_request)=='function' and http_request
    or type(syn)=='table' and syn.request or type(http)=='table' and http.request
if type(send)~='function' then net.enabled=false;net.error='Shared unavailable';return net end
local function guid()return (Http:GenerateGUID(false):gsub('[{}%-]',''))end
net.session=guid();local secret=guid()
local room=tostring(game.PlaceId)..':'..tostring(game.JobId)
if type(game.JobId)~='string' or #game.JobId<8 then net.enabled=false;net.error='Shared needs a live server';return net end
local endpoint=ctx.endpoint
local function rpc(op,fields)
    local body={room=room,session=net.session,secret=secret,user=ctx.player.UserId,op=op}
    for key,value in pairs(fields or {}) do body[key]=value end
    local response=send({Url=endpoint,Method='POST',Headers={['Content-Type']='application/json'},Body=Http:JSONEncode(body),Timeout=4})
    assert(type(response)=='table' and (response.StatusCode or response.Status)==200,'Shared connection unavailable')
    local data=Http:JSONDecode(response.Body)
    assert(type(data)=='table' and type(data.cars)=='table','Shared response unavailable')
    return data
end
local function enqueue(op,v,fields)
    table.insert(net.queue,{op=op,v=v,fields=fields or {id=v and v.netId}})
end
function net:isDriver(v)
    return self.enabled and self.connected and not self.closed and v and v.networked and v.leaseUntil
        and os.clock()<v.leaseUntil and v.netDriver==self.session and v.epoch~=nil
end
function net:attach(v,record)
    self.vehicles[record.id]=v;v.netId=record.id;v.networked=true;v.published=true
    v.netOwner=record.owner;v.netDriver=record.driver;v.epoch=record.epoch;v.netRecord=record
end
function net:register(v)
    if not self.enabled or self.closed then return false end
    v.netId=guid();v.networked=true;v.netOwner=self.session;v.published=false
    self.vehicles[v.netId]=v
    enqueue('spawn',v,{id=v.netId,kind=v.kind,pose=ctx.pose(v)})
    return true
end
function net:claim(v)
    if not self.enabled or self.closed or not self.connected or not v.published or self.pending
        or ctx.current() or os.clock()<self.nextClaim then return end
    self.nextClaim=os.clock()+.7
    if v.netDriver and v.netDriver~=self.session then ctx.report('Occupied');return end
    self.pending=true;enqueue('claim',v)
end
function net:release(v)
    if not v or not v.networked then return end
    local epoch=v.epoch
    v.leaseUntil=0
    if not self.closed then enqueue('release',v,{id=v.netId,epoch=epoch,pose=ctx.pose(v)}) end
end
function net:delete(v)
    if not v or not v.networked then return false end
    if v.netOwner~=self.session then ctx.report('Not your vehicle');return true end
    if v.netDriver and v.netDriver~=self.session then ctx.report('Occupied');return true end
    if not v.deleting then v.deleting=true;enqueue('delete',v)end
    return true
end
function net:close()
    if self.closed then return end
    self.closed=true;self.connected=false
    task.spawn(function()pcall(rpc,'leave')end)
end
local function receive(data)
    local records={}
    for _,record in ipairs(data.cars) do
        if type(record)=='table' and type(record.id)=='string' and (record.kind=='Car' or record.kind=='Bike')
            and type(record.cf)=='table' and #record.cf==12 then records[record.id]=record end
    end
    net.records=records
    for id,v in pairs(net.vehicles) do
        local record=records[id]
        if record then
            v.netOwner=record.owner;v.netDriver=record.driver;v.netRecord=record
            if not ctx.current() or ctx.current()~=v then v.epoch=record.epoch end
        elseif v.published then
            net.vehicles[id]=nil;ctx.remove(v)
        end
    end
    ctx.reconcile(records,net)
end
local function tick()
    local active=ctx.current()
    local item
    local renew=net:isDriver(active) and active.leaseUntil-os.clock()<1.4
    if net.connected and not renew then item=table.remove(net.queue,1) end
    local fields=item and item.fields or {}
    local op=not net.connected and 'join' or item and item.op or 'sync'
    local moving
    if op=='sync' and net:isDriver(active) then
        active.netSeq=(active.netSeq or 0)+1
        moving={id=active.netId,epoch=active.epoch,seq=active.netSeq,pose=ctx.pose(active)}
        fields={move=moving}
    end
    local started=os.clock()
    local ok,data=pcall(rpc,op,fields)
    if net.closed then return end
    if not ok then
        net.error=tostring(data)
        if item then
            if item.op=='claim' then net.pending=false end
            if item.op=='delete' and item.v then item.v.deleting=false end
            if item.op=='spawn' then table.insert(net.queue,item)end
        end
        ctx.report('Shared reconnecting')
        net.connected=false
        return
    end
    if op=='join' then net.connected=data.ok==true end
    if data.error=='authorization' then net.connected=false end
    if moving and active and data.ok and data.epoch==moving.epoch
        and active.netId==moving.id and ctx.current()==active then active.leaseUntil=started+2 end
    receive(data)
    if item then
        local v=item.v
        if item.op=='spawn' then
            if data.ok and net.records[v.netId] then v.published=true;ctx.report('Shared vehicle spawned')
            else ctx.remove(v);net.vehicles[v.netId]=nil;ctx.report('Shared spawn failed')end
        elseif item.op=='claim' then
            net.pending=false
            local record=v and net.records[v.netId]
            if data.ok and record and record.driver==net.session and os.clock()<started+2
                and not v.dead and not ctx.current() then
                v.epoch=data.epoch;v.netSeq=0;v.leaseUntil=started+2;v.netDriver=net.session
                if not ctx.enter(v)then net:release(v)end
            elseif data.ok and record and record.driver==net.session then net:release(v)
            else ctx.report(data.error=='occupied' and 'Occupied' or 'Seat unavailable')end
        elseif item.op=='delete' and v then
            v.deleting=false
            if not data.ok then ctx.report(data.error=='occupied' and 'Occupied' or 'Delete unavailable')end
        end
    end
end
net.tick=tick
if not ctx.manual then
    task.spawn(function()
        while not net.closed do
            local ok,why=pcall(tick)
            if not ok then net.connected=false;net.error=tostring(why);ctx.report('Shared reconnecting')end
            task.wait(net.connected and (ctx.current() and .12 or next(net.records) and .3 or 1.5) or 2)
        end
    end)
end
return net
end
