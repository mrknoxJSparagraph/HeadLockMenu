import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
const endpoint=process.env.VEHICLE_RELAY_URL;
assert(endpoint?.startsWith('https://'),'Set VEHICLE_RELAY_URL to the relay endpoint');
const room='integration_'+randomUUID();
const a={room,session:randomUUID(),secret:randomUUID(),user:1};
const b={room,session:randomUUID(),secret:randomUUID(),user:2};
const pose={cf:[0,10,0,1,0,0,0,1,0,0,0,1],vel:[0,0,0],av:[0,0,0],spin:0,steer:0};
const id=randomUUID(),bike=randomUUID();
const timings=[];
async function rpc(who,op,fields={},status=200){
 const started=performance.now();
 const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({...who,op,...fields}),signal:AbortSignal.timeout(10000)});
 const body=await response.json();timings.push(performance.now()-started);
 assert.equal(response.status,status,JSON.stringify(body));
 assert(!JSON.stringify(body).includes(a.secret));assert(!JSON.stringify(body).includes(b.secret));
 return body;
}
try{
 await Promise.all([rpc(a,'join'),rpc(b,'join')]);
 await rpc(a,'spawn',{id,kind:'Car',pose});
 assert((await rpc(b,'sync')).cars.some(c=>c.id===id&&c.kind==='Car'));
 await rpc(b,'spawn',{id:bike,kind:'Bike',pose});
 assert((await rpc(a,'sync')).cars.some(c=>c.id===bike&&c.kind==='Bike'));
 const claims=await Promise.all([rpc(a,'claim',{id}),rpc(b,'claim',{id})]);
 assert.equal(claims.filter(x=>x.ok).length,1);assert.equal(claims.filter(x=>x.error==='occupied').length,1);
 const winner=claims[0].ok?a:b,other=winner===a?b:a,epoch=claims.find(x=>x.ok).epoch;
 const moved={...pose,cf:[25,10,0,1,0,0,0,1,0,0,0,1],vel:[10,0,0],spin:1.5,steer:.4};
 const firstMove=await rpc(winner,'sync',{move:{id,epoch,seq:1,pose:moved}});
 assert(firstMove.ok,JSON.stringify({error:firstMove.error,epoch,now:firstMove.now,cars:firstMove.cars.map(c=>({id:c.id,epoch:c.epoch,until:c.until,driver:c.driver})),timings}));
 const remote=(await rpc(other,'sync')).cars.find(c=>c.id===id);
 assert.equal(remote.cf[0],25);assert.equal(remote.spin,1.5);assert.equal(remote.steer,.4);
 assert.equal((await rpc(other,'delete',{id:winner===a?id:bike})).ok,false);
 assert.equal((await rpc(winner,'sync',{move:{id,epoch,seq:1,pose}})).error,'stale');
 await rpc(winner,'release',{id,epoch,pose:moved});
 const handoff=await rpc(other,'claim',{id});assert(handoff.ok);assert(handoff.epoch>epoch);
 assert.equal((await rpc(winner,'sync',{move:{id,epoch,seq:2,pose}})).error,'lease lost');
 await rpc(other,'release',{id,epoch:handoff.epoch,pose:moved});
 await rpc(a,'delete',{id});
 assert(!(await rpc(b,'sync')).cars.some(c=>c.id===id));
 await rpc(b,'delete',{id:bike});
 assert.equal((await rpc({...a,secret:'incorrect_secret'},'sync',{},400)).error,'authorization');
 const c={...b,room:room+'_isolated'};await rpc(c,'join');assert.equal((await rpc(c,'sync')).cars.length,0);await rpc(c,'leave');
 const sorted=timings.slice().sort((x,y)=>x-y);
 console.log('PASS live car and motorcycle visibility, motion, simultaneous one-driver claims, handoff, fencing, ownership, removal, authentication and room isolation');
 console.log(`HTTP latency median ${Math.round(sorted[Math.floor(sorted.length/2)])}ms; max ${Math.round(sorted.at(-1))}ms; ${timings.length} requests`);
}finally{await Promise.allSettled([rpc(a,'delete',{id}),rpc(b,'delete',{id:bike}),rpc(a,'leave'),rpc(b,'leave')]);}
