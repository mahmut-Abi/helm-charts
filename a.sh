kubectl exec -n sentry deploy/sentry-web -- python -c "
from django.conf import settings
settings.configure()
import django; django.setup()
from sentry.models.project import Project
for p in Project.objects.all():
    print(p.id, p.slug, p.organization_id)
"

kubectl exec -n sentry deploy/sentry-web -- python -c "
import urllib.request, time
t0 = time.time()
pk = 'd8be6d6aa5e2f58bc50509467458eaa4'
url = f'http://localhost:9000/api/0/relays/projectconfigs/?version=3&projectKeys={pk}'
try:
    resp = urllib.request.urlopen(url, timeout=30)
    body = resp.read().decode()
    print(f'HTTP {resp.status} in {time.time()-t0:.1f}s')
    print(body[:500])
except Exception as e:
    print(f'Error after {time.time()-t0:.1f}s: {e}')
"

kubectl exec -n dify deploy/dify-api -- python3 -c "
import socket
s = socket.socket()
s.settimeout(5)
s.connect(('sentry-relay.sentry', 3000))
print('TCP connected')
s.close()
"

kubectl exec -n dify deploy/dify-api -- python3 -c "
import sentry_sdk
sentry_sdk.init(dsn='http://d8be6d6aa5e2f58bc50509467458eaa4@sentry-relay.sentry:3000/4')
try: 1/0
except Exception as e: sentry_sdk.capture_exception(e)
sentry_sdk.flush(timeout=10)
print('sent')
"

kubectl exec -n sentry deploy/sentry-web -- python3 -c "
import urllib.request, json, base64
r = urllib.request.urlopen('http://localhost:9000/api/0/projects/', timeout=30)
projects = json.loads(r.read())
for p in projects:
    try:
        pk_resp = urllib.request.urlopen(f'http://localhost:9000/api/0/projects/{p[\"organization\"][\"slug\"]}/{p[\"slug\"]}/keys/', timeout=10)
        keys = json.loads(pk_resp.read())
        for k in keys:
            print(f'project_id={p[\"id\"]} slug={p[\"slug\"]} public_key={k[\"public\"][:20]}...')
    except:
        pass
"

kubectl exec -n sentry deploy/sentry-web -- python3 -c "
import urllib.request, json
r = urllib.request.urlopen('http://127.0.0.1:9000/api/0/projects/', timeout=30)
projects = json.loads(r.read())
for p in projects:
    try:
        pk_resp = urllib.request.urlopen(f'http://127.0.0.1:9000/api/0/projects/{p[\"organization\"][\"slug\"]}/{p[\"slug\"]}/keys/', timeout=10)
        keys = json.loads(pk_resp.read())
        for k in keys:
            print(f'project_id={p[\"id\"]} slug={p[\"slug\"]} public_key={k[\"public\"][:20]}...')
    except Exception as e:
        print(f'ERROR for {p[\"slug\"]}: {e}')
"

kubectl exec -n sentry deploy/sentry-web -- sentry exec --python -c "
from sentry.models.project import Project
from sentry.models.projectkey import ProjectKey
for p in Project.objects.all():
    keys = ProjectKey.objects.filter(project=p)
    for k in keys:
        print(f'project_id={p.id} slug={p.slug} org={p.organization.slug} public_key={k.public_key}')
"

kubectl exec -n sentry deploy/sentry-web -- sentry exec --python -c "
from sentry.models.project import Project
print(f'Total projects in DB: {Project.objects.count()}')
from sentry.models.organization import Organization
for org in Organization.objects.all():
    print(f'org={org.slug} id={org.id}')
"

kubectl exec -n sentry deploy/sentry-web -- python3 -c "
import urllib.request, time
start=time.time()
r=urllib.request.urlopen('http://127.0.0.1:9000/api/0/relays/projectconfigs/?version=3', timeout=30)
data=r.read()
print(f'http_code={r.status} time={time.time()-start:.1f}s size={len(data)}')
"

