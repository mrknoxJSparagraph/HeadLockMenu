import test from 'node:test';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {control,document} from '../lib/control.js';
export function memoryRedis(){const values=new Map(),expires=new Map();let now=Date.now();const client=async cmd=>{const [op,key]=cmd;if(op==='GET'){if(expires.has(key)&&expires.get(key)<=now){values.delete(key);expires.delete(key);}return values.get(key)??null;}if(op==='DEL')return Number(values.delete(key));if(op==='EVAL'){const k=cmd[3],old=await client(['GET',k]);if((old??'')!==cmd[4])return[0,old??''];values.set(k,cmd[5]);if(Number(cmd[6]))expires.set(k,now+Number(cmd[6])*1000);else expires.delete(k);return[1,cmd[5]];}throw Error(op);};client.values=values;client.expires=expires;client.advance=ms=>now+=ms;return client;}
const key='isolated_test_owner_credential_1234567890';const env={HEADLOCK_OWNER_KEY_SHA256:createHash('sha256').update(key).digest('hex')};
const owner={session:'owner_session_123',secret:'owner_secret_123',user:100,username:'nonobearbear17',room:'12345:isolated_room_123',ownerKey:key};
const viewer={session:'viewer_session_123',secret:'viewer_secret_123',user:200,username:'OrdinaryUser',room:owner.room};
const part={id:'part_123',class:'Part',name:'Block',size:[2,3,4],cf:[5,6,7,1,0,0,0,1,0,0,0,1],color:[.1,.2,.3],material:'Concrete',shape:'Block',transparency:.1,reflectance:.2,canCollide:true,canTouch:false,canQuery:true,castShadow:false};
const doc={format:'HeadLockTrack',version:1,placeId:12345,name:'Road',parts:[part]};
test('owner control, persistence, revisions, room isolation and rejected identities',async()=>{
 const redis=memoryRedis();const rpc=(who,op,fields={})=>control(redis,{...who,op,...fields},env);
 assert.equal((await rpc(owner,'join')).self.owner,true);assert.equal((await rpc(viewer,'join')).self.owner,false);
 await assert.rejects(rpc({...viewer,secret:'wrong_secret'},'poll'),/authorization/);
 await assert.rejects(rpc({...viewer,session:'spoof_owner_session',secret:'spoof_owner_secret',username:'nonobearbear17'},'join',{ownerKey:'invalid_credential_12345678901234567890'}),/owner authorization/);
 await assert.rejects(rpc(viewer,'command',{target:owner.session,action:'kick'}),/owner authorization/);
 await assert.rejects(rpc(owner,'command',{target:owner.session,action:'pause'}),/target/);
 for(const [action,field,value]of [['pause','paused',true],['resume','paused',false],['mute','soundsPaused',true],['unmute','soundsPaused',false]]){await rpc(owner,'command',{target:viewer.session,action});assert.equal((await rpc(viewer,'poll')).desired[field],value);}
 await rpc(owner,'command',{target:viewer.session,action:'kick',requestId:'kick_request_123'});assert.equal(typeof(await rpc(viewer,'poll')).desired.kick,'string');
 let result=await rpc(owner,'publish',{baseVersion:0,upsert:[part],removed:[],name:'Road'});assert.equal(result.publication.revision,1);
 let received=await rpc(viewer,'poll');assert.equal(received.builds[0].doc.parts[0].cf[0],5);assert.equal(received.builds[0].doc.parts[0].canCollide,true);
 const isolated={...viewer,session:'isolated_session',room:'12345:different_room_123'};await rpc(isolated,'join');assert.deepEqual((await rpc(isolated,'poll')).builds,[]);
 await assert.rejects(rpc(viewer,'publish',{baseVersion:1,upsert:[],removed:[part.id]}),/owner authorization/);
 result=await rpc(owner,'publish',{baseVersion:0,upsert:[],removed:[]});assert.equal(result.publication.conflict,true);assert.equal(result.publication.doc.parts.length,1);
 assert.equal((await rpc(viewer,'poll',{versions:{100:1}})).builds.length,0);
 const invalid={...part,cf:[...part.cf]};invalid.cf[3]=-1;await assert.rejects(rpc(owner,'publish',{baseVersion:1,upsert:[invalid],removed:[]}),/build/);
 await rpc(owner,'save',{saveId:'named_save_123',name:'Road',doc});
 assert.equal((await rpc(owner,'list')).saves[0].name,'Road');assert.deepEqual((await rpc(owner,'load',{saveId:'named_save_123'})).doc,document(doc,12345));
 await assert.rejects(rpc(viewer,'list'),/owner authorization/);await assert.rejects(rpc(viewer,'load',{saveId:'named_save_123'}),/owner authorization/);
 assert([...redis.expires.keys()].every(key=>!key.startsWith('headlock:saves:')),'named saves unexpectedly expire');
 redis.advance(86400000);const owner2={...owner,session:'new_owner_session',secret:'new_owner_secret'};await rpc(owner2,'join');assert.equal((await rpc(owner2,'list')).saves.length,1);assert.equal((await rpc(owner2,'load',{saveId:'named_save_123'})).doc.parts[0].material,'Concrete');
 const otherPlace={...owner,session:'other_place_session',secret:'other_place_secret',room:'54321:isolated_room_123'};await rpc(otherPlace,'join');assert.deepEqual((await rpc(otherPlace,'list')).saves,[]);await assert.rejects(rpc(otherPlace,'load',{saveId:'named_save_123'}),/save missing/);
 const serialized=JSON.stringify(await rpc(owner2,'poll'));assert(!serialized.includes(owner2.secret)&&!serialized.includes(key));
 await rpc(owner2,'delete-save',{saveId:'named_save_123'});assert.deepEqual((await rpc(owner2,'list')).saves,[]);
});
test('missing production authorization configuration fails closed',async()=>{const redis=memoryRedis();await assert.rejects(control(redis,{...owner,op:'join'},{}),/owner authorization/);const result=await control(redis,{...viewer,op:'join'},{});assert.equal(result.self.owner,false);});
