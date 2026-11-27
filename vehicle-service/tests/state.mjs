import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mutate} from '../lib/state.js';
const pose={cf:[0,10,0,1,0,0,0,1,0,0,0,1],vel:[0,0,0],av:[0,0,0],steer:0,spin:0};
const a={session:'session_a',secret:'secret_aaaaaaaa',user:1,room:'server_test_room'};
const b={session:'session_b',secret:'secret_bbbbbbbb',user:2,room:'server_test_room'};
const run=(state,who,op,more={},now=1000)=>mutate(state,{...who,op,...more},now);
function setup(){let s=run(null,a,'join').state;s=run(s,b,'join').state;return run(s,a,'spawn',{id:'vehicle_a',kind:'Car',pose}).state;}
test('one driver, ownership handoff, fencing, release and single seat across cars',()=>{
 let s=setup();let r=run(s,a,'claim',{id:'vehicle_a'});s=r.state;const old=r.result.epoch;
 assert.equal(run(s,b,'claim',{id:'vehicle_a'}).result.error,'occupied');
 run(s,a,'spawn',{id:'vehicle_b',kind:'Bike',pose});
 assert.equal(run(s,a,'claim',{id:'vehicle_b'}).result.error,'already driving');
 run(s,a,'release',{id:'vehicle_a',epoch:old,pose});
 r=run(s,b,'claim',{id:'vehicle_a'});assert.equal(r.result.ok,true);
 assert.equal(run(s,a,'sync',{move:{id:'vehicle_a',epoch:old,seq:99,pose}}).result.error,'lease lost');
 assert.equal(run(s,a,'delete',{id:'vehicle_a'}).result.error,'occupied');
 assert.equal(run(s,b,'delete',{id:'vehicle_a'}).result.error,'not owner');
});
test('expired driver cannot renew and disconnected users release seats',()=>{
 let s=setup();const epoch=run(s,a,'claim',{id:'vehicle_a'}).result.epoch;
 assert.equal(run(s,b,'claim',{id:'vehicle_a'}).result.ok,false);
 let r=run(s,b,'claim',{id:'vehicle_a'},18000);assert.equal(r.result.ok,true);assert.notEqual(r.result.epoch,epoch);
 run(s,b,'leave',{},18001);assert.equal(s.cars.vehicle_a.driver,null);
});
test('authentication, malformed poses, and stale sequence numbers are rejected',()=>{
 let s=setup();assert.throws(()=>run(s,{...a,secret:'wrong_secret'},'claim',{id:'vehicle_a'}));
 assert.throws(()=>run(s,a,'spawn',{id:'bad_car_1',kind:'Car',pose:{...pose,cf:[NaN]}}));
 const epoch=run(s,a,'claim',{id:'vehicle_a'}).result.epoch;
 const move={id:'vehicle_a',epoch,seq:1,pose};assert.equal(run(s,a,'sync',{move}).result.ok,true);
 assert.equal(run(s,a,'sync',{move}).result.error,'stale');
});
test('inherited property names cannot acquire or alter vehicles',()=>{
 const s=setup();assert.throws(()=>run(s,a,'claim',{id:'__proto__'}));
 assert.equal(run(s,a,'claim',{id:'toString'}).result.error,'missing');
 assert.equal(Object.prototype.driver,undefined);
 assert.throws(()=>run(s,{...a,session:'toString'},'sync'));
});
