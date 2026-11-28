import {createHash,timingSafeEqual} from 'node:crypto';
export const LIMIT=1500;
const id=v=>typeof v==='string'&&/^[a-zA-Z0-9_-]{8,100}$/.test(v)&&!['constructor','prototype','__proto__'].includes(v);
const hash=v=>createHash('sha256').update(v).digest('hex');
const ownerName=v=>typeof v==='string'&&(/^(nonobearbear|bluddyblud17)$/i.test(v)||/^nonobearbear(?:[1-9]|[1-9][0-9]|100)$/i.test(v));
const fail=message=>{throw new Error(message);};
const check=(condition,message)=>condition||fail(message);
const array=(v,n,min,max)=>Array.isArray(v)&&v.length===n&&v.every(x=>typeof x==='number'&&Number.isFinite(x)&&x>=min&&x<=max);
const surfaceNames=new Set(['Smooth','Studs','Inlet','Universal','Weld','Glue','SmoothNoOutlines','Hinge','Motor','SteppingMotor']);
const materials=new Set(['Plastic','SmoothPlastic','Neon','Wood','WoodPlanks','Marble','Slate','Concrete','Granite','Brick','Pebble','Cobblestone','CorrodedMetal','DiamondPlate','Foil','Metal','Grass','LeafyGrass','Sand','Fabric','Snow','Mud','Ground','Asphalt','Basalt','CrackedLava','Glacier','Salt','Sandstone','Limestone','Pavement','Ice','Glass','ForceField','Air','Water','RoofShingles','CeramicTiles','ClayRoofTiles','Plaster','Rubber','Carpet','Cardboard','Leather']);
export function document(raw,place){
 check(raw&&raw.format==='HeadLockTrack'&&raw.version===1&&raw.placeId===place&&Array.isArray(raw.parts)&&raw.parts.length<=LIMIT,'build');
 const seen=new Set();
 const parts=raw.parts.map(p=>{
  check(p&&typeof p.id==='string'&&p.id.length>0&&p.id.length<=100&&!seen.has(p.id)&&!['__proto__','constructor','prototype'].includes(p.id),'build');seen.add(p.id);
  check(['Part','WedgePart','CornerWedgePart'].includes(p.class)&&array(p.size,3,.05,2048)&&array(p.cf,12,-1e7,1e7)&&array(p.color,3,0,1),'build');
  const cf=p.cf;const axes=[[cf[3],cf[6],cf[9]],[cf[4],cf[7],cf[10]],[cf[5],cf[8],cf[11]]];
  const dot=(a,b)=>a.reduce((n,x,i)=>n+x*b[i],0);const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
  check(axes.every(a=>Math.abs(dot(a,a)-1)<.004)&&Math.abs(dot(axes[0],axes[1]))<.002&&Math.abs(dot(axes[0],axes[2]))<.002&&Math.abs(dot(axes[1],axes[2]))<.002&&dot(cross(axes[0],axes[1]),axes[2])>.998,'build');
  check(materials.has(p.material)&&typeof(p.materialVariant??'')==='string'&&(p.materialVariant??'').length<=100,'build');
  check(['Block','Ball','Cylinder'].includes(p.shape??'Block')&&[p.transparency??0,p.reflectance??0].every(x=>typeof x==='number'&&Number.isFinite(x)&&x>=0&&x<=1),'build');
  if(p.physics!=null)check(array(p.physics,5,0,100)&&p.physics[0]>=.01,'build');
  const surfaces={};for(const key of ['TopSurface','BottomSurface','LeftSurface','RightSurface','FrontSurface','BackSurface']){const value=p.surfaces?.[key]??'Smooth';check(surfaceNames.has(value),'build');surfaces[key]=value;}
  return {id:p.id,class:p.class,name:String(p.name??'Block').slice(0,80),...(p.class==='Part'?{shape:p.shape??'Block'}:{}),size:p.size,cf:p.cf,color:p.color,material:p.material,materialVariant:p.materialVariant??'',transparency:p.transparency??0,reflectance:p.reflectance??0,canCollide:p.canCollide!==false,canTouch:p.canTouch!==false,canQuery:p.canQuery!==false,castShadow:p.castShadow!==false,anchored:true,surfaces,...(p.physics?{physics:p.physics}:{})};
 });
 return {format:'HeadLockTrack',version:1,placeId:place,name:String(raw.name??'Build').slice(0,80),parts};
}
export const cas="local v=redis.call('GET',KEYS[1]);if(v or '')~=ARGV[1]then return {0,v or ''}end;if ARGV[3]=='0'then redis.call('SET',KEYS[1],ARGV[2])else redis.call('SET',KEYS[1],ARGV[2],'EX',ARGV[3])end;return {1,ARGV[2]}";
export async function update(redis,key,fn,ttl=360){
 let old=await redis(['GET',key]);
 for(let i=0;i<10;i++){
  const value=old?JSON.parse(old):null;const {state,result}=fn(value);
  const saved=await redis(['EVAL',cas,1,key,old??'',JSON.stringify(state),String(ttl)]);
  if(Number(saved[0])===1)return result;
  old=saved[1]||null;
 }
 fail('busy');
}
function validKey(value,expected){if(typeof value!=='string'||value.length<32||!expected||!/^[a-f0-9]{64}$/.test(expected))return false;return timingSafeEqual(Buffer.from(hash(value)),Buffer.from(expected));}
function parseRoom(room){check(typeof room==='string'&&/^\d+:[a-zA-Z0-9_-]{8,100}$/.test(room),'room');const place=Number(room.split(':')[0]);check(Number.isSafeInteger(place)&&place>0,'room');return place;}
const sessionsKey='headlock:control:sessions:v1';
export async function control(redis,input,env=process.env,clock=Date.now){
 check(input&&id(input.session)&&id(input.secret),'session');const place=parseRoom(input.room);const now=clock();
 const entry=await update(redis,sessionsKey,state=>{
  state??={sessions:{}};
  for(const [key,s]of Object.entries(state.sessions))if(s.at<now-45000)delete state.sessions[key];
  for(const s of Object.values(state.sessions))if(s.grant&&!state.sessions[s.grant.session]?.owner)delete s.grant;
  let s=Object.hasOwn(state.sessions,input.session)?state.sessions[input.session]:null;
  if(input.op==='join'){
   check(!s||s.secret===input.secret,'authorization');check(s||Object.keys(state.sessions).length<256,'room full');
   check(Number.isSafeInteger(input.user)&&input.user>0&&typeof input.username==='string'&&/^[a-zA-Z0-9_]{3,20}$/.test(input.username),'user');
   const owner=validKey(input.ownerKey,env.HEADLOCK_OWNER_KEY_SHA256)&&ownerName(input.username);
   if(input.ownerKey)check(owner,'owner authorization');
   if(!s)s=state.sessions[input.session]={secret:input.secret,user:input.user,username:input.username,room:input.room,owner,at:now,desired:{revision:0},actual:{paused:false,soundsPaused:false}};
   else check(s.user===input.user&&s.room===input.room,'authorization');
   if(owner)s.owner=true;
  }else check(s&&s.secret===input.secret&&s.room===input.room,'authorization');
  s.at=now;
  if(input.actual&&typeof input.actual==='object')s.actual={paused:input.actual.paused===true,soundsPaused:input.actual.soundsPaused===true};
  if(input.op==='command'){
   check(s.owner,'owner authorization');check(id(input.target)&&['pause','resume','mute','unmute','kick','grant','revoke'].includes(input.action),'command');
   const target=Object.hasOwn(state.sessions,input.target)?state.sessions[input.target]:null;check(target&&!target.owner,'target');
   if(input.action==='pause'||input.action==='resume')target.desired.paused=input.action==='pause';
   if(input.action==='mute'||input.action==='unmute')target.desired.soundsPaused=input.action==='mute';
   if(input.action==='kick')target.desired.kick=hash(input.requestId??String(now));
   if(input.action==='grant'){check(target.room===s.room,'target');target.grant={by:s.user,session:input.session,username:s.username};}
   if(input.action==='revoke')delete target.grant;
   target.desired.revision++;target.desired.by=s.user;
  }
  const self={user:s.user,username:s.username,owner:s.owner,building:s.owner||!!s.grant,temporary:!s.owner&&!!s.grant,buildOwner:s.grant?.by??s.user,buildUsername:s.grant?.username??s.username};
  const roster=s.owner?Object.entries(state.sessions).map(([session,p])=>({session,user:p.user,username:p.username,room:p.room,owner:p.owner,access:!!p.grant,actual:p.actual,pending:(p.ack??0)<p.desired.revision,at:p.at})).sort((a,b)=>a.username.localeCompare(b.username)):undefined;
  if(Number.isSafeInteger(input.ack)&&input.ack>=0)s.ack=Math.min(input.ack,s.desired.revision);
  const result={self,desired:s.desired,...(roster?{roster}:{})};
  if(input.op==='leave'){delete state.sessions[input.session];for(const p of Object.values(state.sessions))if(p.grant?.session===input.session){delete p.grant;p.desired.revision++;}}
  return {state,result};
 });
 const allowed=new Set(['join','poll','command','publish','save','list','load','delete-save','leave']);check(allowed.has(input.op),'operation');
 const base={ok:true,now,...entry};
 if(input.op==='leave')return base;
 if(input.op==='publish')check(entry.self.building,'owner authorization');
 if(['save','list','load','delete-save'].includes(input.op))check(entry.self.owner,'owner authorization');
 const roomKey='headlock:build:room:'+hash(input.room);
 if(input.op==='publish'){
  check(input.buildOwner==null||input.buildOwner===entry.self.buildOwner,'owner authorization');
  check(Number.isSafeInteger(input.baseVersion)&&input.baseVersion>=0&&Array.isArray(input.upsert)&&input.upsert.length<=LIMIT&&Array.isArray(input.removed)&&input.removed.length<=LIMIT,'build');
  base.publication=await update(redis,roomKey,state=>{
   state??={owners:{}};const key=String(entry.self.buildOwner);const previous=Object.hasOwn(state.owners,key)?state.owners[key]:{revision:0,doc:{format:'HeadLockTrack',version:1,placeId:place,name:'Build',parts:[]}};
   if(input.baseVersion!==previous.revision&&!(input.merge===true&&input.baseVersion<previous.revision))return {state,result:{conflict:true,revision:previous.revision,doc:previous.doc}};
   const map=new Map(previous.doc.parts.map(p=>[p.id,p]));for(const key of input.removed){check(typeof key==='string'&&key.length<=100,'build');map.delete(key);}
   for(const part of input.upsert){check(part&&typeof part.id==='string','build');map.set(part.id,part);}
   const doc=document({...previous.doc,name:input.name??previous.doc.name,parts:[...map.values()]},place);
   const total=Object.entries(state.owners).reduce((n,[id,v])=>n+(id===key?0:v.doc.parts.length),doc.parts.length);check(total<=3000,'room build limit');
   state.owners[key]={revision:previous.revision+1,doc,username:entry.self.buildUsername,at:now};
   return {state,result:{revision:previous.revision+1,doc}};
  },21600);
 }
 const saveIndex='headlock:saves:'+entry.self.user+':'+place;
 if(input.op==='save'){
  check(id(input.saveId)&&typeof input.name==='string','save');const name=input.name.trim();check(name.length>0&&name.length<=80&&!/[\x00-\x1f]/.test(name),'name');
  const doc=document(input.doc,place);doc.name=name;const key=saveIndex+':'+input.saveId;
  const old=await redis(['GET',key]);const prior=old?JSON.parse(old):null;
  const saved={id:input.saveId,name,updatedAt:now,createdAt:prior?.createdAt??now,parts:doc.parts.length,doc};
  await update(redis,key,()=>({state:saved,result:null}),0);
  await update(redis,saveIndex,rows=>{
   rows??=[];check(rows.length<100||rows.some(r=>r.id===input.saveId),'save limit');
   rows=rows.filter(r=>r.id!==input.saveId);rows.push({id:saved.id,name,updatedAt:now,parts:doc.parts.length});return {state:rows,result:null};
  },0);
  base.saved={id:saved.id,name,parts:doc.parts.length,updatedAt:now};
 }
 if(input.op==='list')base.saves=JSON.parse(await redis(['GET',saveIndex])||'[]').sort((a,b)=>b.updatedAt-a.updatedAt);
 if(input.op==='load'){
  check(id(input.saveId),'save');const saved=JSON.parse(await redis(['GET',saveIndex+':'+input.saveId])||'null');check(saved,'save missing');base.doc=document(saved.doc,place);base.saveId=input.saveId;
 }
 if(input.op==='delete-save'){
  check(id(input.saveId),'save');await update(redis,saveIndex,rows=>({state:(rows??[]).filter(r=>r.id!==input.saveId),result:null}),0);await redis(['DEL',saveIndex+':'+input.saveId]);
 }
 if(['join','poll','publish'].includes(input.op)){
  const live=JSON.parse(await redis(['GET',roomKey])||'{"owners":{}}');base.builds=[];
  for(const [owner,b]of Object.entries(live.owners))if(b.revision!==(input.versions?.[owner]??0))base.builds.push({owner:Number(owner),username:b.username,revision:b.revision,doc:b.doc});
 }
 return base;
}
