"""Publish reviewed English Discover audio; credentials stay outside the repository.
Usage: python3 scripts/render-discover-audio.py /path/to/publisher-session.json
Session JSON: url, key (publishable), token (authorized publisher JWT).
The publishing endpoint must allow that publisher; end users cannot synthesize.
"""
import concurrent.futures, hashlib, json, pathlib, sys, time, urllib.request
ROOT=pathlib.Path(__file__).resolve().parents[1]
CATALOG=ROOT/'MyApp/Content/Discover/discover-catalog.json'
OUT=ROOT/'MyApp/Resources/DiscoverAudio'
OUT.mkdir(parents=True,exist_ok=True)
auth=json.loads(pathlib.Path(sys.argv[1]).read_text())
manifest_path=OUT/'discover-audio.json'
manifest=json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
jobs={}
for path in json.loads(CATALOG.read_text())['paths']:
 for step in path['steps']:
  for voice in ['feminine','masculine']:
   for part in ['guidance','closing']:
    key=hashlib.sha256((voice+step[part]['en']).encode()).hexdigest()
    jobs.setdefault(key,{'stepID':step['id'],'voice':voice,'part':part,'aliases':[]})['aliases'].append(f"{step['id']}.{voice}.{part}")
def render(job):
 aliases=job['aliases']
 old=manifest.get(aliases[0])
 if old and (OUT/old['file']).exists(): return aliases,old
 req=urllib.request.Request(auth['url']+'/functions/v1/render-discover-audio',data=json.dumps({k:job[k] for k in ['stepID','voice','part']}).encode(),headers={'Content-Type':'application/json','apikey':auth['key'],'Authorization':'Bearer '+auth['token']})
 for attempt in range(3):
  try:
   with urllib.request.urlopen(req,timeout=100) as r: data=json.load(r)
   filename='discover-'+data['hash']+'.mp3'
   with urllib.request.urlopen(data['url'],timeout=60) as r: audio=r.read()
   if len(audio)<1000 or data['durationMs']<1000: raise ValueError('Invalid audio output')
   (OUT/filename).write_bytes(audio)
   return aliases,{'file':filename,'durationMs':data['durationMs'],'voice':data['voice'],'locale':'en','sha256':hashlib.sha256(audio).hexdigest(),'sourceURL':data['url']}
  except urllib.error.HTTPError as e:
   body=e.read().decode()[:200]
   if e.code<500 or "payment_required" in body or "provider_configuration_required" in body or attempt==2: raise RuntimeError(f"{job['stepID']}: HTTP {e.code} {body}")
   time.sleep(2+attempt)
  except Exception:
   if attempt==2: raise
   time.sleep(2+attempt)
# Fail on credentials/billing before scheduling the full catalog.
first_key = next(iter(jobs))
first_aliases, first_data = render(jobs.pop(first_key))
for alias in first_aliases: manifest[alias] = first_data
manifest_path.write_text(json.dumps(manifest,indent=2,sort_keys=True))
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
 for future in concurrent.futures.as_completed([pool.submit(render,j) for j in jobs.values()]):
  aliases,data=future.result()
  for alias in aliases: manifest[alias]=data
  manifest_path.write_text(json.dumps(manifest,indent=2,sort_keys=True))
  print('Saved',aliases[0],data['durationMs'],'ms',flush=True)
print('Complete:',len(manifest),'cue references,',len(jobs)+1,'unique recordings')
