import {createHash} from 'node:crypto';
import {mutate} from './state.js';

export const compareAndSwap="local value=redis.call('GET',KEYS[1]); if (value or '')~=ARGV[1] then return {0,value or ''} end; redis.call('SET',KEYS[1],ARGV[2],'EX',360); return {1,ARGV[2]}";
export const readPrimary="return redis.call('GET',KEYS[1])";
export function configured(env=process.env){return Boolean((env.UPSTASH_REDIS_REST_URL||env.KV_REST_API_URL)&&(env.UPSTASH_REDIS_REST_TOKEN||env.KV_REST_API_TOKEN));}
export function redisClient(env=process.env){
 const url=env.UPSTASH_REDIS_REST_URL||env.KV_REST_API_URL;
 const token=env.UPSTASH_REDIS_REST_TOKEN||env.KV_REST_API_TOKEN;
 if(!configured(env))throw new Error('storage unavailable');
 return async command=>{
  const response=await fetch(url,{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify(command),signal:AbortSignal.timeout(2500)});
  if(!response.ok)throw new Error('storage unavailable');
  const body=await response.json();
  if(body.error)throw new Error('storage unavailable');
  return body.result;
 };
}
export async function exchange(redis,input,clock=Date.now){
 if(typeof input?.room!=='string'||input.room.length<8||input.room.length>200)throw new Error('room');
 const key='vehicles:'+createHash('sha256').update(input.room).digest('hex');
 let previous=await redis(['EVAL',readPrimary,1,key]);
 for(let attempt=0;attempt<8;attempt++){
  const now=clock();
  const {state,result}=mutate(previous?JSON.parse(previous):null,input,now);
  const next=JSON.stringify(state);
  const saved=await redis(['EVAL',compareAndSwap,1,key,previous??'',next]);
  if(saved[0]===1){
   return {...result,now,cars:Object.values(state.cars).map(c=>({...c,driverUser:c.driver?state.sessions[c.driver]?.user??null:null}))};
  }
  previous=saved[1]||null;
 }
 throw new Error('busy');
}
