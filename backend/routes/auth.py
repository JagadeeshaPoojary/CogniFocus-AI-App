from flask import Blueprint, request, jsonify
from werkzeug.security import check_password_hash
import jwt
import datetime
import os
from database.db import get_db_connection

auth_bp = Blueprint('auth', __name__)
SECRET_KEY = "cognifocus_ai_secret_key_prod_demo"

camera_manager = None

def init_auth_routes(cm_instance):
    global camera_manager
    camera_manager = cm_instance

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    email = data.get('email', '').strip().lower()
    password = data.get('password', '')

    if not email or not password:
        return jsonify({"success": False, "message": "Email and password are required"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE LOWER(email) = ?", (email,))
    user = cursor.fetchone()
    conn.close()

    if not user:
        return jsonify({"success": False, "message": "Invalid email or password"}), 401

    if not check_password_hash(user['password_hash'], password):
        return jsonify({"success": False, "message": "Invalid email or password"}), 401

    token = jwt.encode({
        'user_id': user['id'],
        'email': user['email'],
        'role': user['role'],
        'name': user['name'],
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
    }, SECRET_KEY, algorithm='HS256')

    user_role = str(user['role']).upper()

    # Admin Policy: Automatically initialize all configured system cameras upon Admin login
    if user_role == 'ADMIN' and camera_manager:
        try:
            active_info = camera_manager.start_all()
            active_cams = [c['camera_id'] for c in active_info]
            camera_manager.add_camera_lease(f"ADMIN_{user['id']}", active_cams)
            print(f"[Auth Login] Admin policy triggered: Started {len(active_info)} configured camera workers.")
        except Exception as err:
            print(f"[Auth Login] Warning: Admin auto camera start exception: {err}")

    return jsonify({
        "success": True,
        "message": "Login successful",
        "token": token,
        "user": {
            "id": user['id'],
            "email": user['email'],
            "role": user['role'],
            "name": user['name']
        }
    }), 200

@auth_bp.route('/me', methods=['GET'])
def get_me():
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({"success": False, "message": "Unauthorized"}), 401

    token = auth_header.split(' ')[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        return jsonify({
            "success": True,
            "user": {
                "id": payload['user_id'],
                "email": payload['email'],
                "role": payload['role'],
                "name": payload['name']
            }
        })
    except jwt.ExpiredSignatureError:
        return jsonify({"success": False, "message": "Token expired"}), 401
    except jwt.InvalidTokenError:
        return jsonify({"success": False, "message": "Invalid token"}), 401

@auth_bp.route('/logout', methods=['POST'])
def logout():
    auth_header = request.headers.get('Authorization')
    if auth_header and auth_header.startswith('Bearer '):
        token = auth_header.split(' ')[1]
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
            user_id = payload.get('user_id')
            user_role = str(payload.get('role', '')).upper()
            if camera_manager:
                sess_prefix = "ADMIN" if user_role == "ADMIN" else "TEACHER"
                unreferenced = camera_manager.remove_camera_lease(f"{sess_prefix}_{user_id}")
                if unreferenced:
                    camera_manager.stop_cameras(unreferenced)
        except Exception:
            pass

    return jsonify({"success": True, "message": "Logged out successfully"})
