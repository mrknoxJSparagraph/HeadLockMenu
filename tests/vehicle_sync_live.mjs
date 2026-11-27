import fs from 'node:fs';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {LuauState} from 'luau-web';
const endpoint=process.env.VEHICLE_RELAY_URL;
assert(endpoint?.startsWith('https://'),'Set VEHICLE_RELAY_URL');
function plain(value){
 if(value&&typeof value.keys==='function'&&typeof value.get==='function'){
  const keys=value.keys();
  if(keys.length&&keys.every(k=>typeof k==='number'))return keys.sort((a,b)=>a-b).map(k=>plain(value.get(k)));
  return Object.fromEntries(keys.map(k=>[k,plain(value.get(k))]));
 }
 return value;
}
function literal(value){
 if(value===null||value===undefined)return 'nil';
 if(Array.isArray(value))return '{'+value.map(literal).join(',')+'}';
 if(typeof value==='object')return '{'+Object.entries(value).map(([k,v])=>'['+JSON.stringify(k)+']='+literal(v)).join(',')+'}';
 return JSON.stringify(value);
}
const state=await LuauState.createAsync({print:console.log,_clock:()=>performance.now()/1000,_guid:()=>randomUUID(),
 _encode:v=>JSON.stringify(plain(v)),_decode:async text=>(await state.loadstring('return '+literal(JSON.parse(text)),'HTTP JSON',true)())[0],
 _request:async(url,body)=>{
  const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body,signal:AbortSignal.timeout(4000)});
  return JSON.stringify({StatusCode:response.status,Body:await response.text()});
 }});
try{
 const source=fs.readFileSync('HeadLockMenu_VehicleSync.lua','utf8');
 await state.loadstring(`
os=table.clone(os);os.clock=_clock
task={spawn=function(fn)fn()end}
game={PlaceId=4678052190,JobId=${JSON.stringify('live_vm_'+randomUUID())}}
local function decode(text)return _decode(text)end
request=function(req)return decode(_request(req.Url,req.Body))end
local http={JSONEncode=function(_,v)return _encode(v)end,JSONDecode=function(_,v)return decode(v)end,GenerateGUID=_guid}
local install=(function()${source}end)()
local pose={cf={0,10,0,1,0,0,0,1,0,0,0,1},vel={0,0,0},av={0,0,0}}
local function client(id)
 local c={manual=true,Http=http,player={UserId=id},endpoint=${JSON.stringify(endpoint)}}
 c.current=function()return c.active end;c.pose=function(v)return v.pose end
 c.enter=function(v)c.active=v;return true end
 c.report=function(v)c.message=v end
 c.remove=function(v)v.dead=true end
 c.reconcile=function(records,net)for key,r in pairs(records)do
  local v=net.vehicles[key];if not v then v={kind=r.kind,pose=pose};net:attach(v,r)end
  v.observed=r.cf
 end end
 c.net=install(c);return c
end
local a,b=client(1),client(2)
local ok,why=pcall(function()
 a.net.tick();b.net.tick();assert(a.net.connected and b.net.connected,tostring(a.net.error)..' '..tostring(b.net.error))
 local v={kind='Car',pose=pose};a.net:register(v);a.net.tick();b.net.tick()
 local other=b.net.vehicles[v.netId];assert(other and v.published,'peer car missing')
 a.net:claim(v);a.net.tick();assert(a.active==v,tostring(a.message))
 v.pose={cf={20,10,0,1,0,0,0,1,0,0,0,1},vel={0,0,0},av={0,0,0}}
 a.net.tick();b.net.tick();assert(other.observed[1]==20,'peer car did not move')
 a.net:release(v);a.active=nil;a.net.tick();b.net.tick()
 b.net:claim(other);b.net.tick();assert(b.active==other and b.net:isDriver(other),tostring(b.message))
 b.net:release(other);b.active=nil;b.net.tick();a.net.tick()
 a.net:delete(v);a.net.tick();b.net.tick();assert(v.dead and other.dead,'peer car was not deleted')
end)
a.net:close();b.net:close();assert(ok,why)
print('PASS actual Lua coordinator over live HTTPS: peer spawn, movement, seat acquisition, driver handoff and deletion')
`, 'live vehicle networking',true)();
}finally{state.destroy();}
