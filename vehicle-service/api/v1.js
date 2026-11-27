import {exchange,configured,redisClient} from '../lib/redis.js';

export default async function handler(req,res){
 res.setHeader('Cache-Control','no-store');
 res.setHeader('Access-Control-Allow-Origin','*');
 res.setHeader('Access-Control-Allow-Headers','Content-Type');
 res.setHeader('Access-Control-Allow-Methods','POST,OPTIONS');
 if(req.method==='OPTIONS')return res.status(204).end();
 if(req.method!=='POST')return res.status(405).json({ok:false,error:'method'});
 if(!configured())return res.status(503).json({ok:false,error:'storage unavailable'});
 try{
  const raw=typeof req.body==='string'?req.body:JSON.stringify(req.body??{});
  if(raw.length>20000)return res.status(413).json({ok:false,error:'size'});
  const input=JSON.parse(raw);
  const data=await exchange(redisClient(),input);
  return res.status(200).json(data);
 }catch(error){
  const safe=['room','session','authorization','room full','user','vehicle','vehicle limit','pose','rotation','operation','busy'];
  return res.status(safe.includes(error.message)?400:503).json({ok:false,error:safe.includes(error.message)?error.message:'storage unavailable'});
 }
}
