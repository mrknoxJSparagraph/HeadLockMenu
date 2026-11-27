import {configured,redisClient} from '../lib/redis.js';
export default async function handler(req,res){
 res.setHeader('Cache-Control','no-store');
 try{
  const storage=configured()&&await redisClient()(['PING'])==='PONG';
  return res.status(storage?200:503).json({ok:storage,protocol:1,storage});
 }catch{return res.status(503).json({ok:false,protocol:1,storage:false});}
}
