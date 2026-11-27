import fs from 'node:fs';import assert from 'node:assert/strict';import {createHash,randomUUID} from 'node:crypto';import {LuauState} from 'luau-web';import {control} from '../vehicle-service/lib/control.js';
const values=new Map();const redis=async c=>{if(c[0]==='GET')return values.get(c[1])??null;if(c[0]==='DEL')return Number(values.delete(c[1]));if(c[0]==='EVAL'){const old=values.get(c[3])??'';if(old!==c[4])return[0,old];values.set(c[3],c[5]);return[1,c[5]];}throw Error(c[0]);};
const key='isolated_test_owner_credential_1234567890';const env={HEADLOCK_OWNER_KEY_SHA256:createHash('sha256').update(key).digest('hex')};
const mock=fs.readFileSync('tests/fixtures/roblox_mock.luau','utf8');const prelude=fs.readFileSync('tests/fixtures/sound_menu_prelude.luau','utf8');const builderMock=fs.readFileSync('../track-builder/test_prelude.luau','utf8');
const expose=fs.readFileSync('tests/fixtures/state_expose.luau','utf8');const source=fs.readFileSync('HeadLockMenu_Core.lua','utf8').replace('SC.watchOwnerEmotes()\n\nend\nlocal __ok',expose+'\nSC.watchOwnerEmotes()\n\nend\nlocal __ok');
function plain(v){if(v&&typeof v.keys==='function'&&typeof v.get==='function'){const keys=v.keys();if(keys.length===0)return[];if(keys.every(k=>typeof k==='number'))return keys.sort((a,b)=>a-b).map(k=>plain(v.get(k)));return Object.fromEntries(keys.map(k=>[k,plain(v.get(k))]));}return v;}
function literal(v){if(v===null)return'nil';if(Array.isArray(v))return'{'+v.map(literal).join(',')+'}';if(typeof v==='object')return'{'+Object.entries(v).map(([k,x])=>'['+JSON.stringify(k)+']='+literal(x)).join(',')+'}';return JSON.stringify(v);}
async function client(owner){let vm;vm=await LuauState.createAsync({print:console.log,_guid:()=>randomUUID(),_encode:v=>JSON.stringify(plain(v)),_decode:async text=>(await vm.loadstring('return '+literal(JSON.parse(text)),'JSON bridge',true)())[0],_request:async text=>{try{return JSON.stringify(await control(redis,JSON.parse(text),env));}catch(e){return JSON.stringify({ok:false,error:e.message});}}});
 await vm.loadstring(mock+'\n'+prelude+'\n'+builderMock+`\n game.JobId='isolated_e2e_room_123';TestEnv.localPlayer.UserId=${owner?100:200};TestEnv.localPlayer.Name='${owner?'nonobearbear17':'OrdinaryUser'}';${owner?`_G.HeadLockOwnerAccess={key='${key}'}`:''}
 request=function(options)return{StatusCode=200,Body=_request(options.Body)}end
 `+source+'\nassert(_G.HeadLockMenuExecutionReady,table.concat(TestEnv.warnings," | "))','Complete main menu',true)();return vm;}
