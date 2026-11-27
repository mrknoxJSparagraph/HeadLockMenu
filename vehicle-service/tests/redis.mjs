import {test} from 'node:test';
import assert from 'node:assert/strict';
import {exchange,configured,redisClient,compareAndSwap,readPrimary} from '../lib/redis.js';
import handler from '../api/v1.js';
const pose={cf:[0,10,0,1,0,0,0,1,0,0,0,1],vel:[0,0,0],av:[0,0,0]};
const a={room:'test_room_123',session:'session_aaaaaaaa',secret:'secret_aaaaaaaaa',user:1};
const b={room:a.room,session:'session_bbbbbbbb',secret:'secret_bbbbbbbbb',user:2};
function database(){
 const rows=new Map();let conflicts=0;
 return {rows,get conflicts(){return conflicts},async command(c){
  await Promise.resolve();
  if(c[0]==='GET')return rows.get(c[1])??null;
  if(c[0]==='EVAL'&&c[1]===readPrimary)return rows.get(c[3])??null;
  assert.equal(c[0],'EVAL');assert.equal(c[1],compareAndSwap);assert.equal(c[2],1);
  if((rows.get(c[3])??'')!==c[4]){conflicts++;return [0,rows.get(c[3])??''];}
  rows.set(c[3],c[5]);return [1,c[5]];
 }};
}
test('Redis CAS retries contention, replicates motion, fences old driver and permits handoff',async()=>{
 const db=database(),run=(who,op,rest={})=>exchange(db.command,{...who,op,...rest},()=>1000);
 await Promise.all([run(a,'join'),run(b,'join')]);
 await run(a,'spawn',{id:'vehicle_aaaa',kind:'Car',pose});
 const claims=await Promise.all([run(a,'claim',{id:'vehicle_aaaa'}),run(b,'claim',{id:'vehicle_aaaa'})]);
 assert.equal(claims.filter(x=>x.ok).length,1);assert.equal(claims.filter(x=>x.error==='occupied').length,1);assert(db.conflicts>0);
 const winner=claims[0].ok?a:b,other=winner===a?b:a,epoch=claims.find(x=>x.ok).epoch;
 await run(winner,'sync',{move:{id:'vehicle_aaaa',epoch,seq:1,pose:{...pose,cf:[50,...pose.cf.slice(1)]}}});
 assert.equal((await run(other,'sync')).cars[0].cf[0],50);
 await run(winner,'release',{id:'vehicle_aaaa',epoch});
 const next=await run(other,'claim',{id:'vehicle_aaaa'});assert(next.ok);assert(next.epoch>epoch);
 assert.equal((await run(winner,'sync',{move:{id:'vehicle_aaaa',epoch,seq:2,pose}})).error,'lease lost');
 assert(!JSON.stringify(next).includes(a.secret));assert(!JSON.stringify(next).includes(b.secret));
 assert.equal((await run({...other,room:'another_room'},'join')).cars.length,0);
});
test('Redis REST transport keeps credentials server-side and forwards the atomic command',async()=>{
 const previous=global.fetch;let seen;
 global.fetch=async(url,opts)=>{seen={url,opts};return {ok:true,json:async()=>({result:'PONG'})};};
 try{
  assert(configured({KV_REST_API_URL:'https://redis.example',KV_REST_API_TOKEN:'test-secret'}));
  assert.equal(await redisClient({UPSTASH_REDIS_REST_URL:'https://redis.example',UPSTASH_REDIS_REST_TOKEN:'test-secret'})(['PING']),'PONG');
  assert.equal(seen.opts.headers.Authorization,'Bearer test-secret');assert.equal(seen.opts.body,'["PING"]');
 }finally{global.fetch=previous;}
});
test('replica reads cannot lose sessions or vehicles',async()=>{
 const db=database();let reads=0;
 const stale=async command=>{if(command[0]==='GET'){reads++;return null;}return db.command(command);};
 await exchange(stale,{...a,op:'join'},()=>1000);
 await exchange(stale,{...b,op:'join'},()=>1000);
 const spawned=await exchange(stale,{...a,op:'spawn',id:'vehicle_stale',kind:'Car',pose},()=>1000);
 assert(spawned.cars.some(c=>c.id==='vehicle_stale'));assert.equal(reads,0);
});
test('API does not report ready without storage and rejects unsupported methods',async()=>{
 const res={setHeader(){},status(v){this.code=v;return this},json(v){this.body=v;return this},end(){}};
 await handler({method:'GET'},res);assert.equal(res.code,405);
 if(!configured()){await handler({method:'POST',body:a},res);assert.equal(res.code,503);assert.equal(res.body.error,'storage unavailable');}
});
