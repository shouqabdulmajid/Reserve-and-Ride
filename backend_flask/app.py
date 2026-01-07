import mysql.connector
from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import os
import datetime
import logging
import time

logging.basicConfig(level=logging.INFO)

try:
    from db_config import get_connection
except ImportError:
    print("="*50)
    print("❌ خطأ فادح: لم يتم العثور على ملف 'db_config.py'.")
    print("يرجى إنشاء ملف 'db_config.py' يحتوي على دالة get_connection() لإعداد الاتصال بقاعدة البيانات.")
    print("="*50)
    exit(1)



app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


def check_db_connection():
    """التحقق من اتصال قاعدة البيانات عند بدء تشغيل الخادم."""
    try:
        conn = get_connection()
        if conn.is_connected():
            print("✅ نجح الاتصال بقاعدة البيانات!")
            conn.close()
            return True
        return False
    except Exception as e:
        print(f"❌ فشل الاتصال بقاعدة البيانات عند بدء التشغيل: {e}")
        return False


@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"success": False, "message": "اسم المستخدم وكلمة المرور مطلوبان"}), 400

    print("Received user login data:", data)
    logging.info(f"Attempting passenger login for username: {username}")

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT name, username, password
            FROM users
            WHERE TRIM(LOWER(username)) = TRIM(LOWER(%s))
        """, (username,))
        user = cursor.fetchone()

        if user:
            logging.info(f"Passenger found: {user['username']}")
            stored_hash = user['password']
            
            if check_password_hash(stored_hash, password):
                logging.info(f"Password match for passenger: {username}")
                full_name = user['name'] if user['name'] is not None else user['username']
                print(f"Login successful, determined full name: {full_name}")

                return jsonify({"success": True, "user": {"full_name": full_name, "username": user['username']}})
            else:
                logging.warning(f"Login failed for {username}: Password mismatch")
                return jsonify({"success": False, "message": "اسم المستخدم أو كلمة المرور غير صحيحة"}), 401
        else:
            logging.warning(f"Login failed: User {username} not found")
            return jsonify({"success": False, "message": "اسم المستخدم أو كلمة المرور غير صحيحة"}), 401
    except Exception as e:
        print("Login error:", e)
        logging.error(f"Passenger login error: {e}", exc_info=True)
        return jsonify({"success": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/register", methods=["POST"])
def register():
    data = request.form
    print("Received registration data:", data)
    priority_card = request.files.get('priority_card')

    required_fields = ["id", "name", "password", "username", "email", "birth_date", "resettle", "address", "phone"]

    for field in required_fields:
        if not data.get(field):
            return jsonify({"success": False, "message": f"الحقل '{field}' مطلوب للتسجيل"}), 400

    if not priority_card:
        return jsonify({"success": False, "message": "صورة بطاقة الأولوية مطلوبة"}), 400

    hashed_password = generate_password_hash(data["password"])

    conn = get_connection()
    cursor = conn.cursor()
    try:
        filename = secure_filename(f"{data.get('id')}_{priority_card.filename}")
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        priority_card.save(file_path)

        birth_date_str = data["birth_date"]
        
        try:
            formatted_birth_date = datetime.datetime.strptime(birth_date_str.strip(), '%Y-%m-%d').strftime('%Y-%m-%d')
        except ValueError as ve:
            print(f"Date conversion failed for {birth_date_str}: {ve}")
            return jsonify({"success": False, "message": "صيغة التاريخ غير صالحة. يجب أن تكون س-ش-ي (YYYY-MM-DD)."}), 400

        resettle_data = data.get("resettle")

        cursor.execute("""
            INSERT INTO users (
                id, name, date_of_birth, resettle_date, address, 
                username, password, email, phone, priority_card_path
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            data.get("id"),
            data.get("name"),
            formatted_birth_date,
            resettle_data,
            data.get("address"),
            data.get("username"),
            hashed_password,
            data.get("email"),
            data.get("phone"),
            file_path
        ))
        conn.commit()
        return jsonify({"success": True, "message": "تم التسجيل بنجاح. يرجى تسجيل الدخول."})
    except Exception as e:
        print("Registration error:", e)
        if '1062' in str(e):
            return jsonify({"success": False, "message": "فشل التسجيل. اسم المستخدم أو البريد الإلكتروني أو الهوية مستخدمة بالفعل."}), 409
        return jsonify({"success": False, "message": f"فشل التسجيل. ({str(e)})"}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/employee_register", methods=["POST"])
def employee_register():
    data = request.get_json()
    print("Received employee registration data:", data)

    employee_id = data.get("employee_id")
    employee_name = data.get("name")
    employee_username = data.get("username")
    password = data.get("password")
    employee_email = data.get("email")
    employee_phone = data.get("phone")

    if not all([employee_id, employee_name, employee_username, password]):
        return jsonify({"success": False, "message": "يرجى تقديم كافة البيانات المطلوبة (الرقم الوظيفي، الاسم، اسم المستخدم، كلمة المرور)"}), 400

    hashed_password = generate_password_hash(password)

    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO employee (
                employee_id,
                name,
                username,
                password,
                email,
                phone
            )
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            employee_id,
            employee_name,
            employee_username,
            hashed_password,
            employee_email,
            employee_phone
        ))
        conn.commit()
        return jsonify({"success": True, "message": "تم تسجيل حساب الموظف بنجاح."})
    except Exception as e:
        print("Employee registration error:", e)
        if '1062' in str(e):
            return jsonify({"success": False, "message": "فشل التسجيل. الرقم الوظيفي أو اسم المستخدم أو البريد الإلكتروني مستخدمة بالفعل."}), 409
        return jsonify({"success": False, "message": f"فشل تسجيل الموظف. ({str(e)})"}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/employee_login", methods=["POST"])
def employee_login():
    data = request.get_json()

    employee_credential = data.get("username")
    password = data.get("password")

    if not employee_credential or not password:
        return jsonify({"success": False, "message": "الرقم الوظيفي/اسم المستخدم وكلمة المرور مطلوبان"}), 400

    print("Received employee login data:", data)
    logging.info(f"Attempting login for credential: {employee_credential}")

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        query = """
            SELECT employee_id, name, password
            FROM employee
            WHERE TRIM(LOWER(CAST(employee_id AS CHAR))) = TRIM(LOWER(%s))
            OR TRIM(LOWER(username)) = TRIM(LOWER(%s))
        """
        cursor.execute(query, (employee_credential, employee_credential))
        employee = cursor.fetchone()

        if employee:
            logging.info(f"Employee found: {employee['employee_id']}, Name: {employee['name']}")
            stored_hash = employee["password"]

            if check_password_hash(stored_hash, password):
                logging.info(f"Password match for {employee_credential}")
                return jsonify({
                    "success": True,
                    "employee": {
                        "name": employee["name"],
                        "employee_id": employee["employee_id"]
                    }
                })
            else:
                logging.warning(f"Login failed for {employee_credential}: Password mismatch")
                return jsonify({"success": False, "message": "الرقم الوظيفي/اسم المستخدم أو كلمة المرور غير صحيحة"}), 401
        else:
            logging.warning(f"Login failed: Employee {employee_credential} not found")
            return jsonify({"success": False, "message": "الرقم الوظيفي/اسم المستخدم غير موجود"}), 401

    except Exception as e:
        print("Employee login error:", e)
        logging.error(f"Employee login error: {e}", exc_info=True)
        return jsonify({"success": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()
        

@app.route("/passenger/name_by_id/<passenger_id>", methods=["GET"])
def get_passenger_name_by_id(passenger_id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        cursor.execute("SELECT name FROM users WHERE id = %s", (passenger_id,))
        user = cursor.fetchone()
        
        if user and user.get('name'):
            return jsonify({
                "success": True,
                "name": user['name'].strip()
            })
        else:
            return jsonify({"success": False, "message": "لم يتم العثور على راكب بهذا الرقم أو بياناته ناقصة."}), 404

    except Exception as e:
        print(f"Error fetching passenger name: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()



@app.route("/bookings/active/<passenger_id>", methods=["GET"])
def get_active_bookings_for_employee(passenger_id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        cursor.execute("SELECT name FROM users WHERE id = %s", (passenger_id,))
        user = cursor.fetchone()
        
        if not user:
            return jsonify({"success": False, "message": "لم يتم العثور على راكب بهذا الرقم.", "bookings": []}), 404

        passenger_name = user['name']

        query = """
            SELECT *, id_ticket AS id_ticket 
            FROM tickets
            WHERE TRIM(LOWER(name)) = TRIM(LOWER(%s))
            AND paid = 1
            AND date_ticket_time > NOW()
            ORDER BY date_ticket_time ASC
        """
        
        cursor.execute(query, (passenger_name,))
        bookings = cursor.fetchall()
        
        for booking in bookings:
            if isinstance(booking.get('date_ticket_time'), datetime.datetime):
                booking['date_ticket_time'] = booking['date_ticket_time'].strftime("%Y-%m-%d %H:%M:%S")
            
            booking['vip'] = 1 if booking.get('vip') else 0
            
            for key in ['line', 'departure_station', 'arrival_station']:
                if booking.get(key) is not None:
                    booking[key] = str(booking[key]).strip()

        return jsonify({"success": True, "bookings": bookings})

    except Exception as e:
        print(f"Error fetching active bookings for employee: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route("/bookings/cancel/<booking_id>", methods=["POST"])
def cancel_booking(booking_id):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT paid FROM tickets WHERE id_ticket = %s AND paid = 1", (booking_id,))
        ticket = cursor.fetchone()

        if not ticket:
            return jsonify({"success": False, "message": "التذكرة غير موجودة أو تم إلغاؤها بالفعل"}), 404

        cursor.execute("UPDATE tickets SET paid = 0 WHERE id_ticket = %s", (booking_id,))
        conn.commit()
        
        if cursor.rowcount > 0:
            return jsonify({"success": True, "message": "تم إلغاء الحجز بنجاح"})
        else:
            return jsonify({"success": False, "message": "لم يتم العثور على الحجز لإلغائه"}), 404

    except Exception as e:
        print(f"Error cancelling booking: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()
        

@app.route("/booking/update/<booking_id>", methods=["POST"])
def update_booking(booking_id):
    data = request.get_json()
    
    line = data.get("line")
    departure_station = data.get("departure_station")
    arrival_station = data.get("arrival_station")
    time = data.get("time")
    new_seat_number = data.get("new_seat_number")
    
    if not all([line, departure_station, arrival_station, time, new_seat_number]):
        return jsonify({"success": False, "message": "البيانات ناقصة."}), 400

    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT seat_number, vip FROM tickets WHERE id_ticket = %s AND paid = 1", (booking_id,))
        original_ticket = cursor.fetchone()
        
        if not original_ticket:
            return jsonify({"success": False, "message": "التذكرة غير موجودة."}), 404

        original_seat = original_ticket[0]
        current_vip_value = original_ticket[1]
        
        if new_seat_number.strip() != original_seat.strip():
            cursor.execute("""
                SELECT COUNT(*) FROM tickets 
                WHERE date_ticket_time = %s 
                AND seat_number = %s 
                AND paid = 1
                AND vip = %s 
            """, (time, new_seat_number, current_vip_value))
            
            if cursor.fetchone()[0] > 0:
                return jsonify({"success": False, "message": f"المقعد {new_seat_number} محجوز بالفعل."}), 409
        
        cursor.execute("""
            UPDATE tickets 
            SET 
                line = %s,
                departure_station = %s,
                arrival_station = %s,
                date_ticket_time = %s,
                seat_number = %s 
            WHERE id_ticket = %s AND paid = 1
        """, (line, departure_station, arrival_station, time, new_seat_number, booking_id))
        
        conn.commit()
        return jsonify({"success": True, "message": "تم التحديث بنجاح."})

    except Exception as e:
        print(f"Update error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()
        

@app.route("/times", methods=["GET"])
def get_times():
    now = datetime.datetime.now()
    
    try:
        interval_minutes = int(request.args.get('interval_minutes', 5))
        if interval_minutes <= 0:
            interval_minutes = 5
    except ValueError:
        interval_minutes = 5

    show_all_day = request.args.get('all_day', 'false').lower() == 'true'
    
    start_of_day = datetime.datetime(now.year, now.month, now.day, 0, 0, 0)
    end_of_day = datetime.datetime(now.year, now.month, now.day, 23, 59, 0)
    
    current_time = start_of_day
    times = []

    while current_time <= end_of_day:
        times.append(current_time.strftime("%Y-%m-%d %H:%M:%S"))
        current_time += datetime.timedelta(minutes=interval_minutes)

    if show_all_day:
        return jsonify(times)

    valid_times = [
        t for t in times
        if datetime.datetime.strptime(t, "%Y-%m-%d %H:%M:%S") > now - datetime.timedelta(minutes=1)
    ]

    return jsonify(valid_times)


@app.route("/booked_seats", methods=["POST"])
def booked_seats():
    data = request.get_json()
    time_slot = data.get("time_slot")
    if not time_slot:
        return jsonify([]), 200

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT seat_number, vip FROM tickets WHERE date_ticket_time = %s AND paid = 1", (time_slot,))
        seats = cursor.fetchall()
        
        for seat in seats:
             seat['vip'] = 1 if seat.get('vip') else 0

        return jsonify(seats)
    except Exception as e:
        print(f"Error in booked_seats: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/booked_seats/status", methods=["POST"])
def booked_seats_status():
    data = request.get_json()
    time_slot = data.get("time_slot")
    line = data.get("line")
    departure_station = data.get("departure_station")
    arrival_station = data.get("arrival_station")
    
    seat_type = data.get("seat_type")

    excluded_ticket_id = request.args.get('exclude_ticket_id')

    if not all([time_slot, line, departure_station, arrival_station]):
        return jsonify({"success": False, "message": "يرجى اختيار جميع تفاصيل الرحلة"}), 400

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        # 🛑 تم توحيد الفئات: Single=0, Family=1, VIP=2
        type_mapping = {'SINGLE': 0, 'FAMILY': 1, 'VIP': 2}
        
        target_vip_value = type_mapping.get(seat_type.upper(), 0) if seat_type else 0
        
        print(f"DEBUG: Checking Status for: {seat_type} -> Looking for Value: {target_vip_value}")

        query = """
            SELECT seat_number
            FROM tickets
            WHERE date_ticket_time = %s
            AND TRIM(LOWER(line)) = TRIM(LOWER(%s))
            AND TRIM(LOWER(departure_station)) = TRIM(LOWER(%s))
            AND TRIM(LOWER(arrival_station)) = TRIM(LOWER(%s))
            AND paid = 1
            AND vip = %s  
        """
        
        params = [time_slot, line, departure_station, arrival_station, target_vip_value]
        
        if excluded_ticket_id:
            query += " AND id_ticket != %s"
            params.append(excluded_ticket_id)

        cursor.execute(query, tuple(params))
        
        booked_seats_list = [seat['seat_number'] for seat in cursor.fetchall()]

        return jsonify({"success": True, "booked_seats": booked_seats_list})
    
    except Exception as e:
        print(f"Error in booked_seats_status: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/book", methods=["POST"])
def book():
    data = request.get_json()

    name = data.get("name")
    time = data.get("time")
    seat_number = data.get("seat_number")
    seat_type = data.get("seat_type")
    
    line = data.get("line")
    departure_station = data.get("departure_station")
    arrival_station = data.get("arrival_station")

    if not all([name, time, seat_number, seat_type, line, departure_station, arrival_station]):
        return jsonify({"success": False, "message": "بيانات الحجز ناقصة"}), 400

    conn = get_connection()
    cursor = conn.cursor()
    try:
        # 🛑 توحيد الفئات: Single=0, Family=1, VIP=2
        type_mapping = {'SINGLE': 0, 'FAMILY': 1, 'VIP': 2}
        
        vip_value = type_mapping.get(seat_type.upper(), 0)
        
        print(f"DEBUG: Booking Seat Type: {seat_type} -> Saved Value: {vip_value}")

        cursor.execute("""
            INSERT INTO tickets (
                name, date_ticket_time, date_ticket_find, 
                seat_number, vip, paid, 
                line, departure_station, arrival_station
            )
            VALUES (%s, %s, NOW(), %s, %s, 1, %s, %s, %s)
        """, (
            name,
            time,
            seat_number,
            vip_value,
            line,
            departure_station,
            arrival_station
        ))
        
        conn.commit()
        ticket_id = cursor.lastrowid
        return jsonify({"success": True, "ticket_id": ticket_id})
    except Exception as e:
        print("Book error:", e)
        if '1062' in str(e):
            return jsonify({"success": False, "message": "هذا المقعد محجوز مسبقًا."}), 409
        return jsonify({"success": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/pay", methods=["POST"])
def pay():
    data = request.get_json()
    ticket_id = data.get("ticket_id")
    
    if not ticket_id:
        return jsonify({"success": False, "message": "Missing ticket_id"}), 400

    return jsonify({"success": True, "message": "تم الدفع (افتراضياً عند الحجز)"})



@app.route("/active_bookings", methods=["GET"])
def get_active_bookings():
    passenger_name = request.args.get('passenger_name')
    if not passenger_name:
        return jsonify({"success": False, "message": "Passenger name not provided"}), 400

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        query = """
            SELECT *, id_ticket AS ticketId FROM tickets
            WHERE TRIM(LOWER(name)) = TRIM(LOWER(%s))
            AND paid = 1
            AND date_ticket_time > NOW()
            ORDER BY date_ticket_time ASC
        """
        cursor.execute(query, (passenger_name,))
        bookings = cursor.fetchall()

        for booking in bookings:
            if isinstance(booking.get('date_ticket_time'), datetime.datetime):
                booking['date_ticket_time'] = booking['date_ticket_time'].strftime("%Y-%m-%d %H:%M:%S")
            if isinstance(booking.get('date_ticket_find'), datetime.datetime):
                booking['date_ticket_find'] = booking['date_ticket_find'].strftime("%Y-%m-%d %H:%M:%S")
            
            booking['vip'] = 1 if booking.get('vip') else 0
            booking['line'] = str(booking['line']).strip()
            booking['departure_station'] = str(booking['departure_station']).strip()
            booking['arrival_station'] = str(booking['arrival_station']).strip()


        return jsonify(bookings)
    except Exception as e:
        print("Active bookings error:", e)
        return jsonify({"success": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/completed_bookings", methods=["GET"])
def get_completed_bookings():
    passenger_name = request.args.get('passenger_name')
    if not passenger_name:
        return jsonify({"success": False, "message": "Passenger name not provided"}), 400

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        query = """
            SELECT *, id_ticket AS ticketId FROM tickets
            WHERE TRIM(LOWER(name)) = TRIM(LOWER(%s))
            AND (paid = 0 OR date_ticket_time <= NOW())
            ORDER BY date_ticket_time DESC
        """
        cursor.execute(query, (passenger_name,))
        bookings = cursor.fetchall()

        for booking in bookings:
            if isinstance(booking.get('date_ticket_time'), datetime.datetime):
                booking['date_ticket_time'] = booking['date_ticket_time'].strftime("%Y-%m-%d %H:%M:%S")
            if isinstance(booking.get('date_ticket_find'), datetime.datetime):
                booking['date_ticket_find'] = booking['date_ticket_find'].strftime("%Y-%m-%d %H:%M:%S")

            booking['vip'] = 1 if booking.get('vip') else 0
            booking['line'] = str(booking['line']).strip()
            booking['departure_station'] = str(booking['departure_station']).strip()
            booking['arrival_station'] = str(booking['arrival_station']).strip()

        return jsonify(bookings)
    except Exception as e:
        print("Completed bookings error:", e)
        return jsonify({"success": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/verify_ticket", methods=["POST"])
def verify_ticket():
    data = request.get_json()
    ticket_id = data.get("ticket_id")

    if not ticket_id:
        return jsonify({"valid": False, "message": "لم يتم إرسال رقم التذكرة"}), 400

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM tickets WHERE id_ticket = %s", (ticket_id,))
        ticket = cursor.fetchone()

        if not ticket:
            return jsonify({"valid": False, "message": "التذكرة غير موجودة"}), 404

        if ticket["paid"] != 1:
            return jsonify({"valid": False, "message": "التذكرة غير مدفوعة (ملغاة أو لم تكتمل)"}), 400

        now = datetime.datetime.now()
        booking_time = ticket["date_ticket_time"]

        one_hour = datetime.timedelta(hours=1)
        valid_start = booking_time - one_hour
        valid_end = booking_time + one_hour

        if now >= valid_start and now <= valid_end:
            return jsonify({
                "valid": True,
                "message": "التذكرة صالحة ومطابقة للوقت",
                "details": {
                    "name": ticket['name'],
                    "seat": ticket['seat_number'],
                    "time": booking_time.strftime("%Y-%m-%d %H:%M:%S")
                }
            }), 200

        elif now > valid_end:
            return jsonify({"valid": False, "message": "التذكرة منتهية الصلاحية (تجاوزت وقت الحجز بساعة)"}), 400

        elif now < valid_start:
            return jsonify({"valid": False, "message": "التذكرة سابقة لأوانها (قبل ساعة من موعدها)"}), 400

        else:
            return jsonify({"valid": False, "message": "خطأ غير متوقع في التحقق من الصلاحية"}), 500

    except Exception as e:
        print("Verify ticket error:", e)
        return jsonify({"valid": False, "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    if check_db_connection():
        app.run(host="0.0.0.0", port=5000, debug=True)
    else:
        print("="*50)
        print("❌ لم يتم تشغيل الخادم بسبب فشل الاتصال بقاعدة البيانات.")
        print("يرجى مراجعة إعدادات الاتصال في 'db_config.py'.")
        print("="*50)
