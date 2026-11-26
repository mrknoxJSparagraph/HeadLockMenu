import fs from 'node:fs';
import {LuauState} from 'luau-web';

const mock=fs.readFileSync('tests/fixtures/roblox_mock.luau','utf8');
const prelude=fs.readFileSync('tests/fixtures/sound_menu_prelude.luau','utf8');
const expose=fs.readFileSync('tests/fixtures/state_expose.luau','utf8');
const source=fs.readFileSync('HeadLockMenu_Core.lua','utf8').replace('SC.watchOwnerEmotes()\n\nend\nlocal __ok',expose+'\nSC.watchOwnerEmotes()\n\nend\nlocal __ok');
for (const file of ['saktk_menu_tests.luau','command_tests.luau','fly_tests.luau','juggernaut_tests.luau','spectate_tests.luau','anti_death_tests.luau','integrated_sound_tests.luau']) {
  const state=await LuauState.createAsync({print:console.log});
  try {
    const test=fs.readFileSync('tests/fixtures/'+file,'utf8');
    await state.loadstring(mock+'\n'+prelude+'\n'+source+'\nassert(_G.HeadLockMenuExecutionReady,table.concat(TestEnv.warnings," | "))\n'+test,file,true)();
    console.log('PASS '+file);
  } finally {state.destroy();}
}
