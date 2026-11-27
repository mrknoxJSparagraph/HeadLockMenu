import fs from 'node:fs';
import {LuauState} from 'luau-web';
const source=fs.readFileSync('HeadLockMenu_VehicleSync.lua','utf8');
const state=await LuauState.createAsync({print:console.log});
try{
 await state.loadstring(`
local clock=100
os=table.clone(os);os.clock=function()return clock end
local tasks={}
task={spawn=function(fn)table.insert(tasks,fn)end}
game={PlaceId=4678052190,JobId='same_server_12345'}
local uid=0
local http={JSONEncode=function(_,v)return v end,JSONDecode=function(_,v)return v end,GenerateGUID=function()uid+=1;return string.format('generated_%08d',uid)end}
local cars={};local sequences={};local down=false;local lag=0
request=function(req)
 assert(req.Method=='POST' and req.Timeout==4)
 local b=req.Body;assert(b.room=='4678052190:same_server_12345' and b.secret~=nil)
 if down then error('offline')end
 clock+=lag
 local ok,why,epoch=true,nil,nil
 if b.op=='spawn'then cars[b.id]={id=b.id,kind=b.kind,owner=b.session,driver=nil,epoch=0,cf=b.pose.cf,vel=b.pose.vel,av=b.pose.av}
 elseif b.op=='claim'then
  local c=cars[b.id]
  if not c then ok=false;why='missing'
  elseif c.driver and c.driver~=b.session then ok=false;why='occupied'
  else c.driver=b.session;c.epoch+=1;epoch=c.epoch end
 elseif b.op=='sync'and b.move then
  local m=b.move;local c=cars[m.id]
  if not c or c.driver~=b.session or c.epoch~=m.epoch then ok=false;why='lease lost'
  else c.cf=m.pose.cf;epoch=c.epoch;sequences[b.session]=m.seq end
 elseif b.op=='release'then
  local c=cars[b.id];if c and c.driver==b.session and c.epoch==b.epoch then c.driver=nil;c.epoch+=1 end
 elseif b.op=='delete'then
  local c=cars[b.id]
  if c and c.owner~=b.session then ok=false;why='not owner'
  elseif c and c.driver and c.driver~=b.session then ok=false;why='occupied'
  else cars[b.id]=nil end
 end
 local list={};for _,c in pairs(cars)do table.insert(list,table.clone(c))end
 return {StatusCode=200,Body={ok=ok,error=why,epoch=epoch,cars=list}}
end
local install=(function() ${source} end)()
local pose={cf={0,10,0,1,0,0,0,1,0,0,0,1},vel={0,0,0},av={0,0,0}}
local function client(id)
 local ctx={Http=http,player={UserId=id},manual=true,endpoint='https://relay.example/v1',active=nil,messages={}}
 ctx.current=function()return ctx.active end
 ctx.pose=function(v)return v.pose end
 ctx.enter=function(v)ctx.active=v;return true end
 ctx.remove=function(v)v.dead=true;if ctx.active==v then ctx.active=nil end end
 ctx.report=function(text)table.insert(ctx.messages,text)end
 ctx.reconcile=function(records,net)
  for key,record in pairs(records)do
   local v=net.vehicles[key]
   if not v then v={kind=record.kind,pose=pose};net:attach(v,record)end
   v.observed=record.cf
  end
 end
 ctx.net=install(ctx);return ctx
end
local a,b=client(1),client(2)
a.net.tick();b.net.tick();assert(a.net.connected and b.net.connected)
local v={kind='Car',pose=pose};assert(a.net:register(v));a.net.tick();b.net.tick()
local other=b.net.vehicles[v.netId];assert(other and other.published and v.published)
assert(a.net.records[v.netId] and b.net.records[v.netId])
a.net:claim(v);b.net:claim(other);a.net.tick();b.net.tick()
assert(a.active==v and b.active==nil,'two clients acquired one seat')
assert(a.net:isDriver(v) and not b.net:isDriver(other))
v.pose={cf={15,10,0,1,0,0,0,1,0,0,0,1},vel={0,0,0},av={0,0,0}}
a.net.tick();b.net.tick();assert(other.observed[1]==15,'remote car position was not synchronized')
assert(sequences[a.net.session]==1)
a.net:release(v);a.active=nil;a.net.tick();b.net.tick();clock+=1
b.net:claim(other);b.net.tick();assert(b.active==other and b.net:isDriver(other))
a.net:delete(v);a.net.tick();assert(not v.dead and cars[v.netId],'owner deleted a car while friend was driving')
local oldEpoch=v.epoch
v.netDriver=a.net.session;v.leaseUntil=clock+2;v.epoch=oldEpoch;a.active=v
clock+=2.1;assert(not a.net:isDriver(v),'expired client continued driving');a.active=nil
b.net:release(other);b.active=nil;b.net.tick();a.net.tick();clock+=1
lag=3
a.net:claim(v);a.net.tick();assert(a.active==nil,'late acquisition response activated an expired lease')
lag=0;a.net.tick();assert(cars[v.netId].driver==nil,'late claim was not released')
down=true;a.net.tick();assert(not a.net.connected)
down=false;a.net.tick();assert(a.net.connected)
a.net:delete(v);a.net.tick();b.net.tick();assert(v.dead and other.dead and not cars[v.netId])
a.net:close();assert(a.net.closed and not a.net.connected)
local d=client(4);d.net.tick()
local driven={kind='Car',pose=pose};d.net:register(driven);d.net.tick();d.net:claim(driven);d.net.tick()
assert(d.net:isDriver(driven));clock+=.8
local parked={kind='Bike',pose=pose};d.net:register(parked);d.net.tick()
assert(sequences[d.net.session]==1 and not parked.published,'queued spawn took priority over driver renewal')
d.net.tick();assert(parked.published and d.net:isDriver(driven))
local missing=install({Http=http,player={UserId=3}});assert(not missing.enabled and missing.error=='Shared unavailable')
print('PASS shared spawn visibility, one-seat contention, remote motion, handoff, ownership, lease deadlines, stale replies, reconnect, deletion and unavailable transport')
`, 'vehicle sync',true)();
}finally{state.destroy();}
