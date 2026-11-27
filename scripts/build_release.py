from pathlib import Path
import base64,gzip,json
root=Path(__file__).resolve().parents[1]
public=root/'vehicle-service/public';public.mkdir(exist_ok=True)
(public/'HeadLockMenu_Core.lua').write_text((root/'HeadLockMenu_Core.lua').read_text())
launcher=(root/'HeadLockMenu_Shuffled.lua').read_text().replace('https://raw.githubusercontent.com/mrknoxJSparagraph/HeadLockMenu/main/HeadLockMenu_Core.lua','https://headlock-vehicle-sync.vercel.app/HeadLockMenu_Core.lua')
(public/'HeadLockMenu_Shuffled.lua').write_text(launcher)
print('Prepared public Vercel menu and launcher')

encoded={name:base64.b64encode(gzip.compress(data.encode(),mtime=0)).decode()for name,data in {'core':(root/'HeadLockMenu_Core.lua').read_text(),'launcher':launcher}.items()}
handler="import {gunzipSync} from 'node:zlib';\nconst files="+json.dumps(encoded,separators=(',',':'))+";\nexport default function handler(req,res){if(req.method!=='GET')return res.status(405).end();const data=files[req.query?.file];if(!data)return res.status(404).end();res.setHeader('Content-Type','text/plain; charset=utf-8');res.setHeader('Cache-Control','no-store');return res.status(200).send(gunzipSync(Buffer.from(data,'base64'))); }\n"
(root/'vehicle-service/api/menu.js').write_text(handler)
