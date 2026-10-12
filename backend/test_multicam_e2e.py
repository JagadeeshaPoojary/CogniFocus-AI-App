import requests
import json
import time

BASE = 'http://10.223.8.206:5000'
session = requests.Session()

print('1. Testing Root Endpoint...')
r = session.get(f'{BASE}/', timeout=5)
assert r.status_code == 200, f'Root failed: {r.status_code}'
print('   Root OK:', r.json())

print('2. Logging in as Teacher...')
r = session.post(f'{BASE}/api/auth/login', json={'email': 'teacher@classroom.com', 'password': 'password123'}, timeout=5)
if r.status_code != 200:
    r = session.post(f'{BASE}/api/auth/login', json={'email': 'teacher@classroom.com', 'password': 'teacher123'}, timeout=5)
assert r.status_code == 200, f'Login failed: {r.status_code} {r.text}'
login_data = r.json()
token = login_data['token']
headers = {'Authorization': f'Bearer {token}'}
print('   Login OK: User =', login_data['user']['name'])

print('3. Fetching Teacher Classrooms...')
r = session.get(f'{BASE}/api/teacher/classrooms', headers=headers, timeout=5)
assert r.status_code == 200, f'Classrooms failed: {r.status_code}'
classrooms = r.json().get('classrooms', [])
print('   Classrooms OK:', [c.get('code') for c in classrooms])

print('4. Entering Classroom CSE301 (Start Monitoring)...')
r = session.post(f'{BASE}/api/teacher/classroom/enter', headers=headers, json={'classroom_code': 'CSE301'}, timeout=10)
assert r.status_code == 200, f'Enter failed: {r.status_code} {r.text}'
enter_data = r.json()
print('   Enter OK: Classroom =', enter_data.get('classroom_name') or enter_data.get('classroom_id'), 'Cameras =', enter_data.get('cameras'))

# Wait for camera workers to become online
print('5. Waiting for Teacher Camera Statuses to become online...')
for _ in range(12):
    time.sleep(1.0)
    r = session.get(f'{BASE}/api/teacher/cameras', headers=headers, timeout=5)
    cams = r.json().get('cameras', [])
    if all(c.get('opened') for c in cams) and len(cams) >= 2:
        break

assert r.status_code == 200, f'Get cameras failed: {r.status_code}'
cams = r.json().get('cameras', [])
for cam in cams:
    print(f'   Camera {cam.get("camera_id")}: status={cam.get("status")}, opened={cam.get("opened")}, frame_available={cam.get("frame_available")}, fps={cam.get("fps")}')
assert all(c.get('opened') for c in cams), 'Not all cameras opened'

print('6. Fetching live frame.jpg from CAM001...')
r = session.get(f'{BASE}/api/cameras/CAM001/frame.jpg', headers=headers, timeout=5)
assert r.status_code == 200, f'CAM001 frame failed: {r.status_code}'
assert len(r.content) > 1000, f'CAM001 frame too small: {len(r.content)} bytes'
print(f'   CAM001 Frame OK: {len(r.content)} bytes (JPEG header: {r.content[:2].hex()})')

print('7. Fetching live frame.jpg from CAM002...')
r = session.get(f'{BASE}/api/cameras/CAM002/frame.jpg', headers=headers, timeout=5)
assert r.status_code == 200, f'CAM002 frame failed: {r.status_code}'
assert len(r.content) > 1000, f'CAM002 frame too small: {len(r.content)} bytes'
print(f'   CAM002 Frame OK: {len(r.content)} bytes (JPEG header: {r.content[:2].hex()})')

print('8. Testing idempotent re-entry of CSE301...')
r = session.post(f'{BASE}/api/teacher/classroom/enter', headers=headers, json={'classroom_code': 'CSE301'}, timeout=10)
assert r.status_code == 200, f'Re-enter failed: {r.status_code}'
print('   Re-entry OK!')

print('9. Leaving Classroom CSE301 (Stop Monitoring)...')
r = session.post(f'{BASE}/api/teacher/classroom/leave', headers=headers, timeout=5)
assert r.status_code == 200, f'Leave failed: {r.status_code}'
print('   Leave OK: monitoring_active =', r.json().get('monitoring_active'))

print('10. Verifying Stopped Camera Status...')
r = session.get(f'{BASE}/api/teacher/cameras', headers=headers, timeout=5)
assert r.status_code == 200
print('   Cameras after leave:', r.json())

print('\n*** ALL 10 TESTS PASSED CLEANLY! ***')