async function run(vm,code){return await vm.loadstring(code,'Building/owner end-to-end checks',true)();}
let owner,viewer,reloaded;
try{
 owner=await client(true);viewer=await client(false);
 await run(owner,`local T=__T;local SC=T.SC;SC.authenticated=true;SC.ownerSync.tick();assert(SC.ownerSync.owner,SC.ownerSync.error)
 assert(not T.main:FindFirstChild('Category_Building',true).Visible and not T.main:FindFirstChild('Category_Owner Panel',true).Visible)
 T.selectGame();TestEnv.click(T.main,'  Credits');T.content:FindFirstChild('OwnerFeaturesCheckbox',true).Activated:Fire()
 assert(T.main:FindFirstChild('Category_Building',true).Visible and T.main:FindFirstChild('Category_Owner Panel',true).Visible)
 assert(T.main:FindFirstChild('Category_Building',true).LayoutOrder<T.main:FindFirstChild('Category_Owner Panel',true).LayoutOrder)
 TestEnv.click(T.main,'  Building');T.content:FindFirstChild('BuildingToggle',true).Activated:Fire();assert(SC.building.enabled)
 local api=SC.building.api;assert(api and api.isEnabled());api.equip('Trowel');assert(not api.ui.menuButton.Visible,'standalone menu shortcut visible')
 local p=api.add('Ramp',CFrame.new(12,7,5)*CFrame.Angles(.2,.6,.3));api.edit(function(q)q.Size=Vector3.new(15,2,7);q.Color=Color3.fromRGB(20,40,60);q.Material=Enum.Material.Metal end)
 SC.ownerSync.tick();assert(not SC.ownerSync.publishBlocked,SC.ownerSync.error);assert(SC.ownerSync.versions['100']==1,SC.ownerSync.error);SC.ownerSync.tick();SC.ownerSync.tick();assert(SC.ownerSync.versions['100']==1,'unchanged ramp was repeatedly published')
 `);
 await run(viewer,`local SC=__T.SC;SC.authenticated=true;SC.ownerSync.tick();assert(not SC.ownerSync.owner)
 assert(not __T.main:FindFirstChild('Category_Building',true).Visible);SC.setOwnerFeatures(true);assert(not SC.ownerFeatures)
 assert(_G.HeadLockTrackBuilder==nil,'viewer received editor')
 local folder=SC.ownerSync.sharedFolder;local parts=folder:GetDescendants();local found
 for _,p in ipairs(parts)do if p:IsA('BasePart')then found=p end end
 assert(found and found.ClassName=='WedgePart'and found.CanCollide);assert(found.Size.X==15 and found.Material==Enum.Material.Metal and math.abs(found.Color.B-60/255)<1e-8)
 `);
 await run(owner,`local SC=__T.SC;local api=SC.building.api;api.nudge(1,1);SC.ownerSync.tick()
 TestEnv.click(__T.content,'Save Build');local prompt=__T.gui:FindFirstChild('BuildNamePrompt');assert(prompt)
 prompt:FindFirstChild('BuildSaveName',true).Text='Road 1';TestEnv.click(prompt,'Save');SC.ownerSync.tick();SC.ownerSync.tick()
 assert(#SC.building.saves==1 and SC.building.saves[1].name=='Road 1',SC.building.status)
 local old=api.document();_G.ExpectedBuild=old
 api.clear();SC.ownerSync.tick();assert(#api.document().parts==0)
 `);
 await run(viewer,`local SC=__T.SC;SC.ownerSync.tick();local n=0;for _,p in ipairs(SC.ownerSync.sharedFolder:GetDescendants())do if p:IsA('BasePart')then n+=1 end end;assert(n==0,'shared deletion did not arrive')`);
 await run(owner,`local SC=__T.SC;SC.building.selected=SC.building.saves[1];SC.building.load();SC.ownerSync.tick();SC.ownerSync.tick()
 local api=SC.building.api;local loaded=api.document();assert(#loaded.parts==1 and loaded.parts[1].size[1]==15 and loaded.parts[1].material=='Metal')
 for i,n in ipairs(_G.ExpectedBuild.parts[1].cf)do assert(math.abs(n-loaded.parts[1].cf[i])<1e-7,'saved position/orientation changed')end
 SC.setBuilding(false);assert(not api.isEnabled()and not api.ui.materialWindow.Visible and not api.ui.trowelSwitch.Visible)
 for _,p in pairs(api.tools)do assert(false,'OFF left tools')end
 SC.ownerSync.tick()
 `);
 await run(viewer,`local SC=__T.SC;SC.ownerSync.tick();local count=0;for _,p in ipairs(SC.ownerSync.sharedFolder:GetDescendants())do if p:IsA('BasePart')then count+=1 end end;assert(count==1,'loaded build did not sync')`);
 await run(owner,`local SC=__T.SC;SC.ownerSync.tick();assert(#SC.ownerSync.roster==2)
 TestEnv.click(__T.main,'  Owner Panel');local list=assert(__T.content:FindFirstChild('OwnerUsers',true));local target
 for _,row in ipairs(SC.ownerSync.roster)do if not row.owner then target=row.session end end
 assert(target and list:FindFirstChild('OwnerUser_'..target));TestEnv.click(list:FindFirstChild('OwnerUser_'..target),'Pause');SC.ownerSync.tick()
 `);
 await run(viewer,`local SC=__T.SC;SC.ownerSync.tick();assert(SC.paused,'pause did not arrive');SC.ownerSync.tick();assert(SC.ownerSync.connected,'pause stopped command listener')`);
 for(const [action,expected]of [['resume',`assert(not SC.paused)`],['mute',`assert(SC.soundsPaused)`],['unmute',`assert(not SC.soundsPaused)`],['kick',`assert(TestEnv.localPlayer.Kicks==1)`]]){
  await run(owner,`local SC=__T.SC;local target;for _,u in ipairs(SC.ownerSync.roster)do if not u.owner then target=u.session end end;assert(SC.ownerSync.command(target,'${action}'));SC.ownerSync.tick()`);
  await run(viewer,`local SC=__T.SC;SC.ownerSync.tick();${expected}`);
 }
 await run(owner,`local SC=__T.SC;SC.setBuilding(true);SC.setOwnerFeatures(false);assert(not SC.building.enabled and not __T.main:FindFirstChild('Category_Building',true).Visible)
 _G.HeadLockMenuCleanup();assert(SC.ownerSync.closed and SC.building.api==nil)
 `);
 reloaded=await client(true);await run(reloaded,`local SC=__T.SC;SC.authenticated=true;SC.ownerSync.tick();SC.setOwnerFeatures(true);SC.building.list();SC.ownerSync.tick();assert(#SC.building.saves==1 and SC.building.saves[1].name=='Road 1','restart lost named save')
 SC.building.selected=SC.building.saves[1];SC.building.load();SC.ownerSync.tick();assert(#SC.building.api.document().parts==1)
 _G.HeadLockMenuCleanup()`);
 await run(viewer,`_G.HeadLockMenuCleanup()`);
 assert([...values.keys()].some(k=>k.startsWith('headlock:saves:100:')));
 console.log('PASS complete main-menu owner gates, inventory ON/OFF, removed shortcut, two-client live build create/edit/delete/load, exact persistent named saves across script restarts, all five owner actions and paused-client resume');
}finally{owner?.destroy();viewer?.destroy();reloaded?.destroy();}
