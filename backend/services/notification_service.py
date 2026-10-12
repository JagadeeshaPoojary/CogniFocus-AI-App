import os
import time
import threading
import datetime
import sqlite3
from database.db import get_db_connection
from services.email_service import email_service
from services.sms_service import sms_service

from concurrent.futures import ThreadPoolExecutor

class NotificationService:
    def __init__(self):
        self.cooldown_seconds = int(os.getenv("NOTIFICATION_COOLDOWN_SECONDS", 30))
        self.last_notification_times = {} # key -> timestamp
        self.lock = threading.Lock()
        self.executor = ThreadPoolExecutor(max_workers=2, thread_name_prefix="NotificationWorker")

    def notify_alert_async(self, alert_data):
        """
        Asynchronous wrapper ensuring AI detection loop is NEVER blocked.
        Queues tasks in a bounded ThreadPoolExecutor to prevent thread exhaustion.
        """
        try:
            self.executor.submit(self._process_alert_notification, alert_data)
        except Exception as e:
            print(f"[NotificationService] ThreadPool submit warning: {e}")

    def _process_alert_notification(self, alert_data):
        """
        Core notification dispatch:
        1. Duplicate cooldown protection.
        2. Classroom-wise teacher session & admin recipient lookup.
        3. Preference validation (Email / SMS ON/OFF).
        4. Dispatch & SQLite logging to notification_logs table.
        """
        alert_id = alert_data.get('id')
        classroom_id = alert_data.get('classroom_id') or 'CSE-301'
        classroom_code = alert_data.get('classroom_code') or classroom_id.replace('-', '')
        seat_id = alert_data.get('seat_id') or alert_data.get('seat') or 'N/A'
        student_id = alert_data.get('student_id') or 'N/A'
        camera_id = alert_data.get('camera_id') or 'CAM001'
        duration = alert_data.get('duration') or 10

        alert_data['classroom_code'] = classroom_code

        # 1. Duplicate Cooldown Protection (Section 18 & 19)
        cooldown_key = (classroom_id, camera_id, seat_id, student_id)
        now_t = time.time()
        with self.lock:
            last_t = self.last_notification_times.get(cooldown_key, 0)
            if (now_t - last_t) < self.cooldown_seconds:
                print(f"[NotificationService] Cooldown active for {cooldown_key} ({int(now_t - last_t)}s < {self.cooldown_seconds}s). Skipping duplicate notification.")
                return
            self.last_notification_times[cooldown_key] = now_t

        print("\n========================================")
        print("ALERT CREATED")
        print("========================================")
        print(f"Alert ID: #{alert_id}")
        print(f"Classroom: {classroom_id}")
        print(f"Student: {student_id}")
        print(f"Camera: {camera_id}")
        print(f"Duration: {duration}s")
        print(f"Evidence: {alert_data.get('evidence_image') or 'saved'}")
        print("========================================\n")

        recipients = self._find_recipients(classroom_id, classroom_code)

        if not recipients:
            print(f"[NotificationService] No active teacher or admin recipients found for classroom {classroom_id}.")
            return

        for user in recipients:
            user_id = user['id']
            email = user.get('notification_email') or user.get('email')
            phone = user.get('notification_phone') or user.get('phone')
            email_enabled = bool(user.get('email_notifications_enabled', 1))
            sms_enabled = bool(user.get('sms_notifications_enabled', 1))

            # Send Email
            if email_enabled and email:
                success, err = email_service.send_alert_email(email, alert_data)
                status_str = "SENT" if success else ("NOT CONFIGURED" if "NOT CONFIGURED" in str(err) else "FAILED")
                print(f"\nEMAIL NOTIFICATION\nRecipient: {email}\nStatus: {status_str}")
                self._log_notification(alert_id, user_id, "EMAIL", email, status_str, err)
            else:
                print(f"\nEMAIL NOTIFICATION\nRecipient: {email or 'None'}\nStatus: SKIPPED (Disabled in settings)")

            # Send SMS
            if sms_enabled and phone:
                success, err = sms_service.send_alert_sms(phone, alert_data)
                status_str = "SENT" if success else ("NOT CONFIGURED" if "NOT CONFIGURED" in str(err) else "FAILED")
                print(f"\nSMS NOTIFICATION\nRecipient: {phone}\nStatus: {status_str}")
                self._log_notification(alert_id, user_id, "SMS", phone, status_str, err)
            else:
                print(f"\nSMS NOTIFICATION\nRecipient: {phone or 'None'}\nStatus: SKIPPED (Disabled in settings)")

        # Real-Time Teacher Notifications (Level 1 SSE + Level 2 Web Push)
        # TEACHERS ONLY - ADMIN MUST NOT RECEIVE CLASSROOM POPUP NOTIFICATIONS
        teacher_recipients = [u for u in recipients if str(u.get('role', '')).upper() == 'TEACHER']
        for t_user in teacher_recipients:
            t_id = t_user['id']
            try:
                from services.sse_service import sse_manager
                sse_manager.broadcast_to_teacher(t_id, {
                    "type": "NEW_ALERT",
                    "alert": alert_data
                })
                print(f"[NOTIFICATION] Teacher notification sent to Teacher ID #{t_id} for Alert #{alert_id}", flush=True)
                print(f"[NOTIFICATION] Alert sound triggered for Alert #{alert_id}", flush=True)
            except Exception as sse_err:
                print(f"[NOTIFICATION] SSE broadcast error for Teacher ID #{t_id}: {sse_err}", flush=True)

            try:
                from services.push_service import push_service
                push_service.send_push_to_teacher(t_id, alert_data)
                print(f"[NOTIFICATION] Web Push delivered to Teacher ID #{t_id}", flush=True)
            except Exception as push_err:
                print(f"[NOTIFICATION] Web Push error for Teacher ID #{t_id}: {push_err}", flush=True)

            try:
                from services.fcm_service import fcm_service
                fcm_res = fcm_service.send_alert_push(t_id, alert_data)
                print(f"[NOTIFICATION] FCM Android push dispatched for Teacher ID #{t_id}: {fcm_res}", flush=True)
            except Exception as fcm_err:
                print(f"[NOTIFICATION] FCM push error for Teacher ID #{t_id}: {fcm_err}", flush=True)

    def _find_recipients(self, classroom_id, classroom_code):
        """
        Finds target notification recipients:
        - Active monitoring teacher for the classroom (Classroom-wise routing)
        - Assigned teachers for classroom
        - Admin users (Global monitoring access)
        """
        recipients = []
        try:
            # 0. Check in-memory active teacher sessions for immediate real-time routing
            try:
                from routes.teacher import TEACHER_SESSIONS
                for uid, sess in TEACHER_SESSIONS.items():
                    if sess and sess.get('monitoring_active'):
                        s_cid = str(sess.get('classroom_id', '')).upper()
                        s_code = str(sess.get('classroom_code', '')).upper()
                        req_cid = str(classroom_id).upper()
                        req_code = str(classroom_code).upper()
                        if (s_cid in (req_cid, req_code) or 
                            s_code in (req_cid, req_code) or 
                            s_cid.replace('-', '') == req_cid.replace('-', '')):
                            recipients.append({
                                "id": sess.get('user_id'),
                                "role": "TEACHER",
                                "name": sess.get('user_name', 'Teacher'),
                                "email": sess.get('email', 'teacher@classroom.com')
                            })
            except Exception as mem_err:
                print(f"[NotificationService] In-memory session lookup exception: {mem_err}")

            conn = get_db_connection()
            try:
                cursor = conn.cursor()

                # 1. Find active monitoring teacher for this classroom from DB
                norm_cid = classroom_id.upper().replace('-', '')
                cursor.execute("""
                    SELECT u.* FROM users u
                    JOIN teacher_monitoring_sessions tm 
                      ON (tm.teacher_id = u.id OR CAST(tm.teacher_id AS TEXT) = CAST(u.id AS TEXT))
                    WHERE (UPPER(tm.classroom_id) = ? 
                       OR UPPER(tm.classroom_code) = ? 
                       OR UPPER(REPLACE(tm.classroom_id, '-', '')) = ?) 
                      AND tm.status = 'ACTIVE'
                """, (classroom_id.upper(), classroom_code.upper(), norm_cid))
                active_teachers = cursor.fetchall()
                for r in active_teachers:
                    recipients.append(dict(r))

                # 2. If no active session, find assigned teachers for this classroom
                if not recipients:
                    cursor.execute("""
                        SELECT u.* FROM users u
                        JOIN teacher_classroom_assignments tca 
                          ON (tca.teacher_id = u.id OR CAST(tca.teacher_id AS TEXT) = CAST(u.id AS TEXT))
                        WHERE UPPER(tca.classroom_id) = ? 
                           OR UPPER(tca.classroom_id) = ? 
                           OR UPPER(REPLACE(tca.classroom_id, '-', '')) = ?
                    """, (classroom_id.upper(), classroom_code.upper(), norm_cid))
                    assigned_teachers = cursor.fetchall()
                    for r in assigned_teachers:
                        recipients.append(dict(r))

                # 3. Always check default teacher@classroom.com if list still empty
                if not recipients:
                    cursor.execute("SELECT * FROM users WHERE role = 'TEACHER' AND email = 'teacher@classroom.com'")
                    t_row = cursor.fetchone()
                    if t_row:
                        recipients.append(dict(t_row))

                # 4. Global Admin users
                cursor.execute("SELECT * FROM users WHERE role = 'ADMIN'")
                admin_rows = cursor.fetchall()
                for r in admin_rows:
                    recipients.append(dict(r))
            finally:
                conn.close()
        except Exception as e:
            print(f"[NotificationService] Recipient lookup query exception: {e}")

        # Deduplicate recipients by ID
        unique_recipients = {}
        for user in recipients:
            unique_recipients[user['id']] = user
        return list(unique_recipients.values())

    def _log_notification(self, alert_id, recipient_id, channel, recipient, status, error_message):
        try:
            conn = get_db_connection()
            try:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT INTO notification_logs (alert_id, recipient_id, channel, recipient, status, error_message)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (alert_id, recipient_id, channel, recipient, status, str(error_message) if error_message else None))
                conn.commit()
            finally:
                conn.close()
        except Exception as e:
            print(f"[NotificationService] Failed to insert notification log: {e}")

notification_service = NotificationService()
