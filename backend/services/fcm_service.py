import os
import sys
import json
import sqlite3
import datetime

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
try:
    from database.db import get_db_connection
except ImportError:
    from backend.database.db import get_db_connection

try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False


class FCMService:
    def __init__(self):
        self.app = None
        self.is_initialized = False
        self._init_firebase_admin()

    def _init_firebase_admin(self):
        """Initializes Firebase Admin SDK from environment or config file."""
        if not FIREBASE_AVAILABLE:
            print("[FCMService] firebase-admin package is not installed.")
            return

        # 1. Check already initialized
        try:
            self.app = firebase_admin.get_app()
            self.is_initialized = True
            print("[FCMService] Firebase Admin default app is already initialized.")
            return
        except ValueError:
            pass

        # 2. Candidate credential paths
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        candidate_paths = [
            os.getenv("FIREBASE_CREDENTIALS_PATH"),
            os.getenv("GOOGLE_APPLICATION_CREDENTIALS"),
            os.path.join(base_dir, 'config', 'firebase_credentials.json'),
            os.path.join(base_dir, 'config', 'serviceAccountKey.json'),
            os.path.join(base_dir, 'firebase_credentials.json'),
        ]

        cred_path = None
        for p in candidate_paths:
            if p and os.path.exists(p) and os.path.isfile(p):
                cred_path = p
                break

        if cred_path:
            try:
                cred = credentials.Certificate(cred_path)
                self.app = firebase_admin.initialize_app(cred)
                self.is_initialized = True
                print(f"[FCMService] Firebase Admin successfully initialized using credentials at: {cred_path}")
            except Exception as e:
                print(f"[FCMService] Failed to initialize Firebase Admin with credentials at {cred_path}: {e}")
        else:
            print("[FCMService] Firebase credentials file not found.")
            print("[FCMService] Standby mode: Place your Firebase Service Account JSON at 'backend/config/firebase_credentials.json' or set FIREBASE_CREDENTIALS_PATH.")

    def is_configured(self):
        return self.is_initialized and self.app is not None

    def register_device_token(self, teacher_id, fcm_token, device_id=None, platform='android'):
        """Registers or refreshes an FCM device token for an authenticated teacher."""
        if not teacher_id or not fcm_token:
            return False, "teacher_id and fcm_token are required"

        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO teacher_device_tokens (teacher_id, device_id, fcm_token, platform, is_active, updated_at)
                VALUES (?, ?, ?, ?, 1, CURRENT_TIMESTAMP)
                ON CONFLICT(fcm_token) DO UPDATE SET
                    teacher_id = excluded.teacher_id,
                    device_id = COALESCE(excluded.device_id, teacher_device_tokens.device_id),
                    platform = excluded.platform,
                    is_active = 1,
                    updated_at = CURRENT_TIMESTAMP
            """, (teacher_id, device_id, fcm_token, platform))
            conn.commit()
            conn.close()
            print(f"[FCMService] Device token registered for teacher #{teacher_id} (Platform: {platform})")
            return True, None
        except Exception as e:
            print(f"[FCMService] Error registering device token for teacher #{teacher_id}: {e}")
            return False, str(e)

    def unregister_device_token(self, teacher_id, fcm_token=None, device_id=None):
        """Deactivates a device token upon teacher logout without affecting other active devices."""
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            if fcm_token:
                cursor.execute("""
                    UPDATE teacher_device_tokens
                    SET is_active = 0, updated_at = CURRENT_TIMESTAMP
                    WHERE teacher_id = ? AND fcm_token = ?
                """, (teacher_id, fcm_token))
            elif device_id:
                cursor.execute("""
                    UPDATE teacher_device_tokens
                    SET is_active = 0, updated_at = CURRENT_TIMESTAMP
                    WHERE teacher_id = ? AND device_id = ?
                """, (teacher_id, device_id))
            else:
                cursor.execute("""
                    UPDATE teacher_device_tokens
                    SET is_active = 0, updated_at = CURRENT_TIMESTAMP
                    WHERE teacher_id = ?
                """, (teacher_id,))
            conn.commit()
            conn.close()
            print(f"[FCMService] Deactivated FCM token for teacher #{teacher_id}")
            return True, None
        except Exception as e:
            print(f"[FCMService] Error unregistering device token: {e}")
            return False, str(e)

    def get_active_tokens_for_teacher(self, teacher_id):
        """Returns all active FCM tokens for a given teacher ID."""
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("""
                SELECT id, fcm_token, device_id, platform
                FROM teacher_device_tokens
                WHERE (teacher_id = ? OR CAST(teacher_id AS TEXT) = CAST(? AS TEXT))
                  AND is_active = 1
            """, (teacher_id, str(teacher_id)))
            rows = cursor.fetchall()
            conn.close()
            return [dict(r) for r in rows]
        except Exception as e:
            print(f"[FCMService] Error fetching active tokens for teacher #{teacher_id}: {e}")
            return []

    def send_alert_push(self, teacher_id, alert_data):
        """
        Sends high-priority FCM push notification to all active devices registered to the teacher.
        Safe against failures: never raises exceptions or interrupts AI detection loop.
        """
        tokens_info = self.get_active_tokens_for_teacher(teacher_id)
        if not tokens_info:
            print(f"[FCMService] No active FCM device tokens registered for teacher #{teacher_id}.")
            return {"sent": 0, "failed": 0, "reason": "No registered tokens"}

        alert_id = alert_data.get('id')
        classroom_id = alert_data.get('classroom_id') or 'CSE301'
        camera_id = alert_data.get('camera_id') or 'CAM001'
        duration = alert_data.get('duration') or ''
        dur_str = f" • Duration: {duration}s" if duration and str(duration) != '0' else ""

        title = "Possible Mobile Phone Usage Detected"
        body = f"Classroom {classroom_id} • Camera {camera_id}{dur_str}"

        # Stringified payload required by FCM data message
        data_payload = {
            "alert_id": str(alert_id or ''),
            "classroom_id": str(classroom_id),
            "camera_id": str(camera_id),
            "student_id": str(alert_data.get('student_id') or ''),
            "seat_id": str(alert_data.get('seat_id') or ''),
            "alert_type": str(alert_data.get('alert_type') or 'Possible Mobile Phone Usage'),
            "duration": str(duration),
            "timestamp": str(alert_data.get('timestamp') or datetime.datetime.now().isoformat()),
            "severity": str(alert_data.get('severity') or 'High'),
            "click_action": "FLUTTER_NOTIFICATION_CLICK"
        }

        if not self.is_configured():
            print(f"[FCMService] Firebase Admin not configured with credentials file. Simulating FCM dispatch for {len(tokens_info)} devices.")
            self._log_fcm(alert_id, teacher_id, "FCM", f"{len(tokens_info)} devices", "STANDBY (Credentials not placed)", None)
            return {"sent": 0, "simulated": len(tokens_info), "reason": "Credentials not placed"}

        sent_count = 0
        failed_count = 0
        invalid_tokens = []

        for item in tokens_info:
            token = item['fcm_token']
            token_id = item['id']
            try:
                message = messaging.Message(
                    token=token,
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                    ),
                    data=data_payload,
                    android=messaging.AndroidConfig(
                        priority='high',
                        notification=messaging.AndroidNotification(
                            channel_id='cognifocus_alerts_channel',
                            sound='default',
                            default_vibrate_timings=True,
                            click_action='FLUTTER_NOTIFICATION_CLICK'
                        )
                    )
                )

                response = messaging.send(message)
                sent_count += 1
                print(f"[FCMService] FCM alert push sent successfully to token ending with ...{token[-8:]}: {response}")
                self._log_fcm(alert_id, teacher_id, "FCM", token, "SENT", None)
            except Exception as e:
                failed_count += 1
                err_str = str(e)
                print(f"[FCMService] FCM delivery error for token ending with ...{token[-8:]}: {err_str}")
                self._log_fcm(alert_id, teacher_id, "FCM", token, "FAILED", err_str)

                # Check if token is invalid or unregistered
                if any(k in err_str.lower() for k in ['unregistered', 'invalid', 'not-found', 'not_found', 'registration-token-not-registered']):
                    invalid_tokens.append(token_id)

        # Deactivate expired/invalid tokens
        if invalid_tokens:
            try:
                conn = get_db_connection()
                cursor = conn.cursor()
                cursor.executemany("UPDATE teacher_device_tokens SET is_active = 0 WHERE id = ?", [(tid,) for tid in invalid_tokens])
                conn.commit()
                conn.close()
                print(f"[FCMService] Deactivated {len(invalid_tokens)} expired or invalid FCM device tokens.")
            except Exception as cleanup_err:
                print(f"[FCMService] Error deactivating invalid tokens: {cleanup_err}")

        return {"sent": sent_count, "failed": failed_count}

    def send_test_push(self, teacher_id, custom_message=None):
        """Dispatches a test push notification to verify FCM connectivity."""
        tokens = self.get_active_tokens_for_teacher(teacher_id)
        if not tokens:
            return False, "No active device tokens found for this teacher. Please log in on your phone first."

        if not self.is_configured():
            return False, "Firebase Admin credentials not found at backend/config/firebase_credentials.json."

        title = "🚨 [TEST] CogniFocus-AI Alert"
        body = custom_message or "Classroom CSE301 • Camera CAM001 • Test Push Notification"

        sent = 0
        for item in tokens:
            token = item['fcm_token']
            try:
                msg = messaging.Message(
                    token=token,
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                    ),
                    data={
                        "is_test": "true",
                        "alert_id": "0",
                        "alert_type": "Test Alert",
                        "classroom_id": "CSE301",
                        "camera_id": "CAM001",
                        "duration": "10",
                        "timestamp": datetime.datetime.now().isoformat(),
                        "click_action": "FLUTTER_NOTIFICATION_CLICK"
                    },
                    android=messaging.AndroidConfig(
                        priority='high',
                        notification=messaging.AndroidNotification(
                            channel_id='cognifocus_alerts_channel',
                            sound='default',
                            default_vibrate_timings=True,
                            click_action='FLUTTER_NOTIFICATION_CLICK'
                        )
                    )
                )
                messaging.send(msg)
                sent += 1
            except Exception as e:
                print(f"[FCMService] Test push failure for token ...{token[-8:]}: {e}")

        return (sent > 0), f"Test push sent to {sent}/{len(tokens)} device(s)."

    def _log_fcm(self, alert_id, recipient_id, channel, recipient, status, error_message):
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO notification_logs (alert_id, recipient_id, channel, recipient, status, error_message)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (alert_id, recipient_id, channel, recipient[:50], status, str(error_message) if error_message else None))
            conn.commit()
            conn.close()
        except Exception:
            pass


fcm_service = FCMService()