kubectl exec -n sentry deploy/sentry-web -- python3 -c "
import urllib.request, json, uuid
event_id = uuid.uuid4().hex
body = json.dumps({'event_id': event_id, 'message': 'test-direct'}).encode()
req = urllib.request.Request('http://127.0.0.1:9000/api/4/envelope/', data=body, method='POST')
req.add_header('Content-Type', 'application/x-sentry-envelope')
req.add_header('X-Sentry-Auth', 'Sentry sentry_version=7, sentry_client=test/1.0, sentry_key=d8be6d6aa5e2f58bc50509467458eaa4')
r = urllib.request.urlopen(req, timeout=30)
print(f'http_code={r.status} body={r.read().decode()[:200]}')
"

kubectl exec -n dify deploy/dify-api -- python3 -c "
import sentry_sdk
sentry_sdk.init(dsn='http://d8be6d6aa5e2f58bc50509467458eaa4@sentry-relay.sentry.svc.cluster.local:3000/4')
sentry_sdk.capture_message('relay-fixed-test')
print('sent')
"

kubectl exec -n sentry deploy/sentry-snuba-consumer -- python3 -c "
from confluent_kafka import Consumer, KafkaError
c = Consumer({'bootstrap.servers': 'kafka.public-services:9092', 'group.id': 'debug-check', 'auto.offset.reset': 'latest', 'enable.auto.commit': False})
c.subscribe(['ingest-events'])
import time
start = time.time()
while time.time() - start < 10:
    msg = c.poll(1.0)
    if msg and not msg.error():
        print(f'offset={msg.offset()} key={msg.key()} value={msg.value()[:200]}')
        break
c.close()
"

kubectl exec -n sentry deploy/sentry-web -- sentry exec --python -c "
from sentry.models.group import Group
from sentry.models.project import Project
p = Project.objects.get(slug='dify-api')
groups = Group.objects.filter(project=p).order_by('-id')[:5]
for g in groups:
    print(f'id={g.id} message={g.message} status={g.status}')
"

kubectl exec -n dify deploy/dify-api -- python3 -c "
import sentry_sdk
sentry_sdk.init(dsn='http://d8be6d6aa5e2f58bc50509467458eaa4@sentry-relay.sentry.svc.cluster.local:3000/4')
sentry_sdk.capture_exception(Exception('pipeline-test-2'))
print('sent')
" && sleep 3 && kubectl logs -n sentry deploy/sentry-relay --tail=30 2>&1 | grep -i "d8be6d\|envelope\|event\|outcome\|accepted\|processed"

kubectl exec -n sentry deploy/sentry-snuba-consumer -- python3 -c "
from confluent_kafka import Consumer
c = Consumer({'bootstrap.servers': 'kafka.public-services:9092', 'group.id': 'debug-check-2', 'auto.offset.reset': 'earliest', 'enable.auto.commit': False})
c.subscribe(['ingest-events'])
import time
start = time.time()
while time.time() - start < 15:
    msg = c.poll(1.0)
    if msg and not msg.error():
        val = msg.value()
        if b'pipeline' in val or b'relay-fixed' in val:
            print(f'FOUND: offset={msg.offset()} value={val[:300]}')
c.close()
print('done')
"

kubectl exec -n dify deploy/dify-api -- python3 -c "
import sentry_sdk
sentry_sdk.init(dsn='http://d8be6d6aa5e2f58bc50509467458eaa4@sentry-relay.sentry.svc.cluster.local:3000/4')
sentry_sdk.capture_exception(Exception('pipeline-final-test'))
print('sent')
"

kubectl exec -n sentry deploy/sentry-web -- sentry exec --python -c "
    from sentry.models.group import Group
    from sentry.models.project import Project
    p = Project.objects.get(slug='dify-api')
    groups = Group.objects.filter(project=p).order_by('-id')[:5]
    for g in groups:
        print(f'id={g.id} message={g.message} status={g.status}')
    "
