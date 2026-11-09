#!/bin/bash
# Pull Notes, Images and Edits tabs from the Google Sheet into notes.js
set -e; cd /home/user/workspace
SID=1Xy258S_qX8ioGQyaftq02O2XKHkcuR9ylcWEVsEGZvk
gws sheets spreadsheets values batchGet --params "{\"spreadsheetId\":\"$SID\",\"ranges\":[\"Notes!A1:F1000\",\"Images!A1:H2000\",\"Edits!A1:D2000\"]}" 2>gws.err > notes_raw.json
python3 - "$SID" <<'P'
import json,sys,datetime
vr=json.load(open('notes_raw.json'))['valueRanges']
def tab(i):
    v=vr[i].get('values',[])
    if not v:return []
    h=[x.strip().lower() for x in v[0]];out=[]
    for r in v[1:]:
        d={k:(r[j].strip() if j<len(r) else '') for j,k in enumerate(h)}
        if d.get('id') and not d['id'].startswith('(example)'):out.append(d)
    return out
notes=[{'id':r['id'],'shelfmark':r.get('shelfmark',''),'title':r.get('title',''),'institution':r.get('institution',''),
 'tags':[t.strip() for t in r.get('tags','').split(',') if t.strip()],'note':r.get('note','')} for r in tab(0)]
images=[{'id':r['id'],'folio':r.get('folio',''),'scene':r.get('scene',''),'link':r.get('link',''),'type':r.get('building type',''),
 'obs':r.get('observation',''),'interp':r.get('interpretation','')} for r in tab(1)]
OK={'bibliography','title','date','center','region','patron','institution','folios','paintings_stated','scribe','note','url','century','format','place_recorded','shelfmark','extent'}
edits=[];bad=[]
for r in tab(2):
    f=r.get('field','').strip().lower().replace(' ','_')
    (edits if f in OK else bad).append({'id':r['id'],'field':f,'value':r.get('new value','')})
out={'sheetUrl':f'https://docs.google.com/spreadsheets/d/{sys.argv[1]}/edit','synced':datetime.date.today().isoformat(),'rows':notes,'images':images,'edits':edits}
open('shahnama-catalog/notes.js','w').write('window.SN_NOTES='+json.dumps(out,ensure_ascii=False)+';\n')
print(len(notes),'notes,',len(images),'images,',len(edits),'edits synced')
if bad:print('Skipped edits with unknown field:',bad)
P
