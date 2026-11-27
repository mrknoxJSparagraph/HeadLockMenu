import {redisClient,configured} from '../lib/redis.js';
import {control} from '../lib/control.js';
export default async function handler(req,res){
 res.setHeader('Cache-Control','no-store');res.setHeader('Access-Control-Allow-Origin','*');res.setHeader('Access-Control-Allow-Headers','Content-Type');res.setHeader('Access-Control-Allow-Methods','POST,OPTIONS');
 if(req.method==='OPTIONS')return res.status(204).end();if(req.method!=='POST')return res.status(405).json({ok:false,error:'method'});
 if(!configured())return res.status(503).json({ok:false,error:'storage unavailable'});
 try{
  const raw=typeof req.body==='string'?req.body:JSON.stringify(req.body??{});if(Buffer.byteLength(raw)>2500000)return res.status(413).json({ok:false,error:'size'});
  const result=await control(redisClient(),JSON.parse(raw));return res.status(200).json(result);
 }catch(e){const message=['session','room','user','authorization','owner authorization','room full','target','command','build','room build limit','save','name','save limit','save missing','operation','busy'].includes(e.message)?e.message:'storage unavailable';return res.status(message.includes('authorization')?403:message==='storage unavailable'?503:400).json({ok:false,error:message});}
}
