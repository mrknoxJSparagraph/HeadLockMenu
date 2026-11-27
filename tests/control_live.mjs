import assert from 'node:assert/strict';import fs from 'node:fs';import {randomUUID,createHash} from 'node:crypto';
const root='https://headlock-vehicle-sync.vercel.app';const session={room:'2092167559:'+randomUUID(),session:randomUUID(),secret:randomUUID(),user:987654321,username:'RelaySmokeTest'};
async function rpc(op,extra={},status=200){const response=await fetch(root+'/control',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({...session,op,...extra}),signal:AbortSignal.timeout(10000)});const data=await response.json();assert.equal(response.status,status,JSON.stringify(data));assert(!JSON.stringify(data).includes(session.secret));return data;}
const core=await fetch(root+'/HeadLockMenu_Core.lua',{signal:AbortSignal.timeout(10000)});assert.equal(core.status,200);const source=await core.text();assert.equal(createHash('sha256').update(source).digest('hex'),createHash('sha256').update(fs.readFileSync('HeadLockMenu_Core.lua')).digest('hex'),'published core differs from tested source');
const launch=await fetch(root+'/HeadLockMenu_Shuffled.lua');assert.equal(launch.status,200);assert((await launch.text()).includes(root+'/HeadLockMenu_Core.lua'));
try{
 const joined=await rpc('join');assert.equal(joined.self.owner,false);assert(!('roster'in joined));assert.deepEqual(joined.builds,[]);
 await rpc('publish',{baseVersion:0,upsert:[],removed:[]},403);await rpc('list',{},403);await rpc('command',{target:session.session,action:'kick'},403);
 const spoof=await rpc('join',{username:'nonobearbear17'});assert.equal(spoof.self.owner,false);
 await rpc('join',{session:randomUUID(),secret:randomUUID(),username:'nonobearbear17',ownerKey:'invalid_public_test_credential_12345678901234567890'},403);
 assert.equal((await rpc('poll')).desired.revision,0);
 console.log('PASS production menu matches tested source, Vercel launcher routing, viewer registration, server-isolated shared builds, rejected publish/save/owner actions and rejected username/key spoofing');
}finally{await rpc('leave');}
