const LEASE=6000,SESSION=30000;
const finite=(v,n)=>Array.isArray(v)&&v.length===n&&v.every(x=>typeof x==='number'&&Number.isFinite(x)&&Math.abs(x)<1e7);
const id=v=>typeof v==='string'&&/^[a-zA-Z0-9_-]{8,80}$/.test(v)&&!['__proto__','constructor','prototype'].includes(v);
function pose(v){
 if(!finite(v?.cf,12)||!finite(v?.vel,3)||!finite(v?.av,3))throw new Error('pose');
 for(const offset of [3,6,9])if(Math.abs(Math.hypot(...v.cf.slice(offset,offset+3))-1)>.03)throw new Error('rotation');
 return {cf:v.cf,vel:v.vel,av:v.av,steer:Math.max(-1,Math.min(1,Number(v.steer)||0)),spin:Number.isFinite(v.spin)?v.spin:0};
}
export function mutate(state,input,now){
 state??={sessions:{},cars:{}};
 for(const [key,s]of Object.entries(state.sessions))if(s.at<now-SESSION)delete state.sessions[key];
 for(const [key,c]of Object.entries(state.cars)){
  if(c.driver&&(!state.sessions[c.driver]||c.until<=now)){c.driver=null;c.until=0;c.epoch++;}
  if(c.at<now-300000&&!state.sessions[c.owner]&&!c.driver)delete state.cars[key];
 }
 if(!id(input.session)||!id(input.secret))throw new Error('session');
 let session=Object.hasOwn(state.sessions,input.session)?state.sessions[input.session]:null;
 if(input.op==='join'){
  if(session&&session.secret!==input.secret)throw new Error('authorization');
  if(!session&&Object.keys(state.sessions).length>=32)throw new Error('room full');
  if(!Number.isSafeInteger(input.user)||input.user<1)throw new Error('user');
  session=state.sessions[input.session]={secret:input.secret,user:input.user,at:now};
 }else if(!session||session.secret!==input.secret)throw new Error('authorization');
 session.at=now;
 let result={ok:true};
 if(['spawn','claim','release','delete'].includes(input.op)&&!id(input.id))throw new Error('vehicle');
 const car=input.id&&Object.hasOwn(state.cars,input.id)?state.cars[input.id]:null;
 switch(input.op){
 case 'join':break;
 case 'spawn':
  if(!id(input.id)||!['Car','Bike'].includes(input.kind))throw new Error('vehicle');
  if(car){if(car.owner!==input.session)throw new Error('authorization');break;}
  if(Object.keys(state.cars).length>=64||Object.values(state.cars).filter(c=>c.owner===input.session).length>=8)throw new Error('vehicle limit');
  state.cars[input.id]={id:input.id,kind:input.kind,owner:input.session,creator:session.user,driver:null,until:0,epoch:0,seq:0,at:now,...pose(input.pose)};
  break;
 case 'claim':
  if(!car){result={ok:false,error:'missing'};break;}
  if(Object.values(state.cars).some(c=>c.driver===input.session&&c.id!==car.id&&c.until>now)){result={ok:false,error:'already driving'};break;}
  if(car.driver&&car.driver!==input.session){result={ok:false,error:'occupied'};break;}
  if(!car.driver){car.driver=input.session;car.epoch++;car.seq=0;}
  car.until=now+LEASE;car.at=now;result.epoch=car.epoch;break;
 case 'sync':
  if(input.move){
   const m=input.move,c=Object.hasOwn(state.cars,m.id)?state.cars[m.id]:null;
   if(!c||c.driver!==input.session||c.epoch!==m.epoch||c.until<=now){result={ok:false,error:'lease lost'};break;}
   if(!Number.isSafeInteger(m.seq)||m.seq<=c.seq){result={ok:false,error:'stale'};break;}
   Object.assign(c,pose(m.pose),{seq:m.seq,until:now+LEASE,at:now});result.epoch=c.epoch;
  }
  for(const c of Object.values(state.cars))if(c.owner===input.session)c.at=now;
  break;
 case 'release':
  if(car&&car.driver===input.session&&car.epoch===input.epoch){
   if(input.pose)Object.assign(car,pose(input.pose));
   car.driver=null;car.until=0;car.epoch++;car.at=now;
  }break;
 case 'delete':
  if(car&&car.owner===input.session){
   if(car.driver&&car.driver!==input.session){result={ok:false,error:'occupied'};break;}
   delete state.cars[car.id];
  }else if(car)result={ok:false,error:'not owner'};
  break;
 case 'leave':
  delete state.sessions[input.session];
  for(const c of Object.values(state.cars))if(c.driver===input.session){c.driver=null;c.until=0;c.epoch++;}
  break;
 default:throw new Error('operation');
 }
 return {state,result};
}
