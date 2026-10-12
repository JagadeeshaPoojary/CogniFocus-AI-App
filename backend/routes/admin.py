from flask import Blueprint, jsonify, request
import jwt
from database.db import get_db_connection
from routes.auth import SECRET_KEY

admin_bp = Blueprint('admin', __name__)

camera_manager = None

def init_admin_routes(cm_instance):
    global camera_manager
    camera_manager = cm_instance

def verify_admin_auth(req):
    auth_header = req.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return None
    token = auth_header.split(' ')[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        if str(payload.get('role', '')).upper() in ['ADMIN', 'ADMINISTRATOR']:
            return payload
    except Exception:
        pass
    return None

@admin_bp.route('/start-monitoring', methods=['POST'])
def start_monitoring():
    if not camera_manager:
        return jsonify({"success": False, "message": "Camera Manager not initialized"}), 500
        
    admin_user = verify_admin_auth(request)
    admin_id = admin_user.get('user_id') if admin_user else 'GLOBAL'

    active_cameras = camera_manager.start_all()
    cam_ids = [c['camera_id'] for c in active_cameras if 'camera_id' in c]
    
    # Register Admin lease
    camera_manager.add_camera_lease(f"ADMIN_{admin_id}", cam_ids)

    return jsonify({
        "success": True,
        "message": f"Successfully initialized {len(active_cameras)} camera monitoring workers",
        "monitoring": True,
        "cameras": active_cameras
    })

@admin_bp.route('/stop-monitoring', methods=['POST'])
def stop_monitoring():
    if not camera_manager:
        return jsonify({"success": False, "message": "Camera Manager not initialized"}), 500
        
    admin_user = verify_admin_auth(request)
    admin_id = admin_user.get('user_id') if admin_user else 'GLOBAL'

    # Release Admin lease and stop unreferenced cameras
    unreferenced = camera_manager.remove_camera_lease(f"ADMIN_{admin_id}")
    if unreferenced:
        camera_manager.stop_cameras(unreferenced)

    return jsonify({
        "success": True,
        "message": f"Admin monitoring released. {len(unreferenced)} unreferenced camera workers stopped.",
        "monitoring": False
    })

@admin_bp.route('/cameras/discover', methods=['GET'])
def discover_cameras():
    if not camera_manager:
        return jsonify({"success": False, "message": "Camera Manager not initialized"}), 500
        
    cameras = camera_manager.discover_cameras()
    return jsonify({"success": True, "cameras": cameras})
