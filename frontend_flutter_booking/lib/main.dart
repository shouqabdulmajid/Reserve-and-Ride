// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'package:flutter_localizations/flutter_localizations.dart';

const String backendUrl = "http://192.168.100.9:5000";

void main() {
  Intl.defaultLocale = 'ar_SA';
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tashilat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Tajawal',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            textStyle: const TextStyle(
                fontSize: 16,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.indigo, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          labelStyle: TextStyle(color: Colors.indigo[700]),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.indigo.shade700,
            textStyle: const TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.w600),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ar', 'SA'),
      home: RoleSelectionPage(),
    );
  }
}

class RoleSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسهيلات - اختيار الدور")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "من فضلك، اختر دورك:",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 250,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                icon: const Icon(Icons.person, size: 30),
                label: const Text("راكب", style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EmployeeLoginPage()),
                  );
                },
                icon: const Icon(Icons.work, size: 30),
                label: const Text("موظف", style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeeLoginPage extends StatelessWidget {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> _isLoggingInNotifier = ValueNotifier(false);

  void employeeLogin(BuildContext context) async {
    if (_isLoggingInNotifier.value) return;
    _isLoggingInNotifier.value = true;
    FocusScope.of(context).unfocus();
    try {
      final res = await http
          .post(
            Uri.parse("$backendUrl/employee_login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": usernameController.text,
              "password": passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(res.body);

      if (res.statusCode == 200 && body["success"] == true) {
        final employeeName = body["employee"]["name"] ?? "موظف";
        final employeeId = body["employee"]["employee_id"] ?? "غير معروف";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("أهلاً بك يا $employeeName (ID: $employeeId)!"),
              backgroundColor: Colors.green),
        );
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeHomePage(name: employeeName),
            ),
          );
        }
      } else {
        final message = body["message"] ?? "فشل تسجيل دخول الموظف";
        _showErrorDialog(context, "خطأ في الدخول", message);
      }
    } catch (e) {
      _showErrorDialog(context, "خطأ في الاتصال",
          "حدث خطأ أثناء الاتصال بالخادم. يرجى التحقق من اتصالك بالشبكة والمحاولة مرة أخرى.");
      print("Employee Login Error: $e");
    } finally {
      _isLoggingInNotifier.value = false;
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, textDirection: ui.TextDirection.rtl),
        content: Text(message, textDirection: ui.TextDirection.rtl),
        actions: <Widget>[
          TextButton(
            child: const Text('حسناً'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("تسجيل دخول الموظف")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                    labelText: "اسم المستخدم أو الرقم الوظيفي"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                decoration:
                    const InputDecoration(labelText: "كلمة المرور للموظف"),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              ValueListenableBuilder<bool>(
                  valueListenable: _isLoggingInNotifier,
                  builder: (context, isLoggingIn, child) {
                    return ElevatedButton(
                      onPressed:
                          isLoggingIn ? null : () => employeeLogin(context),
                      child: isLoggingIn
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)))
                          : const Text("تسجيل الدخول"),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                    );
                  }),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EmployeeRegisterPage()),
                ),
                child: const Text("إنشاء حساب موظف"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("العودة لاختيار الدور"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmployeeRegisterPage extends StatelessWidget {
  final employeeIdController = TextEditingController();
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final ValueNotifier<bool> _isRegisteringNotifier = ValueNotifier(false);

  void employeeRegister(BuildContext context) async {
    if (_isRegisteringNotifier.value) return;
    _isRegisteringNotifier.value = true;
    FocusScope.of(context).unfocus();

    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

    if (!emailRegex.hasMatch(emailController.text)) {
      _showError(context, "الرجاء إدخال بريد إلكتروني صحيح");
      _isRegisteringNotifier.value = false;
      return;
    }

    final phoneText = phoneController.text;
    if (phoneText.length != 9 || !phoneText.startsWith('5')) {
      _showError(context,
          "الرجاء إدخال رقم هاتف صحيح (يجب أن يبدأ بـ 5 ويكون مكوناً من 9 أرقام)");
      _isRegisteringNotifier.value = false;
      return;
    }

    if (employeeIdController.text.isEmpty ||
        nameController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        phoneController.text.isEmpty ||
        emailController.text.isEmpty) {
      _showError(context, "الرجاء ملء جميع الحقول المطلوبة");
      _isRegisteringNotifier.value = false;
      return;
    }

    try {
      final res = await http
          .post(
            Uri.parse("$backendUrl/employee_register"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "employee_id": employeeIdController.text,
              "name": nameController.text,
              "username": usernameController.text,
              "password": passwordController.text,
              "email": emailController.text,
              "phone": phoneController.text,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(res.body);

      if (res.statusCode == 200 && body["success"] == true) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("تم إنشاء حساب الموظف بنجاح"),
                backgroundColor: Colors.green),
          );
        }
      } else {
        final message = body["message"] ?? "فشل تسجيل حساب الموظف";
        _showError(context, message);
      }
    } catch (e) {
      _showError(context, "خطأ في الاتصال بالخادم: ${e.toString()}");
    } finally {
      _isRegisteringNotifier.value = false;
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("إنشاء حساب موظف")),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: employeeIdController,
              keyboardType: TextInputType.number, // أصبح رقمي
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: "الرقم الوظيفي (Employee ID)"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "الاسم بالكامل"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: usernameController,
              decoration:
                  const InputDecoration(labelText: "اسم المستخدم (Username)"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "كلمة المرور"),
              obscureText: true,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "البريد الإلكتروني"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9)
              ],
              decoration: const InputDecoration(
                labelText: "رقم الجوال",
                prefixText: "+966 ",
                hintText: "5xxxxxxxx",
              ),
            ),
            const SizedBox(height: 30),
            ValueListenableBuilder<bool>(
                valueListenable: _isRegisteringNotifier,
                builder: (context, isRegistering, child) {
                  return ElevatedButton(
                    onPressed:
                        isRegistering ? null : () => employeeRegister(context),
                    child: isRegistering
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)))
                        : const Text("تسجيل حساب الموظف"),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                  );
                }),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("العودة لاختيار الدور"),
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeeHomePage extends StatelessWidget {
  final String name;
  const EmployeeHomePage({required this.name, super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("لوحة تحكم الموظف")),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "مرحباً أيها الموظف $name!",
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SeatStatusPage()),
                    );
                  },
                  icon: const Icon(Icons.search),
                  label: const Text("رؤية حالة المقاعد"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CancelBookingPage(employeeName: name)),
                    );
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text("إلغاء حجز لراكب"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              EditBookingSearchPage(employeeName: name)),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("التعديل على الحجز"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PassengerIdInputPage(name: name)),
                    );
                  },
                  icon: const Icon(Icons.add_box),
                  label: const Text("حجز جديد لراكب"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("تسجيل الخروج"),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoleSelectionPage(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PassengerIdInputPage extends StatefulWidget {
  final String name;

  const PassengerIdInputPage({required this.name, super.key});

  @override
  State<PassengerIdInputPage> createState() => _PassengerIdInputPageState();
}

class _PassengerIdInputPageState extends State<PassengerIdInputPage> {
  final TextEditingController _idController = TextEditingController();
  bool _isLoading = false;

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  Future<void> fetchPassengerName(String passengerId) async {
    final trimmedId = passengerId.trim();
    if (trimmedId.isEmpty) {
      _showMessage("الرجاء إدخال رقم هوية الراكب", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http
          .get(
            Uri.parse("$backendUrl/passenger/name_by_id/$trimmedId"),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        final passengerName = body["name"] as String? ?? "راكب غير مسمى";

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  BookingPage(name: passengerName, employeeName: widget.name),
            ),
          );
        }
      } else {
        final message = body["message"] ??
            "لم يتم العثور على راكب بهذه الهوية أو بياناته ناقصة.";
        _showMessage(message, Colors.redAccent);
      }
    } catch (e) {
      _showMessage("خطأ في الاتصال بالخادم: $e", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("حجز جديد - إدخال الهوية")),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "أهلاً بك أيها الموظف ${widget.name}، يرجى إدخال هوية الراكب لإجراء الحجز:",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _idController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: "رقم هوية الراكب (10 أرقام)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => fetchPassengerName(_idController.text.trim()),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.arrow_forward),
                label: Text(_isLoading
                    ? "جاري التحقق والمتابعة..."
                    : "المتابعة لصفحة الحجز"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء والعودة"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CancelBookingPage extends StatefulWidget {
  final String employeeName;
  const CancelBookingPage({required this.employeeName, super.key});

  @override
  State<CancelBookingPage> createState() => _CancelBookingPageState();
}

class _CancelBookingPageState extends State<CancelBookingPage> {
  final TextEditingController _idController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _bookings = [];
  String? _selectedBookingId;

  String _formatBookingDisplay(Map<String, dynamic> booking) {
    String formattedTime = booking['date_ticket_time'] ?? 'وقت غير متوفر';
    try {
      formattedTime = DateFormat('yyyy/MM/dd - hh:mm a', 'ar_SA')
          .format(DateTime.parse(formattedTime));
    } catch (e) {
      print("Error formatting date for cancel list: $e");
    }

    final seatType = (booking['vip'] == 1) ? 'أولوية' : 'عادي/عائلي';
    return "T#${booking['id_ticket']} | ${booking['departure_station']} إلى ${booking['arrival_station']} | مقعد: ${booking['seat_number']} ($seatType)\nالوقت: $formattedTime";
  }

  Future<void> fetchBookings() async {
    final passengerId = _idController.text.trim();
    if (passengerId.isEmpty) {
      _showMessage("الرجاء إدخال رقم هوية الراكب", Colors.redAccent);
      return;
    }

    setState(() {
      _isLoading = true;
      _bookings = [];
      _selectedBookingId = null;
    });

    try {
      final response = await http.get(
        Uri.parse("$backendUrl/bookings/active/$passengerId"),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        setState(() {
          _bookings = body["bookings"] ?? [];
        });
        if (_bookings.isEmpty) {
          _showMessage("لا توجد حجوزات فعالة لهذا الراكب", Colors.orange);
        }
      } else {
        final message = body["message"] ?? "فشل في جلب بيانات الحجوزات";
        _showMessage(message, Colors.redAccent);
      }
    } catch (e) {
      _showMessage("خطأ في الاتصال بالخادم: $e", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> cancelBooking() async {
    if (_selectedBookingId == null) {
      _showMessage("الرجاء اختيار الحجز الذي تريد إلغاءه", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$backendUrl/bookings/cancel/$_selectedBookingId"),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    CancelSuccessPage(employeeName: widget.employeeName)),
          );
        }
      } else {
        final message = body["message"] ?? "فشل إلغاء الحجز";
        _showMessage(message, Colors.redAccent);
      }
    } catch (e) {
      _showMessage("خطأ في الاتصال بالخادم: $e", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("إلغاء حجز راكب")),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _idController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "رقم هوية الراكب",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : fetchBookings,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("عرض الحجوزات الفعالة"),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _bookings.isEmpty
                    ? const Center(child: Text("لا توجد حجوزات حالياً"))
                    : ListView.builder(
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          final id = booking["id_ticket"]; // استخدام ID التذكرة

                          return RadioListTile<String>(
                            title: Text(_formatBookingDisplay(booking),
                                style: const TextStyle(fontSize: 14)),
                            value: id.toString(),
                            groupValue: _selectedBookingId,
                            onChanged: (val) {
                              setState(() {
                                _selectedBookingId = val;
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _isLoading || _selectedBookingId == null
                    ? null
                    : cancelBooking,
                icon: const Icon(Icons.cancel),
                label: const Text("إلغاء الحجز"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CancelSuccessPage extends StatelessWidget {
  final String employeeName;
  const CancelSuccessPage({required this.employeeName, super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("تم الإلغاء")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              const Text(
                "تم إلغاء حجز الراكب بنجاح ✅",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EmployeeHomePage(name: employeeName)),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text("العودة إلى لوحة تحكم الموظف"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> _isLoggingInNotifier = ValueNotifier(false);

  void login(BuildContext context) async {
    if (_isLoggingInNotifier.value) return;
    _isLoggingInNotifier.value = true;
    FocusScope.of(context).unfocus();

    try {
      final res = await http
          .post(
            Uri.parse("$backendUrl/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": usernameController.text,
              "password": passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(res.body);

      if (res.statusCode == 200 && body["success"] == true) {
        final user = body["user"];
        final userName = user != null && user["full_name"] != null
            ? user["full_name"] as String
            : (user != null && user["username"] != null
                ? user["username"] as String
                : "مستخدم بدون اسم");

        print("Login successful, user name is: $userName");

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(name: userName),
            ),
          );
        }
      } else {
        final message = body["message"] ?? "فشل تسجيل الدخول";
        _showError(context, message);
      }
    } catch (e) {
      _showError(context, "خطأ في الاتصال بالخادم: ${e.toString()}");
    } finally {
      _isLoggingInNotifier.value = false;
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("تسجيل الدخول (راكب)")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "اسم المستخدم"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "كلمة المرور"),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              ValueListenableBuilder<bool>(
                valueListenable: _isLoggingInNotifier,
                builder: (context, isLoggingIn, child) {
                  return ElevatedButton(
                    onPressed: isLoggingIn ? null : () => login(context),
                    child: isLoggingIn
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("تسجيل الدخول"),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                  );
                },
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterPage()),
                ),
                child: const Text("إنشاء حساب"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("العودة لاختيار الدور"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Map<String, TextEditingController> fields = {
    "id": TextEditingController(),
    "name": TextEditingController(),
    "address": TextEditingController(),
    "username": TextEditingController(),
    "password": TextEditingController(),
    "email": TextEditingController(),
    "phone": TextEditingController(),
  };

  DateTime? _selectedDate;
  final List<String> saudiCities = [
    'الرياض',
    'جدة',
    'مكة',
    'المدينة المنورة',
    'الدمام',
    'الخبر',
    'الظهران',
    'القطيف',
    'الأحساء',
    'الطائف',
    'تبوك',
    'بريدة',
    'الجبيل',
    'حائل',
    'عرعر',
    'خميس مشيط',
    'أبها',
    'نجران',
    'جازان',
    'الباحة',
    'القريات',
    'سكاكا',
    'ينبع',
    'القصيم'
  ];

  String? _selectedCity;

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final ValueNotifier<bool> _isRegisteringNotifier = ValueNotifier(false);

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'SA'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void register(BuildContext context) async {
    if (_isRegisteringNotifier.value) return;
    _isRegisteringNotifier.value = true;
    FocusScope.of(context).unfocus();

    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(fields["email"]!.text)) {
      _showError("الرجاء إدخال بريد إلكتروني صحيح");
      _isRegisteringNotifier.value = false;
      return;
    }

    final phoneText = fields["phone"]!.text;
    if (phoneText.length != 9 || !phoneText.startsWith('5')) {
      _showError(
          "الرجاء إدخال رقم هاتف صحيح (يجب أن يبدأ بـ 5 ويكون مكوناً من 9 أرقام)");
      _isRegisteringNotifier.value = false;
      return;
    }

    if (_selectedCity == null) {
      _showError("الرجاء اختيار مدينة الإقامة");
      _isRegisteringNotifier.value = false;
      return;
    }

    if (_selectedImage == null) {
      _showError("الرجاء اختيار صورة البطاقة");
      _isRegisteringNotifier.value = false;
      return;
    }

    if (_selectedDate == null) {
      _showError("الرجاء اختيار تاريخ الميلاد");
      _isRegisteringNotifier.value = false;
      return;
    }

    bool anyFieldEmpty = false;
    fields.forEach((key, controller) {
      if (controller.text.isEmpty) {
        anyFieldEmpty = true;
      }
    });
    if (anyFieldEmpty) {
      _showError("الرجاء ملء جميع الحقول المطلوبة");
      _isRegisteringNotifier.value = false;
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$backendUrl/register"),
    );

    for (var entry in fields.entries) {
      request.fields[entry.key] = entry.value.text;
    }

    request.fields["birth_date"] =
        DateFormat('yyyy-MM-dd', 'en').format(_selectedDate!);

    request.fields["resettle"] = _selectedCity!;

    request.files.add(
      await http.MultipartFile.fromPath(
        'priority_card',
        _selectedImage!.path,
      ),
    );

    try {
      final response = await request
          .send()
          .timeout(const Duration(seconds: 30)); // مهلة 30 ثانية
      final responseBody = await response.stream.bytesToString();
      final body = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("تم إنشاء الحساب"),
                backgroundColor: Colors.green),
          );
        }
      } else {
        final message = body["message"] ?? "فشل التسجيل";
        _showError(message);
      }
    } catch (e) {
      _showError("خطأ في الاتصال بالخادم: ${e.toString()}");
    } finally {
      _isRegisteringNotifier.value = false;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("تسجيل حساب (راكب)")),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: fields["id"],
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                decoration:
                    const InputDecoration(labelText: "رقم الهوية / الإقامة"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: fields["name"],
                decoration: const InputDecoration(labelText: "الاسم بالكامل"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'تاريخ الميلاد',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 2),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        _selectedDate == null
                            ? 'اختر تاريخ الميلاد'
                            : DateFormat.yMMMd('ar_SA').format(_selectedDate!),
                        style: TextStyle(
                          fontSize: 16.0,
                          color: _selectedDate == null
                              ? Colors.grey[700]
                              : Colors.black,
                        ),
                      ),
                      Icon(Icons.calendar_today,
                          color: Theme.of(context).primaryColor),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "مدينة الإقامة"),
                value: _selectedCity,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCity = newValue;
                  });
                },
                items:
                    saudiCities.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down,
                    color: Theme.of(context).primaryColor),
                style: const TextStyle(
                    fontSize: 16.0, color: Colors.black, fontFamily: 'Tajawal'),
                dropdownColor: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: fields["address"],
                decoration: const InputDecoration(labelText: "العنوان"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: fields["username"],
                decoration: const InputDecoration(labelText: "اسم المستخدم"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: fields["password"],
                decoration: const InputDecoration(labelText: "كلمة المرور"),
                obscureText: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: fields["email"],
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: "البريد الإلكتروني"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: fields["phone"],
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9)
                ],
                decoration: const InputDecoration(
                  labelText: "رقم الجوال",
                  prefixText: "+966",
                  hintText: "5xxxxxxxx",
                ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                const Text(
                  "إرفاق صورة بطاقة الأولوية",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 5),
                              Text("اضغط هنا لرفع صورة البطاقة"),
                            ],
                          )
                        : Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const SizedBox(height: 20),
            ValueListenableBuilder<bool>(
                valueListenable: _isRegisteringNotifier,
                builder: (context, isRegistering, child) {
                  return ElevatedButton(
                    onPressed: isRegistering ? null : () => register(context),
                    child: isRegistering
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("تسجيل"),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                  );
                }),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final String name;
  HomePage({required this.name});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("الصفحة الرئيسية (راكب)")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("مرحباً بك يا $name!", style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPagePassenger(name: name),
                  ),
                ),
                child: const Text("احجز الآن"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ActiveBookingsPage(passengerName: name)),
                ),
                child: const Text("الحجوزات الفعالة"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CompletedBookingsPage(passengerName: name)),
                ),
                child: const Text("الحجوزات المنتهية"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RoleSelectionPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text("تسجيل الخروج"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingPagePassenger extends StatefulWidget {
  final String name;

  BookingPagePassenger({required this.name});

  @override
  _BookingPagePassengerState createState() => _BookingPagePassengerState();
}

class _BookingPagePassengerState extends State<BookingPagePassenger> {
  final List<String> metroLines = [
    'المسار الأزرق',
    'المسار الأحمر',
    'المسار البرتقالي',
    'المسار الأصفر',
    'المسار الأخضر',
    'المسار البنفسجي',
  ];

  final Map<String, List<String>> metroStations = {
    'المسار الأزرق': [
      'SABB',
      'Dr Sulaiman Al-Habib',
      'Al-Shabab Club Stadium',
      'KAFD',
      'Al-Murooj',
      'King Fahad District',
      'King Fahad District 2',
      'STC',
      'Al-Wurud 2',
      'Al-Urubah',
      'Bank Albilad',
      'King Fahad Library',
      'Ministry of Interior',
      'Al-Murabba',
      'Passport Department',
      'National Museum',
      'Al-Bat’ha',
      'Qasr Al-Hokm',
      'Al-Owd',
      'Skirinah',
      'Manfouhah',
      'Al-Iman Hospital',
      'Transportation Center',
      'Al-Aziziah',
      'Ad Dar Al-Baida',
    ],
    'المسار الأحمر': [
      'King Saud University Station',
      'King Salman Oasis',
      'KACST',
      'At Takhassusi',
      'STC',
      'Al-Wurud',
      'King Abdulaziz Road',
      'Ministry of Education',
      'An Nuzhah',
      'Riyadh Exhibition Center',
      'Khalid Bin Alwaleed Road',
      'Al-Hamra',
      'Al-Khaleej',
      'City Centre Ishbiliyah',
      'King Fahd Sports City Station',
    ],
    'المسار البرتقالي': [
      'Jeddah Road',
      'Tuwaiq',
      'Ad Douh',
      'Western Station',
      'Aishah bint Abi Bakr Street',
      'Dhahrat Al-Badiah',
      'Sultanah',
      'Al-Jarradiyah',
      'Courts Complex',
      'Qasr Al-Hokm',
      'Al-Hilla',
      'Al-Margab',
      'As Salhiyah',
      'First Industrial City',
      'Railway Station',
      'Al-Malaz',
      'Jarir District',
      'Al-Rajhi Grand Mosque',
      'Harun Ar Rashid Road',
      'An Naseem',
      'Khashm Al-An',
    ],
    'المسار الأصفر': [
      'Airport T1-2',
      'Airport T3',
      'Airport T4',
      'Airport T5',
      'KAFD'
    ],
    'المسار الأخضر': ['Ministry of Education', 'National Museum'],
    'المسار البنفسجي': ['KAFD', 'An Naseem'],
  };

  final List<String> seatCategories = ['Single', 'Family', 'VIP'];

  String? selectedLine;
  String? selectedDepartureStation;
  String? selectedArrivalStation;
  List<String> timeSlots = [];
  String? selectedTime;
  String? selectedCategory;
  String? selectedSeat;
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _seatsStatus = {
    'S1': {'isBooked': false, 'type': 'Single'},
    'S2': {'isBooked': false, 'type': 'Single'},
    'S3': {'isBooked': false, 'type': 'Single'},
    'S4': {'isBooked': false, 'type': 'Single'},
    'S5': {'isBooked': false, 'type': 'Single'},
    'S6': {'isBooked': false, 'type': 'Single'},
    'S7': {'isBooked': false, 'type': 'Single'},
    'S8': {'isBooked': false, 'type': 'Single'},
    'S9': {'isBooked': false, 'type': 'Single'},
    'S10': {'isBooked': false, 'type': 'Single'},
    'S11': {'isBooked': false, 'type': 'Single'},
    'S12': {'isBooked': false, 'type': 'Single'},
    'S13': {'isBooked': false, 'type': 'Single'},
    'S14': {'isBooked': false, 'type': 'Single'},
    'S15': {'isBooked': false, 'type': 'Single'},
    'S16': {'isBooked': false, 'type': 'Single'},
    'S17': {'isBooked': false, 'type': 'Single'},
    'S18': {'isBooked': false, 'type': 'Single'},
    'S19': {'isBooked': false, 'type': 'Single'},
    'S20': {'isBooked': false, 'type': 'Single'},
    'S21': {'isBooked': false, 'type': 'Single'},
    'S22': {'isBooked': false, 'type': 'Single'},
    'S23': {'isBooked': false, 'type': 'Single'},
    'S24': {'isBooked': false, 'type': 'Single'},
    'S25': {'isBooked': false, 'type': 'Single'},
    'S26': {'isBooked': false, 'type': 'Single'},
    'S27': {'isBooked': false, 'type': 'Single'},
    'S28': {'isBooked': false, 'type': 'Single'},
    'S29': {'isBooked': false, 'type': 'Single'},
    'S30': {'isBooked': false, 'type': 'Single'},
    'S31': {'isBooked': false, 'type': 'Single'},
    'S32': {'isBooked': false, 'type': 'Single'},
  };

  final ValueNotifier<bool> _isBookingNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    selectedCategory = seatCategories.first;
    loadTimeSlots();
  }

  List<DropdownMenuItem<String>> _buildStationItems(String? line) {
    if (line == null || !metroStations.containsKey(line)) return [];
    final double widthAvailable = (MediaQuery.of(context).size.width / 2) - 50;
    return (metroStations[line] ?? [])
        .map((station) => DropdownMenuItem(
              value: station,
              child: SizedBox(
                width: widthAvailable,
                child: Text(station,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13)),
              ),
            ))
        .toList();
  }

  void loadTimeSlots() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await http
          .get(Uri.parse("$backendUrl/times?interval_minutes=5"))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        List<String> fetchedTimes = List<String>.from(jsonDecode(res.body));
        final now = DateTime.now();
        fetchedTimes = fetchedTimes.where((timeString) {
          try {
            final slotTime = DateTime.parse(timeString);
            bool isFuture = slotTime.isAfter(now);
            bool isOperatingHours = slotTime.hour >= 5;
            return isFuture && isOperatingHours;
          } catch (e) {
            return false;
          }
        }).toList();
        setState(() {
          timeSlots = fetchedTimes;
          selectedTime = timeSlots.isNotEmpty ? timeSlots.first : null;
        });
        if (selectedTime != null) {
          await fetchSeatStatus(selectedTime!);
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _showMessage("فشل في جلب الأوقات المتاحة", isError: true);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError("خطأ في الاتصال: ${e.toString()}");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchSeatStatus(String time) async {
    if (selectedLine == null ||
        selectedDepartureStation == null ||
        selectedArrivalStation == null) return;

    setState(() {
      _isLoading = true;
      _seatsStatus.forEach((key, value) {
        value['isBooked'] = false;
      });
      selectedSeat = null;
    });

    try {
      final res = await http
          .post(
            Uri.parse("$backendUrl/booked_seats/status"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "line": selectedLine,
              "departure_station": selectedDepartureStation,
              "arrival_station": selectedArrivalStation,
              "time_slot": time,
              "seat_type": selectedCategory,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final List<dynamic> bookedSeats =
            jsonDecode(res.body)['booked_seats'] ?? [];
        setState(() {
          for (var seatNumber in bookedSeats) {
            if (_seatsStatus.containsKey(seatNumber)) {
              _seatsStatus[seatNumber]!['isBooked'] = true;
            }
          }
          _isLoading = false;
        });
      } else {
        _showMessage("فشل في جلب حالة المقاعد", isError: true);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError("خطأ: ${e.toString()}");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void bookTicket() async {
    if (_isBookingNotifier.value) return;
    _isBookingNotifier.value = true;
    FocusScope.of(context).unfocus();

    if (selectedSeat == null ||
        selectedTime == null ||
        selectedLine == null ||
        selectedDepartureStation == null ||
        selectedArrivalStation == null) {
      _showError("الرجاء اختيار جميع تفاصيل الحجز.");
      _isBookingNotifier.value = false;
      return;
    }
    if (selectedDepartureStation == selectedArrivalStation) {
      _showError("المحطات يجب أن تكون مختلفة.");
      _isBookingNotifier.value = false;
      return;
    }

    try {
      final isVip = selectedCategory == 'VIP';
      final res = await http
          .post(
            Uri.parse("$backendUrl/book"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": widget.name,
              "time": selectedTime,
              "seat_number": selectedSeat,
              "seat_type": selectedCategory,
              "vip": isVip,
              "line": selectedLine,
              "departure_station": selectedDepartureStation,
              "arrival_station": selectedArrivalStation,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(res.body);

      if (res.statusCode == 200 && body["success"] == true) {
        final ticketId = body["ticket_id"];
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TicketQrPagePassenger(
                ticketId: ticketId.toString(),
                userName: widget.name,
                bookingTime: selectedTime!,
                seatType: selectedCategory!,
                line: selectedLine!,
                departure: selectedDepartureStation!,
                arrival: selectedArrivalStation!,
                seatNumber: selectedSeat!,
              ),
            ),
          );
        }
      } else {
        _showError(body["message"] ?? "فشل الحجز.");
        if (selectedTime != null) fetchSeatStatus(selectedTime!);
      }
    } catch (e) {
      _showError("خطأ: ${e.toString()}");
    } finally {
      _isBookingNotifier.value = false;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, textDirection: ui.TextDirection.rtl),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Widget buildSeat(MapEntry<String, Map<String, dynamic>> entry) {
    final seatNumber = entry.key;
    final isBooked = entry.value['isBooked'] as bool;
    final isSelected = selectedSeat == seatNumber;
    final Color svgColor = isBooked ? Colors.red.shade700 : Colors.green;
    return InkWell(
      onTap: isBooked
          ? null
          : () {
              setState(() {
                selectedSeat = isSelected ? null : seatNumber;
              });
            },
      child: SizedBox(
        width: 60,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Colors.green.shade500, width: 3)
                : Border.all(color: Colors.transparent, width: 3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(seatNumber,
                  style: TextStyle(
                      color: svgColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 2),
              SvgPicture.asset('assets/seat_icon.svg',
                  width: 36,
                  height: 36,
                  colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildSeatRows() {
    final allSeats = _seatsStatus.entries.toList();
    List<Widget> rows = [];
    const List<List<String?>> finalLayout = [
      ['S1', null, null, 'S17'],
      ['S2', null, null, 'S18'],
      [null, null, 'Divider', null, null],
      ['S3', null, 'S19', 'S20'],
      ['S5', null, 'S21', 'S22'],
      ['S7', null, 'S23', 'S24'],
      ['S9', null, 'S25', 'S26'],
      [null, null, 'Divider', null, null],
      ['S11', null, 'S27', 'S28'],
      ['S13', null, 'S29', 'S30'],
      ['S15', null, 'S31', 'S32'],
      ['S4', null, 'S6', 'S8'],
      [null, null, 'Divider', null, null],
      ['S20', null, null, 'S24'],
      ['S22', null, null, 'S26'],
    ];
    Map<String, MapEntry<String, Map<String, dynamic>>> seatMap = {
      for (var entry in allSeats) entry.key: entry
    };

    for (var rowDefinition in finalLayout) {
      if (rowDefinition.length == 5 && rowDefinition[2] == 'Divider') {
        rows.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0),
            child: Divider(thickness: 2, color: Colors.grey)));
        continue;
      }
      List<Widget> seatsInRow = [];
      for (int i = 0; i < rowDefinition.length; i++) {
        final seatKey = rowDefinition[i];
        if (seatKey == null) {
          seatsInRow.add(SizedBox(width: i == 2 ? 40.0 : 10.0));
          continue;
        }
        final seatKeys = seatKey.split(',');
        if (seatKeys.length > 1) {
          seatsInRow.add(Row(
              mainAxisSize: MainAxisSize.min,
              children: seatKeys.map((id) {
                final entry = seatMap[id.trim()] ??
                    allSeats.firstWhere((e) => e.key == id.trim(),
                        orElse: () => MapEntry(
                            id.trim(), {'isBooked': true, 'type': 'Single'}));
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: buildSeat(entry));
              }).toList()));
        } else {
          final entry = seatMap[seatKey.trim()] ??
              allSeats.firstWhere((e) => e.key == seatKey.trim(),
                  orElse: () => MapEntry(
                      seatKey.trim(), {'isBooked': true, 'type': 'Single'}));
          seatsInRow.add(buildSeat(entry));
        }
      }
      rows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: seatsInRow)));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text("حجز تذكرة جديدة (${widget.name})")),
        body: _isLoading && timeSlots.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedLine,
                    decoration: InputDecoration(
                        labelText: "اختر مسار المترو",
                        prefixIcon: Icon(Icons.route,
                            color: Theme.of(context).primaryColor)),
                    items: metroLines
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedLine = val;
                        selectedDepartureStation = null;
                        selectedArrivalStation = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (selectedLine != null) ...[
                    DropdownButtonFormField<String>(
                      value: selectedDepartureStation,
                      decoration: InputDecoration(
                          labelText: "محطة المغادرة",
                          prefixIcon: Icon(Icons.departure_board,
                              color: Theme.of(context).primaryColor)),
                      items: _buildStationItems(selectedLine),
                      onChanged: (val) {
                        setState(() {
                          selectedDepartureStation = val;
                        });
                      },
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedArrivalStation,
                      decoration: InputDecoration(
                          labelText: "محطة الوصول",
                          prefixIcon: Icon(Icons.pin_drop,
                              color: Theme.of(context).primaryColor)),
                      items: _buildStationItems(selectedLine),
                      onChanged: (val) {
                        setState(() {
                          selectedArrivalStation = val;
                        });
                      },
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 20),
                  ],
                  DropdownButtonFormField<String>(
                    value: selectedTime,
                    decoration: InputDecoration(
                        labelText: "اختر وقت الرحلة",
                        prefixIcon: Icon(Icons.access_time,
                            color: Theme.of(context).primaryColor)),
                    items: timeSlots.map((time) {
                      try {
                        return DropdownMenuItem(
                            value: time,
                            child: Text(
                                DateFormat('yyyy/MM/dd - hh:mm a', 'ar_SA')
                                    .format(DateTime.parse(time))));
                      } catch (e) {
                        return DropdownMenuItem(value: time, child: Text(time));
                      }
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedTime = val;
                        });
                        fetchSeatStatus(val);
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                        labelText: "اختيار الفئة",
                        prefixIcon: Icon(Icons.category,
                            color: Theme.of(context).primaryColor)),
                    items: seatCategories
                        .map((category) => DropdownMenuItem(
                            value: category, child: Text(category)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCategory = val;
                        selectedSeat = null;
                      });
                      if (selectedTime != null) fetchSeatStatus(selectedTime!);
                    },
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("اختر المقعد ($selectedCategory):",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (selectedSeat != null)
                        Text("مختار: $selectedSeat",
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.bold)),
                      if (_isLoading && timeSlots.isNotEmpty)
                        const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Column(children: buildSeatRows()),
                  const SizedBox(height: 40),
                  ValueListenableBuilder<bool>(
                      valueListenable: _isBookingNotifier,
                      builder: (context, isBooking, child) {
                        return ElevatedButton.icon(
                          icon: isBooking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white)))
                              : const Icon(Icons.book_online),
                          label:
                              Text(isBooking ? "جاري الحجز..." : "تأكيد الحجز"),
                          onPressed: selectedSeat == null || isBooking
                              ? null
                              : bookTicket,
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50)),
                        );
                      }),
                ],
              ),
      ),
    );
  }
}

class TicketQrPagePassenger extends StatelessWidget {
  final String ticketId;
  final String userName;
  final String bookingTime;
  final String seatType;
  final String line;
  final String departure;
  final String arrival;
  final String seatNumber;

  // لا يوجد اسم موظف هنا
  const TicketQrPagePassenger({
    Key? key,
    required this.ticketId,
    required this.userName,
    required this.bookingTime,
    required this.seatType,
    required this.line,
    required this.departure,
    required this.arrival,
    required this.seatNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qrData = ticketId;
    String formattedTime = bookingTime;
    try {
      formattedTime = DateFormat('yyyy/MM/dd - hh:mm a', 'ar_SA')
          .format(DateTime.parse(bookingTime));
    } catch (e) {}

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تذكرة الراكب'), centerTitle: true),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("تم الحجز بنجاح!",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
                const SizedBox(height: 15),
                const Text("امسح هذا الرمز عند البوابة للدخول",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: QrImageView(
                      data: qrData, version: QrVersions.auto, size: 220.0),
                ),
                const SizedBox(height: 30),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTicketDetailRow(
                            Icons.confirmation_number_outlined,
                            "رقم التذكرة:",
                            ticketId),
                        _buildTicketDetailRow(
                            Icons.person_outline, "اسم الراكب:", userName),
                        _buildTicketDetailRow(
                            Icons.access_time, "وقت الرحلة:", formattedTime),
                        _buildTicketDetailRow(Icons.event_seat_outlined,
                            "المقعد:", "$seatNumber ($seatType)"),
                        _buildTicketDetailRow(
                            Icons.route_outlined, "المسار:", line),
                        _buildTicketDetailRow(
                            Icons.departure_board_outlined, "من:", departure),
                        _buildTicketDetailRow(
                            Icons.pin_drop_outlined, "إلى:", arrival),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.home_outlined),
                  label: const Text("العودة إلى الصفحة الرئيسية"),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomePage(name: userName)),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo[700]),
          const SizedBox(width: 10),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 5),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class BookingPage extends StatefulWidget {
  final String name;
  final String employeeName;

  BookingPage({required this.name, required this.employeeName});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final List<String> metroLines = [
    'المسار الأزرق',
    'المسار الأحمر',
    'المسار البرتقالي',
    'المسار الأصفر',
    'المسار الأخضر',
    'المسار البنفسجي',
  ];

  final Map<String, List<String>> metroStations = {
    'المسار الأزرق': [
      'SABB',
      'Dr Sulaiman Al-Habib',
      'Al-Shabab Club Stadium',
      'KAFD',
      'Al-Murooj',
      'King Fahad District',
      'King Fahad District 2',
      'STC',
      'Al-Wurud 2',
      'Al-Urubah',
      'Bank Albilad',
      'King Fahad Library',
      'Ministry of Interior',
      'Al-Murabba',
      'Passport Department',
      'National Museum',
      'Al-Bat’ha',
      'Qasr Al-Hokm',
      'Al-Owd',
      'Skirinah',
      'Manfouhah',
      'Al-Iman Hospital',
      'Transportation Center',
      'Al-Aziziah',
      'Ad Dar Al-Baida',
    ],
    'المسار الأحمر': [
      'King Saud University Station',
      'King Salman Oasis',
      'KACST',
      'At Takhassusi',
      'STC',
      'Al-Wurud',
      'King Abdulaziz Road',
      'Ministry of Education',
      'An Nuzhah',
      'Riyadh Exhibition Center',
      'Khalid Bin Alwaleed Road',
      'Al-Hamra',
      'Al-Khaleej',
      'City Centre Ishbiliyah',
      'King Fahd Sports City Station',
    ],
    'المسار البرتقالي': [
      'Jeddah Road',
      'Tuwaiq',
      'Ad Douh',
      'Western Station',
      'Aishah bint Abi Bakr Street',
      'Dhahrat Al-Badiah',
      'Sultanah',
      'Al-Jarradiyah',
      'Courts Complex',
      'Qasr Al-Hokm',
      'Al-Hilla',
      'Al-Margab',
      'As Salhiyah',
      'First Industrial City',
      'Railway Station',
      'Al-Malaz',
      'Jarir District',
      'Al-Rajhi Grand Mosque',
      'Harun Ar Rashid Road',
      'An Naseem',
      'Khashm Al-An',
    ],
    'المسار الأصفر': [
      'Airport T1-2',
      'Airport T3',
      'Airport T4',
      'Airport T5',
      'KAFD'
    ],
    'المسار الأخضر': ['Ministry of Education', 'National Museum'],
    'المسار البنفسجي': ['KAFD', 'An Naseem'],
  };

  final List<String> seatCategories = ['Single', 'Family', 'VIP'];

  String? selectedLine;
  String? selectedDepartureStation;
  String? selectedArrivalStation;
  List<String> timeSlots = [];
  String? selectedTime;
  String? selectedCategory;
  String? selectedSeat;
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _seatsStatus = {
    'S1': {'isBooked': false, 'type': 'Single'},
    'S2': {'isBooked': false, 'type': 'Single'},
    'S3': {'isBooked': false, 'type': 'Single'},
    'S4': {'isBooked': false, 'type': 'Single'},
    'S5': {'isBooked': false, 'type': 'Single'},
    'S6': {'isBooked': false, 'type': 'Single'},
    'S7': {'isBooked': false, 'type': 'Single'},
    'S8': {'isBooked': false, 'type': 'Single'},
    'S9': {'isBooked': false, 'type': 'Single'},
    'S10': {'isBooked': false, 'type': 'Single'},
    'S11': {'isBooked': false, 'type': 'Single'},
    'S12': {'isBooked': false, 'type': 'Single'},
    'S13': {'isBooked': false, 'type': 'Single'},
    'S14': {'isBooked': false, 'type': 'Single'},
    'S15': {'isBooked': false, 'type': 'Single'},
    'S16': {'isBooked': false, 'type': 'Single'},
    'S17': {'isBooked': false, 'type': 'Single'},
    'S18': {'isBooked': false, 'type': 'Single'},
    'S19': {'isBooked': false, 'type': 'Single'},
    'S20': {'isBooked': false, 'type': 'Single'},
    'S21': {'isBooked': false, 'type': 'Single'},
    'S22': {'isBooked': false, 'type': 'Single'},
    'S23': {'isBooked': false, 'type': 'Single'},
    'S24': {'isBooked': false, 'type': 'Single'},
    'S25': {'isBooked': false, 'type': 'Single'},
    'S26': {'isBooked': false, 'type': 'Single'},
    'S27': {'isBooked': false, 'type': 'Single'},
    'S28': {'isBooked': false, 'type': 'Single'},
    'S29': {'isBooked': false, 'type': 'Single'},
    'S30': {'isBooked': false, 'type': 'Single'},
    'S31': {'isBooked': false, 'type': 'Single'},
    'S32': {'isBooked': false, 'type': 'Single'},
  };

  final ValueNotifier<bool> _isBookingNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    selectedCategory = seatCategories.first;
    loadTimeSlots();
  }

  void loadTimeSlots() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await http
          .get(Uri.parse("$backendUrl/times?interval_minutes=5"))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        List<String> fetchedTimes = List<String>.from(jsonDecode(res.body));
        final now = DateTime.now();

        fetchedTimes = fetchedTimes.where((timeString) {
          try {
            final slotTime = DateTime.parse(timeString);
            bool isFuture = slotTime.isAfter(now);
            bool isOperatingHours = slotTime.hour >= 5;
            return isFuture && isOperatingHours;
          } catch (e) {
            return false;
          }
        }).toList();

        setState(() {
          timeSlots = fetchedTimes;
          selectedTime = timeSlots.isNotEmpty ? timeSlots.first : null;
        });
        if (selectedTime != null) {
          await fetchSeatStatus(selectedTime!);
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _showMessage("فشل في جلب الأوقات المتاحة", isError: true);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError("خطأ في الاتصال بالخادم: ${e.toString()}");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchSeatStatus(String time) async {
    if (selectedLine == null ||
        selectedDepartureStation == null ||
        selectedArrivalStation == null) return;

    setState(() {
      _isLoading = true;
      _seatsStatus.forEach((key, value) {
        value['isBooked'] = false;
      });
      selectedSeat = null;
    });

    try {
      final res = await http
          .post(
            Uri.parse("$backendUrl/booked_seats/status"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "line": selectedLine,
              "departure_station": selectedDepartureStation,
              "arrival_station": selectedArrivalStation,
              "time_slot": time,
              "seat_type": selectedCategory,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final List<dynamic> bookedSeats =
            jsonDecode(res.body)['booked_seats'] ?? [];
        setState(() {
          for (var seatNumber in bookedSeats) {
            if (_seatsStatus.containsKey(seatNumber)) {
              _seatsStatus[seatNumber]!['isBooked'] = true;
            }
          }
          _isLoading = false;
        });
      } else {
        final body = jsonDecode(res.body);
        _showMessage(body["message"] ?? "فشل في جلب حالة المقاعد",
            isError: true);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError("خطأ في الاتصال: ${e.toString()}");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void bookTicket() async {
    if (_isBookingNotifier.value) return;
    _isBookingNotifier.value = true;
    FocusScope.of(context).unfocus();

    if (selectedSeat == null ||
        selectedTime == null ||
        selectedLine == null ||
        selectedDepartureStation == null ||
        selectedArrivalStation == null) {
      _showError("الرجاء اختيار جميع تفاصيل الحجز.");
      _isBookingNotifier.value = false;
      return;
    }
    if (selectedDepartureStation == selectedArrivalStation) {
      _showError("محطة المغادرة ومحطة الوصول يجب أن تكونا مختلفتين.");
      _isBookingNotifier.value = false;
      return;
    }

    try {
      final seatType = selectedCategory;
      final isVip = selectedCategory == 'VIP';

      final res = await http
          .post(
            Uri.parse("$backendUrl/book"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": widget.name,
              "time": selectedTime,
              "seat_number": selectedSeat,
              "seat_type": seatType,
              "vip": isVip,
              "line": selectedLine,
              "departure_station": selectedDepartureStation,
              "arrival_station": selectedArrivalStation,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(res.body);

      if (res.statusCode == 200 && body["success"] == true) {
        final ticketId = body["ticket_id"];
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TicketQrPage(
                ticketId: ticketId.toString(),
                userName: widget.name,
                bookingTime: selectedTime!,
                seatType: selectedCategory!,
                line: selectedLine!,
                departure: selectedDepartureStation!,
                arrival: selectedArrivalStation!,
                seatNumber: selectedSeat!,
                employeeName: widget.employeeName,
              ),
            ),
          );
        }
      } else {
        _showError(body["message"] ?? "فشل الحجز.");
        if (selectedTime != null) fetchSeatStatus(selectedTime!);
      }
    } catch (e) {
      _showError("خطأ في الاتصال: ${e.toString()}");
    } finally {
      _isBookingNotifier.value = false;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, textDirection: ui.TextDirection.rtl),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  List<DropdownMenuItem<String>> _buildStationItems(String? line) {
    if (line == null || !metroStations.containsKey(line)) return [];

    final double widthAvailable = (MediaQuery.of(context).size.width / 2) - 50;

    return (metroStations[line] ?? [])
        .map((station) => DropdownMenuItem(
              value: station,
              child: SizedBox(
                width: widthAvailable,
                child: Text(
                  station,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ))
        .toList();
  }

  Widget buildSeat(MapEntry<String, Map<String, dynamic>> entry) {
    final seatNumber = entry.key;
    final isBooked = entry.value['isBooked'] as bool;
    final isSelected = selectedSeat == seatNumber;
    final Color svgColor = isBooked ? Colors.red.shade700 : Colors.green;
    const double seatIconSize = 36.0;
    const double width = 60.0;

    return InkWell(
      onTap: isBooked
          ? null
          : () {
              setState(() {
                selectedSeat = isSelected ? null : seatNumber;
              });
            },
      child: SizedBox(
        width: width,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Colors.green.shade500, width: 3)
                : Border.all(color: Colors.transparent, width: 3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(seatNumber,
                  style: TextStyle(
                      color: svgColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 2),
              SvgPicture.asset('assets/seat_icon.svg',
                  width: seatIconSize,
                  height: seatIconSize,
                  colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildSeatRows() {
    final allSeats = _seatsStatus.entries.toList();
    List<Widget> rows = [];
    const List<List<String?>> finalLayout = [
      ['S1', null, null, 'S17'],
      ['S2', null, null, 'S18'],
      [null, null, 'Divider', null, null],
      ['S3', null, 'S19', 'S20'],
      ['S5', null, 'S21', 'S22'],
      ['S7', null, 'S23', 'S24'],
      ['S9', null, 'S25', 'S26'],
      [null, null, 'Divider', null, null],
      ['S11', null, 'S27', 'S28'],
      ['S13', null, 'S29', 'S30'],
      ['S15', null, 'S31', 'S32'],
      ['S4', null, 'S6', 'S8'],
      [null, null, 'Divider', null, null],
      ['S20', null, null, 'S24'],
      ['S22', null, null, 'S26'],
    ];
    Map<String, MapEntry<String, Map<String, dynamic>>> seatMap = {
      for (var entry in allSeats) entry.key: entry
    };

    for (var rowDefinition in finalLayout) {
      if (rowDefinition.length == 5 && rowDefinition[2] == 'Divider') {
        rows.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0),
            child: Divider(thickness: 2, color: Colors.grey)));
        continue;
      }
      List<Widget> seatsInRow = [];
      for (int i = 0; i < rowDefinition.length; i++) {
        final seatKey = rowDefinition[i];
        if (seatKey == null) {
          seatsInRow.add(SizedBox(width: i == 2 ? 40.0 : 10.0));
          continue;
        }
        final seatKeys = seatKey.split(',');
        if (seatKeys.length > 1) {
          seatsInRow.add(Row(
              mainAxisSize: MainAxisSize.min,
              children: seatKeys.map((id) {
                final entry = seatMap[id.trim()] ??
                    allSeats.firstWhere((e) => e.key == id.trim(),
                        orElse: () => MapEntry(
                            id.trim(), {'isBooked': true, 'type': 'Single'}));
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: buildSeat(entry));
              }).toList()));
        } else {
          final entry = seatMap[seatKey.trim()] ??
              allSeats.firstWhere((e) => e.key == seatKey.trim(),
                  orElse: () => MapEntry(
                      seatKey.trim(), {'isBooked': true, 'type': 'Single'}));
          seatsInRow.add(buildSeat(entry));
        }
      }
      rows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: seatsInRow)));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text("حجز تذكرة جديدة (${widget.name})")),
        body: _isLoading && timeSlots.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedLine,
                    decoration: InputDecoration(
                        labelText: "اختر مسار المترو",
                        prefixIcon: Icon(Icons.route,
                            color: Theme.of(context).primaryColor)),
                    items: metroLines
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedLine = val;
                        selectedDepartureStation = null;
                        selectedArrivalStation = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // 🛑 عرض المحطات تحت بعضها (Vertical) لمنع الخطأ
                  if (selectedLine != null) ...[
                    DropdownButtonFormField<String>(
                      value: selectedDepartureStation,
                      decoration: InputDecoration(
                          labelText: "محطة المغادرة",
                          prefixIcon: Icon(Icons.departure_board,
                              color: Theme.of(context).primaryColor)),
                      items: _buildStationItems(selectedLine),
                      onChanged: (val) {
                        setState(() {
                          selectedDepartureStation = val;
                        });
                      },
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedArrivalStation,
                      decoration: InputDecoration(
                          labelText: "محطة الوصول",
                          prefixIcon: Icon(Icons.pin_drop,
                              color: Theme.of(context).primaryColor)),
                      items: _buildStationItems(selectedLine),
                      onChanged: (val) {
                        setState(() {
                          selectedArrivalStation = val;
                        });
                      },
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 20),
                  ],

                  DropdownButtonFormField<String>(
                    value: selectedTime,
                    decoration: InputDecoration(
                        labelText: "اختر وقت الرحلة",
                        prefixIcon: Icon(Icons.access_time,
                            color: Theme.of(context).primaryColor)),
                    items: timeSlots.map((time) {
                      try {
                        return DropdownMenuItem(
                            value: time,
                            child: Text(
                                DateFormat('yyyy/MM/dd - hh:mm a', 'ar_SA')
                                    .format(DateTime.parse(time))));
                      } catch (e) {
                        return DropdownMenuItem(value: time, child: Text(time));
                      }
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedTime = val;
                        });
                        fetchSeatStatus(val);
                      }
                    },
                  ),
                  const SizedBox(height: 30),

                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                        labelText: "اختيار الفئة",
                        prefixIcon: Icon(Icons.category,
                            color: Theme.of(context).primaryColor)),
                    items: seatCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCategory = val;
                        selectedSeat = null;
                      });
                      // 🛑 تحديث المقاعد فوراً عند تغيير الفئة
                      if (selectedTime != null) fetchSeatStatus(selectedTime!);
                    },
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("اختر المقعد ($selectedCategory):",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (selectedSeat != null)
                        Text("مختار: $selectedSeat",
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.bold)),
                      if (_isLoading && timeSlots.isNotEmpty)
                        const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Column(children: buildSeatRows()),
                  const SizedBox(height: 40),
                  ValueListenableBuilder<bool>(
                      valueListenable: _isBookingNotifier,
                      builder: (context, isBooking, child) {
                        return ElevatedButton.icon(
                          icon: isBooking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white)))
                              : const Icon(Icons.book_online),
                          label:
                              Text(isBooking ? "جاري الحجز..." : "تأكيد الحجز"),
                          onPressed: selectedSeat == null || isBooking
                              ? null
                              : bookTicket,
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50)),
                        );
                      }),
                ],
              ),
      ),
    );
  }
}

class TicketQrPage extends StatelessWidget {
  final String ticketId;
  final String userName;
  final String bookingTime;
  final String seatType;
  final String line;
  final String departure;
  final String arrival;
  final String seatNumber;
  final String employeeName;

  const TicketQrPage({
    Key? key,
    required this.ticketId,
    required this.userName,
    required this.bookingTime,
    required this.seatType,
    required this.line,
    required this.departure,
    required this.arrival,
    required this.seatNumber,
    required this.employeeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qrData = ticketId;

    String formattedTime = "غير متاح";
    try {
      formattedTime = DateFormat('yyyy/MM/dd - hh:mm a', 'ar_SA')
          .format(DateTime.parse(bookingTime));
    } catch (e) {
      print("Error formatting booking time: $e");
      formattedTime = bookingTime;
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تذكرة الراكب'),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "تم الحجز بنجاح!",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                const SizedBox(height: 15),
                const Text(
                  "امسح هذا الرمز عند البوابة للدخول",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220.0,
                    errorStateBuilder: (cxt, err) {
                      return const Center(
                        child: Text(
                          "حدث خطأ أثناء توليد رمز QR",
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTicketDetailRow(
                            Icons.confirmation_number_outlined,
                            "رقم التذكرة:",
                            ticketId),
                        _buildTicketDetailRow(
                            Icons.person_outline, "اسم الراكب:", userName),
                        _buildTicketDetailRow(
                            Icons.access_time, "وقت الرحلة:", formattedTime),
                        _buildTicketDetailRow(Icons.event_seat_outlined,
                            "المقعد:", "$seatNumber ($seatType)"),
                        _buildTicketDetailRow(
                            Icons.route_outlined, "المسار:", line),
                        _buildTicketDetailRow(
                            Icons.departure_board_outlined, "من:", departure),
                        _buildTicketDetailRow(
                            Icons.pin_drop_outlined, "إلى:", arrival),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.home_outlined),
                  label: const Text("العودة إلى لوحة تحكم الموظف"),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              EmployeeHomePage(name: employeeName)),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo[700]),
          const SizedBox(width: 10),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 5),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class SeatStatusPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SeatStatusPageState();
}

class _SeatStatusPageState extends State<SeatStatusPage> {
  final List<String> metroLines = [
    'المسار الأزرق',
    'المسار الأحمر',
    'المسار البرتقالي',
    'المسار الأصفر',
    'المسار الأخضر',
    'المسار البنفسجي',
  ];
  final Map<String, List<String>> metroStations = {
    'المسار الأزرق': [
      'SABB',
      'Dr Sulaiman Al-Habib',
      'Al-Shabab Club Stadium',
      'KAFD',
      'Al-Murooj',
      'King Fahad District',
      'King Fahad District 2',
      'STC',
      'Al-Wurud 2',
      'Al-Urubah',
      'Bank Albilad',
      'King Fahad Library',
      'Ministry of Interior',
      'Al-Murabba',
      'Passport Department',
      'National Museum',
      'Al-Bat’ha',
      'Qasr Al-Hokm',
      'Al-Owd',
      'Skirinah',
      'Manfouhah',
      'Al-Iman Hospital',
      'Transportation Center',
      'Al-Aziziah',
      'Ad Dar Al-Baida',
    ],
    'المسار الأحمر': [
      'King Saud University Station',
      'King Salman Oasis',
      'KACST',
      'At Takhassusi',
      'STC',
      'Al-Wurud',
      'King Abdulaziz Road',
      'Ministry of Education',
      'An Nuzhah',
      'Riyadh Exhibition Center',
      'Khalid Bin Alwaleed Road',
      'Al-Hamra',
      'Al-Khaleej',
      'City Centre Ishbiliyah',
      'King Fahd Sports City Station',
    ],
    'المسار البرتقالي': [
      'Jeddah Road',
      'Tuwaiq',
      'Ad Douh',
      'Western Station',
      'Aishah bint Abi Bakr Street',
      'Dhahrat Al-Badiah',
      'Sultanah',
      'Al-Jarradiyah',
      'Courts Complex',
      'Qasr Al-Hokm',
      'Al-Hilla',
      'Al-Margab',
      'As Salhiyah',
      'First Industrial City',
      'Railway Station',
      'Al-Malaz',
      'Jarir District',
      'Al-Rajhi Grand Mosque',
      'Harun Ar Rashid Road',
      'An Naseem',
      'Khashm Al-An',
    ],
    'المسار الأصفر': [
      'Airport T1-2',
      'Airport T3',
      'Airport T4',
      'Airport T5',
      'KAFD'
    ],
    'المسار الأخضر': ['Ministry of Education', 'National Museum'],
    'المسار البنفسجي': ['KAFD', 'An Naseem'],
  };

  final List<String> seatCategories = ['Single', 'Family', 'VIP'];
  String? selectedCategory = 'Single';

  final Map<String, Map<String, dynamic>> _seatsStatus = {
    'S1': {'isBooked': false, 'type': 'Single'},
    'S2': {'isBooked': false, 'type': 'Single'},
    'S3': {'isBooked': false, 'type': 'Single'},
    'S4': {'isBooked': false, 'type': 'Single'},
    'S5': {'isBooked': false, 'type': 'Single'},
    'S6': {'isBooked': false, 'type': 'Single'},
    'S7': {'isBooked': false, 'type': 'Single'},
    'S8': {'isBooked': false, 'type': 'Single'},
    'S9': {'isBooked': false, 'type': 'Single'},
    'S10': {'isBooked': false, 'type': 'Single'},
    'S11': {'isBooked': false, 'type': 'Single'},
    'S12': {'isBooked': false, 'type': 'Single'},
    'S13': {'isBooked': false, 'type': 'Single'},
    'S14': {'isBooked': false, 'type': 'Single'},
    'S15': {'isBooked': false, 'type': 'Single'},
    'S16': {'isBooked': false, 'type': 'Single'},
    'S17': {'isBooked': false, 'type': 'Single'},
    'S18': {'isBooked': false, 'type': 'Single'},
    'S19': {'isBooked': false, 'type': 'Single'},
    'S20': {'isBooked': false, 'type': 'Single'},
    'S21': {'isBooked': false, 'type': 'Single'},
    'S22': {'isBooked': false, 'type': 'Single'},
    'S23': {'isBooked': false, 'type': 'Single'},
    'S24': {'isBooked': false, 'type': 'Single'},
    'S25': {'isBooked': false, 'type': 'Single'},
    'S26': {'isBooked': false, 'type': 'Single'},
    'S27': {'isBooked': false, 'type': 'Single'},
    'S28': {'isBooked': false, 'type': 'Single'},
    'S29': {'isBooked': false, 'type': 'Single'},
    'S30': {'isBooked': false, 'type': 'Single'},
    'S31': {'isBooked': false, 'type': 'Single'},
    'S32': {'isBooked': false, 'type': 'Single'},
  };

  String? selectedLine;
  String? selectedDepartureStation;
  String? selectedArrivalStation;
  List<String> timeSlots = [];
  String? selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadTimeSlots();
  }

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  List<DropdownMenuItem<String>> _buildStationItems(String? line) {
    if (line == null || !metroStations.containsKey(line)) return [];
    final double widthAvailable = (MediaQuery.of(context).size.width / 2) - 50;
    return (metroStations[line] ?? [])
        .map((station) => DropdownMenuItem(
              value: station,
              child: SizedBox(
                  width: widthAvailable,
                  child: Text(station,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 13))),
            ))
        .toList();
  }

  void loadTimeSlots() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await http
          .get(Uri.parse("$backendUrl/times?interval_minutes=1&all_day=true"))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        List<String> fetchedTimes = List<String>.from(jsonDecode(res.body));

        fetchedTimes = fetchedTimes.where((timeString) {
          try {
            final slotTime = DateTime.parse(timeString);
            return slotTime.hour >= 5;
          } catch (e) {
            return false;
          }
        }).toList();

        setState(() {
          timeSlots = fetchedTimes;
          selectedTime = timeSlots.isNotEmpty ? timeSlots.first : null;
        });
      } else {
        _showMessage("فشل في جلب الأوقات", Colors.red);
      }
    } catch (e) {
      _showMessage("خطأ في الاتصال: ${e.toString()}", Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchSeatStatus() async {
    if (selectedLine == null ||
        selectedDepartureStation == null ||
        selectedArrivalStation == null ||
        selectedTime == null) {
      _showMessage("الرجاء اختيار جميع تفاصيل الرحلة", Colors.orange);
      return;
    }
    setState(() {
      _isLoading = true;
      _seatsStatus.forEach((key, value) {
        value['isBooked'] = false;
      });
    });
    try {
      final res = await http
          .post(
            Uri.parse("$backendUrl/booked_seats/status"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "line": selectedLine,
              "departure_station": selectedDepartureStation,
              "arrival_station": selectedArrivalStation,
              "time_slot": selectedTime,
              "seat_type": selectedCategory,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final List<dynamic> bookedSeats =
            jsonDecode(res.body)['booked_seats'] ?? [];
        setState(() {
          for (var seatNumber in bookedSeats) {
            if (_seatsStatus.containsKey(seatNumber)) {
              _seatsStatus[seatNumber]!['isBooked'] = true;
            }
          }
        });
        _showMessage("تم تحديث حالة المقاعد بنجاح.", Colors.green);
      } else {
        _showMessage("فشل في جلب الحالة", Colors.red);
      }
    } catch (e) {
      _showMessage("خطأ: ${e.toString()}", Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildSeat(MapEntry<String, Map<String, dynamic>> entry) {
    final seatNumber = entry.key;
    final isBooked = entry.value['isBooked'] as bool;
    final Color svgColor = isBooked ? Colors.red.shade700 : Colors.green;
    return SizedBox(
      width: 60,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent, width: 3)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(seatNumber,
                style: TextStyle(
                    color: svgColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 2),
            SvgPicture.asset('assets/seat_icon.svg',
                width: 36,
                height: 36,
                colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn)),
          ],
        ),
      ),
    );
  }

  List<Widget> buildSeatRows() {
    final allSeats = _seatsStatus.entries.toList();
    List<Widget> rows = [];
    const List<List<String?>> finalLayout = [
      ['S1', null, null, 'S17'],
      ['S2', null, null, 'S18'],
      [null, null, 'Divider', null, null],
      ['S3', null, 'S19', 'S20'],
      ['S5', null, 'S21', 'S22'],
      ['S7', null, 'S23', 'S24'],
      ['S9', null, 'S25', 'S26'],
      [null, null, 'Divider', null, null],
      ['S11', null, 'S27', 'S28'],
      ['S13', null, 'S29', 'S30'],
      ['S15', null, 'S31', 'S32'],
      ['S4', null, 'S6', 'S8'],
      [null, null, 'Divider', null, null],
      ['S20', null, null, 'S24'],
      ['S22', null, null, 'S26'],
    ];
    Map<String, MapEntry<String, Map<String, dynamic>>> seatMap = {
      for (var entry in allSeats) entry.key: entry
    };

    for (var rowDefinition in finalLayout) {
      if (rowDefinition.length == 5 && rowDefinition[2] == 'Divider') {
        rows.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0),
            child: Divider(thickness: 2, color: Colors.grey)));
        continue;
      }
      List<Widget> seatsInRow = [];
      for (int i = 0; i < rowDefinition.length; i++) {
        final seatKey = rowDefinition[i];
        if (seatKey == null) {
          seatsInRow.add(SizedBox(width: i == 2 ? 40.0 : 10.0));
          continue;
        }
        final seatKeys = seatKey.split(',');
        if (seatKeys.length > 1) {
          seatsInRow.add(Row(
              mainAxisSize: MainAxisSize.min,
              children: seatKeys.map((id) {
                final entry = seatMap[id.trim()] ??
                    allSeats.firstWhere((e) => e.key == id.trim(),
                        orElse: () => MapEntry(
                            id.trim(), {'isBooked': true, 'type': 'Single'}));
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: buildSeat(entry));
              }).toList()));
        } else {
          final entry = seatMap[seatKey.trim()] ??
              allSeats.firstWhere((e) => e.key == seatKey.trim(),
                  orElse: () => MapEntry(
                      seatKey.trim(), {'isBooked': true, 'type': 'Single'}));
          seatsInRow.add(buildSeat(entry));
        }
      }
      rows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: seatsInRow)));
    }
    return rows;
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(children: [
      Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 14)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('رؤية حالة المقاعد')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: selectedLine,
              decoration: InputDecoration(
                  labelText: "اختر مسار المترو",
                  prefixIcon:
                      Icon(Icons.route, color: Theme.of(context).primaryColor)),
              items: metroLines
                  .map((line) =>
                      DropdownMenuItem(value: line, child: Text(line)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedLine = val;
                  selectedDepartureStation = null;
                  selectedArrivalStation = null;
                  _seatsStatus.forEach((k, v) => v['isBooked'] = false);
                });
              },
            ),
            const SizedBox(height: 15),
            if (selectedLine != null) ...[
              DropdownButtonFormField<String>(
                value: selectedDepartureStation,
                decoration: InputDecoration(
                    labelText: "محطة المغادرة",
                    prefixIcon: Icon(Icons.departure_board,
                        color: Theme.of(context).primaryColor)),
                items: _buildStationItems(selectedLine),
                onChanged: (val) {
                  setState(() {
                    selectedDepartureStation = val;
                    _seatsStatus.forEach((k, v) => v['isBooked'] = false);
                  });
                },
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down,
                    color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedArrivalStation,
                decoration: InputDecoration(
                    labelText: "محطة الوصول",
                    prefixIcon: Icon(Icons.pin_drop,
                        color: Theme.of(context).primaryColor)),
                items: _buildStationItems(selectedLine),
                onChanged: (val) {
                  setState(() {
                    selectedArrivalStation = val;
                    _seatsStatus.forEach((k, v) => v['isBooked'] = false);
                  });
                },
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down,
                    color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 20),
            ],
            DropdownButtonFormField<String>(
              value: selectedTime,
              decoration: InputDecoration(
                  labelText: "اختر وقت الرحلة",
                  prefixIcon: Icon(Icons.access_time,
                      color: Theme.of(context).primaryColor)),
              items: timeSlots.map((time) {
                try {
                  return DropdownMenuItem(
                      value: time,
                      child: Text(DateFormat('yyyy/MM/dd - hh:mm a', 'ar_SA')
                          .format(DateTime.parse(time))));
                } catch (e) {
                  return DropdownMenuItem(value: time, child: Text(time));
                }
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedTime = val;
                  _seatsStatus.forEach((k, v) => v['isBooked'] = false);
                });
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                  labelText: "نوع الفئة",
                  prefixIcon: Icon(Icons.category,
                      color: Theme.of(context).primaryColor)),
              items: seatCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedCategory = val;
                  _seatsStatus.forEach((k, v) => v['isBooked'] = false);
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: (selectedLine == null ||
                      selectedDepartureStation == null ||
                      selectedArrivalStation == null ||
                      selectedTime == null ||
                      _isLoading)
                  ? null
                  : fetchSeatStatus,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.chair_outlined),
              label:
                  Text(_isLoading ? "جاري جلب الحالة..." : "جلب حالة المقاعد"),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 30),
            const Text("تخطيط الحافلة:",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
                textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildLegendItem(Colors.green, "متاح"),
              const SizedBox(width: 15),
              _buildLegendItem(Colors.red.shade700, "محجوز")
            ]),
            const SizedBox(height: 20),
            Column(children: buildSeatRows()),
          ],
        ),
      ),
    );
  }
}

class Booking {
  final String ticketId;
  final String line;
  final String departureStation;
  final String arrivalStation;
  final String time;
  final String seat;
  final bool isVip;

  Booking({
    required this.ticketId,
    required this.line,
    required this.departureStation,
    required this.arrivalStation,
    required this.time,
    required this.seat,
    required this.isVip,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      ticketId: (json['id_ticket'] ?? 'N/A').toString(),
      line: (json['line'] ?? 'N/A').trim(),
      departureStation: (json['departure_station'] ?? 'N/A').trim(),
      arrivalStation: (json['arrival_station'] ?? 'N/A').trim(),
      time: (json['date_ticket_time'] ?? 'N/A').trim(),
      seat: (json['seat_number'] ?? 'N/A').toString().trim(),
      isVip: json['vip'] == 1,
    );
  }
}

class _BookingsList extends StatefulWidget {
  final String passengerName;
  final String endpoint;
  final bool enableEdit;
  final List<Booking>? initialBookings;
  final String employeeName;
  const _BookingsList(
      {required this.passengerName,
      required this.endpoint,
      this.enableEdit = false,
      this.initialBookings,
      required this.employeeName});

  @override
  State<_BookingsList> createState() => _BookingsListState();
}

class _BookingsListState extends State<_BookingsList> {
  Future<List<Booking>>? _bookingsFuture;

  @override
  void initState() {
    super.initState();
    if (widget.initialBookings != null) {
      _bookingsFuture = Future.value(widget.initialBookings!);
    } else {
      _bookingsFuture = _fetchBookings();
    }
  }

  Future<List<Booking>> _fetchBookings() async {
    final url =
        "$backendUrl${widget.endpoint}?passenger_name=${Uri.encodeComponent(widget.passengerName)}";
    print("Fetching bookings from: $url"); // طباعة للتحقق

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        List<dynamic> data = jsonDecode(res.body);
        List<Booking> bookings =
            data.map((item) => Booking.fromJson(item)).toList();

        bookings.sort((a, b) {
          try {
            DateTime timeA = DateTime.parse(a.time);
            DateTime timeB = DateTime.parse(b.time);
            return widget.endpoint == '/active_bookings'
                ? timeA.compareTo(timeB)
                : timeB.compareTo(timeA);
          } catch (e) {
            print("Error parsing date for sorting: $e");
            return 0;
          }
        });

        return bookings;
      } else {
        throw Exception('فشل في جلب الحجوزات (${res.statusCode})');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال بالخادم: ${e.toString()}');
    }
  }

  // دالة لإعادة تحميل البيانات عند السحب للأسفل
  Future<void> _refreshBookings() async {
    setState(() {
      if (widget.initialBookings == null) {
        _bookingsFuture = _fetchBookings(); // إعادة طلب البيانات
      } else {
        _bookingsFuture = Future.value(widget.initialBookings!);
      }
    });
  }

  Widget _buildBookingTile(
      BuildContext context, Booking booking, bool isActive) {
    String formattedTime = booking.time;
    try {
      formattedTime = DateFormat('yyyy/MM/dd - hh:mm a', 'ar_SA')
          .format(DateTime.parse(booking.time));
    } catch (e) {}

    String seatTypeDisplay = booking.isVip
        ? 'VIP'
        : (booking.seat.startsWith('F') ? 'Family' : 'Single');

    IconData iconDisplay;
    if (widget.enableEdit) {
      iconDisplay = Icons.edit_note;
    } else if (seatTypeDisplay == 'VIP') {
      iconDisplay = Icons.chair_alt;
    } else if (seatTypeDisplay == 'Family') {
      iconDisplay = Icons.event_seat;
    } else {
      iconDisplay = Icons.chair;
    }

    return Card(
      color: isActive ? Colors.white : Colors.grey.shade100,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: isActive ? 2 : 1,
      child: ListTile(
        leading: Icon(
          iconDisplay,
          color: isActive
              ? (widget.enableEdit ? Colors.blue.shade700 : Colors.indigo)
              : Colors.green.shade600,
          size: 40,
        ),
        title: Text(
          "من ${booking.departureStation} إلى ${booking.arrivalStation}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "المسار: ${booking.line} | المقعد: ${booking.seat} ($seatTypeDisplay)\nالوقت: $formattedTime",
          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          textDirection: ui.TextDirection.rtl,
        ),
        isThreeLine: true,
        trailing: widget.enableEdit
            ? const Icon(Icons.arrow_forward_ios, size: 18)
            : Text(
                "T#${booking.ticketId}",
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey),
              ),
        onTap: () {
          if (widget.enableEdit) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditBookingDetailPage(
                    booking: booking, employeeName: widget.employeeName),
              ),
            );
          } else if (isActive) {
            if (widget.employeeName == "N/A") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketQrPagePassenger(
                    ticketId: booking.ticketId.toString(),
                    userName: widget.passengerName,
                    bookingTime: booking.time,
                    seatType: seatTypeDisplay,
                    line: booking.line,
                    departure: booking.departureStation,
                    arrival: booking.arrivalStation,
                    seatNumber: booking.seat,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketQrPage(
                    ticketId: booking.ticketId.toString(),
                    userName: widget.passengerName,
                    bookingTime: booking.time,
                    seatType: seatTypeDisplay,
                    line: booking.line,
                    departure: booking.departureStation,
                    arrival: booking.arrivalStation,
                    seatNumber: booking.seat,
                    employeeName: widget.employeeName,
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Booking>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 50),
                const SizedBox(height: 10),
                Text(
                  "حدث خطأ أثناء جلب الحجوزات:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("إعادة المحاولة"),
                  onPressed: _refreshBookings,
                )
              ],
            ),
          ));
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt_outlined,
                    size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                Text(
                  widget.endpoint == '/active_bookings'
                      ? 'لا توجد حجوزات فعالة حالياً.'
                      : 'لا توجد حجوزات منتهية.',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshBookings,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              bool isActive =
                  widget.endpoint == '/active_bookings' || widget.enableEdit;
              return _buildBookingTile(context, booking, isActive);
            },
          ),
        );
      },
    );
  }
}

class ActiveBookingsPage extends StatelessWidget {
  final String passengerName;
  const ActiveBookingsPage({required this.passengerName});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("الحجوزات الفعالة")),
        body: _BookingsList(
          passengerName: passengerName,
          endpoint: '/active_bookings',
          employeeName: "N/A",
        ),
      ),
    );
  }
}

class CompletedBookingsPage extends StatelessWidget {
  final String passengerName;
  const CompletedBookingsPage({required this.passengerName});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("الحجوزات المنتهية")),
        body: _BookingsList(
          passengerName: passengerName,
          endpoint: '/completed_bookings',
          employeeName: "N/A",
        ),
      ),
    );
  }
}

class EditBookingSearchPage extends StatefulWidget {
  final String employeeName;
  const EditBookingSearchPage({required this.employeeName, super.key});

  @override
  State<EditBookingSearchPage> createState() => _EditBookingSearchPageState();
}

class _EditBookingSearchPageState extends State<EditBookingSearchPage> {
  final TextEditingController _idController = TextEditingController();
  bool _isLoading = false;

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  Future<void> fetchBookingsForEdit() async {
    final passengerId = _idController.text.trim();
    if (passengerId.isEmpty) {
      _showMessage("الرجاء إدخال رقم هوية الراكب", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("$backendUrl/bookings/active/$passengerId"),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        final List<dynamic> rawBookings = body["bookings"] ?? [];

        if (rawBookings.isEmpty) {
          _showMessage("لا توجد حجوزات فعالة لهذا الراكب", Colors.orange);
          return;
        }

        final List<Booking> bookings =
            rawBookings.map((item) => Booking.fromJson(item)).toList();

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EditBookingListPage(
                    passengerId: passengerId,
                    bookings: bookings,
                    employeeName: widget.employeeName)),
          );
        }
      } else {
        final message = body["message"] ?? "فشل في جلب بيانات الحجوزات";
        _showMessage(message, Colors.redAccent);
      }
    } catch (e) {
      _showMessage("خطأ في الاتصال بالخادم: $e", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("تعديل حجز - بحث")),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "يرجى إدخال رقم هوية أو إقامة الراكب لعرض حجوزاته الفعالة:",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _idController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "رقم هوية الراكب",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : fetchBookingsForEdit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search),
                label: Text(_isLoading ? "جاري البحث..." : "البحث عن الحجوزات"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditBookingListPage extends StatelessWidget {
  final String passengerId;
  final String employeeName;
  final List<Booking> bookings;

  const EditBookingListPage(
      {required this.passengerId,
      required this.bookings,
      required this.employeeName,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("اختيار الحجز للتعديل")),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "الراكب ذو الهوية: $passengerId\nلديه ${bookings.length} حجوزات فعالة. اختر الحجز المراد تعديله:",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: _BookingsList(
                passengerName: "N/A",
                endpoint: '/active_bookings',
                enableEdit: true,
                initialBookings: bookings,
                employeeName: employeeName,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditBookingDetailPage extends StatefulWidget {
  final Booking booking;
  final String employeeName;

  const EditBookingDetailPage(
      {required this.booking, required this.employeeName, super.key});

  @override
  State<EditBookingDetailPage> createState() => _EditBookingDetailPageState();
}

class _EditBookingDetailPageState extends State<EditBookingDetailPage> {
  late String? selectedLine;
  late String? selectedDepartureStation;
  late String? selectedArrivalStation;
  late String? selectedTime;
  late String selectedOldSeat;
  late String? selectedNewSeat;

  List<String> timeSlots = [];
  bool _isLoading = false;
  final ValueNotifier<bool> _isUpdatingNotifier = ValueNotifier(false);

  // خريطة المقاعد
  final Map<String, Map<String, dynamic>> _seatsStatus = {
    'S1': {'isBooked': false, 'type': 'Single'},
    'S2': {'isBooked': false, 'type': 'Single'},
    'S3': {'isBooked': false, 'type': 'Single'},
    'S4': {'isBooked': false, 'type': 'Single'},
    'S5': {'isBooked': false, 'type': 'Single'},
    'S6': {'isBooked': false, 'type': 'Single'},
    'S7': {'isBooked': false, 'type': 'Single'},
    'S8': {'isBooked': false, 'type': 'Single'},
    'S9': {'isBooked': false, 'type': 'Single'},
    'S10': {'isBooked': false, 'type': 'Single'},
    'S11': {'isBooked': false, 'type': 'Single'},
    'S12': {'isBooked': false, 'type': 'Single'},
    'S13': {'isBooked': false, 'type': 'Single'},
    'S14': {'isBooked': false, 'type': 'Single'},
    'S15': {'isBooked': false, 'type': 'Single'},
    'S16': {'isBooked': false, 'type': 'Single'},
    'S17': {'isBooked': false, 'type': 'Single'},
    'S18': {'isBooked': false, 'type': 'Single'},
    'S19': {'isBooked': false, 'type': 'Single'},
    'S20': {'isBooked': false, 'type': 'Single'},
    'S21': {'isBooked': false, 'type': 'Single'},
    'S22': {'isBooked': false, 'type': 'Single'},
    'S23': {'isBooked': false, 'type': 'Single'},
    'S24': {'isBooked': false, 'type': 'Single'},
    'S25': {'isBooked': false, 'type': 'Single'},
    'S26': {'isBooked': false, 'type': 'Single'},
    'S27': {'isBooked': false, 'type': 'Single'},
    'S28': {'isBooked': false, 'type': 'Single'},
    'S29': {'isBooked': false, 'type': 'Single'},
    'S30': {'isBooked': false, 'type': 'Single'},
    'S31': {'isBooked': false, 'type': 'Single'},
    'S32': {'isBooked': false, 'type': 'Single'},
  };

  final Map<String, List<String>> metroStations = {
    'المسار الأزرق': [
      'SABB',
      'Dr Sulaiman Al-Habib',
      'Al-Shabab Club Stadium',
      'KAFD',
      'Al-Murooj',
      'King Fahad District',
      'King Fahad District 2',
      'STC',
      'Al-Wurud 2',
      'Al-Urubah',
      'Bank Albilad',
      'King Fahad Library',
      'Ministry of Interior',
      'Al-Murabba',
      'Passport Department',
      'National Museum',
      'Al-Bat’ha',
      'Qasr Al-Hokm',
      'Al-Owd',
      'Skirinah',
      'Manfouhah',
      'Al-Iman Hospital',
      'Transportation Center',
      'Al-Aziziah',
      'Ad Dar Al-Baida',
    ],
    'المسار الأحمر': [
      'King Saud University Station',
      'King Salman Oasis',
      'KACST',
      'At Takhassusi',
      'STC',
      'Al-Wurud',
      'King Abdulaziz Road',
      'Ministry of Education',
      'An Nuzhah',
      'Riyadh Exhibition Center',
      'Khalid Bin Alwaleed Road',
      'Al-Hamra',
      'Al-Khaleej',
      'City Centre Ishbiliyah',
      'King Fahd Sports City Station',
    ],
    'المسار البرتقالي': [
      'Jeddah Road',
      'Tuwaiq',
      'Ad Douh',
      'Western Station',
      'Aishah bint Abi Bakr Street',
      'Dhahrat Al-Badiah',
      'Sultanah',
      'Al-Jarradiyah',
      'Courts Complex',
      'Qasr Al-Hokm',
      'Al-Hilla',
      'Al-Margab',
      'As Salhiyah',
      'First Industrial City',
      'Railway Station',
      'Al-Malaz',
      'Jarir District',
      'Al-Rajhi Grand Mosque',
      'Harun Ar Rashid Road',
      'An Naseem',
      'Khashm Al-An',
    ],
    'المسار الأصفر': [
      'Airport T1-2',
      'Airport T3',
      'Airport T4',
      'Airport T5',
      'KAFD'
    ],
    'المسار الأخضر': ['Ministry of Education', 'National Museum'],
    'المسار البنفسجي': ['KAFD', 'An Naseem'],
  };
  final List<String> metroLines = [
    'المسار الأزرق',
    'المسار الأحمر',
    'المسار البرتقالي',
    'المسار الأصفر',
    'المسار الأخضر',
    'المسار البنفسجي',
  ];

  @override
  void initState() {
    super.initState();
    selectedLine = widget.booking.line.trim();
    selectedDepartureStation = widget.booking.departureStation.trim();
    selectedArrivalStation = widget.booking.arrivalStation.trim();
    selectedTime = widget.booking.time.trim();
    selectedOldSeat = widget.booking.seat.trim();
    selectedNewSeat = widget.booking.seat.trim();
    loadTimeSlots();
  }

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  List<DropdownMenuItem<String>> _buildStationItems(String? line) {
    if (line == null || !metroStations.containsKey(line)) return [];
    // تقليص العرض لمنع الأخطاء حتى في الوضع العمودي (احتياط)
    final double widthAvailable = MediaQuery.of(context).size.width - 100;
    return (metroStations[line] ?? [])
        .map((station) => DropdownMenuItem(
              value: station,
              child: SizedBox(
                width: widthAvailable,
                child: Text(station,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13)),
              ),
            ))
        .toList();
  }

  Future<void> loadTimeSlots() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await http
          .get(Uri.parse("$backendUrl/times?interval_minutes=5"))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        List<String> fetchedTimes = List<String>.from(jsonDecode(res.body));
        final now = DateTime.now();

        fetchedTimes = fetchedTimes.where((timeString) {
          try {
            final slotTime = DateTime.parse(timeString);
            bool isFuture = slotTime.isAfter(now);
            bool isOperatingHours = slotTime.hour >= 5;
            // في التعديل: نعرض الوقت إذا كان (مستقبل + تشغيل) أو (هو نفس وقت الحجز الحالي)
            return (isFuture && isOperatingHours) ||
                timeString == widget.booking.time.trim();
          } catch (e) {
            return false;
          }
        }).toList();

        setState(() {
          timeSlots = fetchedTimes;
          // التحقق من أن الوقت المختار ما زال موجوداً
          if (!timeSlots.contains(selectedTime)) {
            if (timeSlots.contains(widget.booking.time.trim())) {
              selectedTime = widget.booking.time.trim();
            } else {
              selectedTime = null;
              selectedNewSeat = null;
            }
          }
        });

        if (selectedTime != null &&
            selectedLine != null &&
            selectedDepartureStation != null &&
            selectedArrivalStation != null) {
          await fetchSeatStatus(selectedTime!);
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _showMessage("فشل في جلب الأوقات المتاحة", Colors.red);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showMessage("خطأ في الاتصال: ${e.toString()}", Colors.red);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchSeatStatus(String time) async {
    if (selectedLine == null ||
        selectedDepartureStation == null ||
        selectedArrivalStation == null) return;

    setState(() {
      _isLoading = true;
      _seatsStatus.forEach((key, value) {
        value['isBooked'] = false;
      });
    });

    try {
      String currentSeatType = widget.booking.isVip
          ? "VIP"
          : (widget.booking.seat.startsWith('F') ? "Family" : "Single");

      final response = await http
          .post(
            Uri.parse(
                "$backendUrl/booked_seats/status?exclude_ticket_id=${widget.booking.ticketId}"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "line": selectedLine,
              "departure_station": selectedDepartureStation,
              "arrival_station": selectedArrivalStation,
              "time_slot": time,
              "seat_type": currentSeatType,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> bookedSeats =
            jsonDecode(response.body)['booked_seats'] ?? [];
        setState(() {
          for (var seatNumber in bookedSeats) {
            _seatsStatus[seatNumber]!['isBooked'] = true;
          }
          if (time != widget.booking.time.trim() ||
              selectedOldSeat != selectedNewSeat) {
            if (bookedSeats.contains(selectedOldSeat)) {
              selectedNewSeat = null;
            }
          }
          _isLoading = false;
        });
      } else {
        final body = jsonDecode(response.body);
        _showMessage(body["message"] ?? "فشل في جلب حالة المقاعد", Colors.red);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showMessage("خطأ في الاتصال: ${e.toString()}", Colors.red);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updateBooking() async {
    if (_isUpdatingNotifier.value) return;
    _isUpdatingNotifier.value = true;
    FocusScope.of(context).unfocus();

    if (selectedNewSeat == null ||
        selectedTime == null ||
        selectedLine == null ||
        selectedDepartureStation == null ||
        selectedArrivalStation == null) {
      _showMessage(
          "الرجاء اختيار جميع تفاصيل الحجز والمقعد الجديد.", Colors.redAccent);
      _isUpdatingNotifier.value = false;
      return;
    }

    if (selectedDepartureStation == selectedArrivalStation) {
      _showMessage(
          "محطة المغادرة والوصول يجب أن تكونا مختلفتين.", Colors.redAccent);
      _isUpdatingNotifier.value = false;
      return;
    }

    if (selectedNewSeat != selectedOldSeat &&
        _seatsStatus[selectedNewSeat]?['isBooked'] == true) {
      _showMessage("المقعد الجديد محجوز بالفعل!", Colors.redAccent);
      _isUpdatingNotifier.value = false;
      return;
    }

    try {
      final res = await http
          .post(
            Uri.parse("$backendUrl/booking/update/${widget.booking.ticketId}"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "line": selectedLine,
              "departure_station": selectedDepartureStation,
              "arrival_station": selectedArrivalStation,
              "time": selectedTime,
              "new_seat_number": selectedNewSeat,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(res.body);

      if (res.statusCode == 200 && body["success"] == true) {
        if (mounted) {
          _showMessage(body["message"] ?? "تم التعديل بنجاح ✅", Colors.green);
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => EmployeeHomePage(name: widget.employeeName)),
              (route) => false);
        }
      } else {
        _showMessage(body["message"] ?? "فشل التعديل.", Colors.redAccent);
      }
    } catch (e) {
      _showMessage("خطأ أثناء التعديل: ${e.toString()}", Colors.red);
    } finally {
      _isUpdatingNotifier.value = false;
    }
  }

  void _onSelectionChanged(String? val, bool isTime) {
    setState(() {
      if (isTime) {
        selectedTime = val;
      } else if (selectedLine != null &&
          selectedDepartureStation != null &&
          selectedArrivalStation != null) {
        selectedNewSeat = selectedOldSeat;
      }
    });

    if (selectedTime != null &&
        selectedLine != null &&
        selectedDepartureStation != null &&
        selectedArrivalStation != null) {
      fetchSeatStatus(selectedTime!);
    } else {
      setState(() {
        _seatsStatus.forEach((key, value) {
          value['isBooked'] = false;
        });
        _isLoading = false;
      });
    }
  }

  Widget buildSeat(MapEntry<String, Map<String, dynamic>> entry) {
    final seatNumber = entry.key;
    final isBooked = entry.value['isBooked'] as bool;
    final isSelected = selectedNewSeat == seatNumber;
    final isOldSeat = selectedOldSeat == seatNumber;

    Color svgColor;
    if (isBooked && !isOldSeat) {
      svgColor = Colors.red.shade700;
    } else if (isOldSeat && !isSelected) {
      svgColor = Colors.orange.shade700;
    } else if (isSelected) {
      svgColor = Colors.blue.shade600;
    } else {
      svgColor = Colors.green; // اللون الافتراضي للمتاح
    }

    Border? seatBorder;
    if (isSelected) {
      seatBorder = Border.all(color: Colors.green.shade500, width: 3);
    } else if (isOldSeat) {
      seatBorder = Border.all(
          color: Colors.orange.shade700.withOpacity(0.5), width: 1.5);
    } else {
      seatBorder = Border.all(color: Colors.transparent, width: 3);
    }

    const double seatIconSize = 36.0;
    const double width = 60.0;

    return InkWell(
      onTap: (isBooked && !isOldSeat)
          ? null
          : () {
              setState(() {
                selectedNewSeat = isSelected ? null : seatNumber;
              });
            },
      child: SizedBox(
        width: width,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8), border: seatBorder),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(seatNumber,
                  style: TextStyle(
                      color: svgColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 2),
              SvgPicture.asset('assets/seat_icon.svg',
                  width: seatIconSize,
                  height: seatIconSize,
                  colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn)),
              if (isSelected && selectedNewSeat != selectedOldSeat)
                Text("جديد",
                    style: TextStyle(
                        color: svgColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              if (isOldSeat && !isSelected)
                Text("أصلي", style: TextStyle(color: svgColor, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildSeatRows() {
    final allSeats = _seatsStatus.entries.toList();
    List<Widget> rows = [];
    const List<List<String?>> finalLayout = [
      ['S1', null, null, 'S17'],
      ['S2', null, null, 'S18'],
      [null, null, 'Divider', null, null],
      ['S3', null, 'S19', 'S20'],
      ['S5', null, 'S21', 'S22'],
      ['S7', null, 'S23', 'S24'],
      ['S9', null, 'S25', 'S26'],
      [null, null, 'Divider', null, null],
      ['S11', null, 'S27', 'S28'],
      ['S13', null, 'S29', 'S30'],
      ['S15', null, 'S31', 'S32'],
      ['S4', null, 'S6', 'S8'],
      [null, null, 'Divider', null, null],
      ['S20', null, null, 'S24'],
      ['S22', null, null, 'S26'],
    ];
    Map<String, MapEntry<String, Map<String, dynamic>>> seatMap = {
      for (var entry in allSeats) entry.key: entry
    };

    for (var rowDefinition in finalLayout) {
      if (rowDefinition.length == 5 && rowDefinition[2] == 'Divider') {
        rows.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0),
            child: Divider(thickness: 2, color: Colors.grey)));
        continue;
      }
      List<Widget> seatsInRow = [];
      for (int i = 0; i < rowDefinition.length; i++) {
        final seatKey = rowDefinition[i];
        if (seatKey == null) {
          seatsInRow.add(SizedBox(width: i == 2 ? 40.0 : 10.0));
          continue;
        }
        final seatKeys = seatKey.split(',');
        if (seatKeys.length > 1) {
          seatsInRow.add(Row(
              mainAxisSize: MainAxisSize.min,
              children: seatKeys.map((id) {
                final entry = seatMap[id.trim()] ??
                    allSeats.firstWhere((e) => e.key == id.trim(),
                        orElse: () => MapEntry(
                            id.trim(), {'isBooked': true, 'type': 'Single'}));
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: buildSeat(entry));
              }).toList()));
        } else {
          final entry = seatMap[seatKey.trim()] ??
              allSeats.firstWhere((e) => e.key == seatKey.trim(),
                  orElse: () => MapEntry(
                      seatKey.trim(), {'isBooked': true, 'type': 'Single'}));
          seatsInRow.add(buildSeat(entry));
        }
      }
      rows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: seatsInRow)));
    }
    return rows;
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(children: [
      Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 14)),
    ]);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text("تعديل الحجز #${widget.booking.ticketId}")),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            key: ValueKey(widget.booking.ticketId),
            children: [
              Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(Icons.event_seat, color: Colors.orange),
                  title: const Text("المقعد المحجوز حالياً:"),
                  trailing: Text(
                      "$selectedOldSeat (${widget.booking.isVip ? 'VIP' : (widget.booking.seat.startsWith('F') ? 'Family' : 'Single')})",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                key: ValueKey('line_${selectedLine ?? 'init'}'),
                value: selectedLine,
                decoration: InputDecoration(
                    labelText: "المسار الحالي",
                    prefixIcon: Icon(Icons.route,
                        color: Theme.of(context).primaryColor)),
                items: metroLines
                    .map((line) =>
                        DropdownMenuItem(value: line, child: Text(line)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedLine = val;
                    selectedDepartureStation = null;
                    selectedArrivalStation = null;
                  });
                  _onSelectionChanged(val, false);
                },
                isExpanded: true,
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                key: ValueKey('departure_${selectedLine ?? 'init'}'),
                value: selectedDepartureStation,
                decoration: InputDecoration(
                    labelText: "محطة المغادرة الحالية",
                    prefixIcon: Icon(Icons.departure_board,
                        color: Theme.of(context).primaryColor)),
                items: selectedLine != null
                    ? _buildStationItems(selectedLine)
                    : [],
                onChanged: (val) {
                  setState(() {
                    selectedDepartureStation = val;
                  });
                  _onSelectionChanged(val, false);
                },
                isExpanded: true,
                validator: (value) =>
                    value == null ? 'الرجاء اختيار محطة المغادرة' : null,
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                key: ValueKey('arrival_${selectedLine ?? 'init'}'),
                value: selectedArrivalStation,
                decoration: InputDecoration(
                    labelText: "محطة الوصول الحالية",
                    prefixIcon: Icon(Icons.pin_drop,
                        color: Theme.of(context).primaryColor)),
                items: selectedLine != null
                    ? _buildStationItems(selectedLine)
                    : [],
                onChanged: (val) {
                  setState(() {
                    selectedArrivalStation = val;
                  });
                  _onSelectionChanged(val, false);
                },
                isExpanded: true,
                validator: (value) =>
                    value == null ? 'الرجاء اختيار محطة الوصول' : null,
              ),
              const SizedBox(height: 20),

              if (_isLoading && timeSlots.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  key: ValueKey('time_${selectedTime ?? 'init'}'),
                  value: timeSlots.contains(selectedTime) ? selectedTime : null,
                  decoration: InputDecoration(
                      labelText: "وقت الرحلة الحالي",
                      prefixIcon: Icon(Icons.access_time,
                          color: Theme.of(context).primaryColor)),
                  items: timeSlots.map((time) {
                    String formattedTime = time;
                    try {
                      formattedTime =
                          DateFormat('yyyy/MM/dd - hh:mm a', 'ar_SA')
                              .format(DateTime.parse(time));
                    } catch (e) {}
                    return DropdownMenuItem(
                        value: time, child: Text(formattedTime));
                  }).toList(),
                  onChanged: (val) {
                    _onSelectionChanged(val, true);
                  },
                  isExpanded: true,
                ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: (selectedLine == null ||
                        selectedDepartureStation == null ||
                        selectedArrivalStation == null ||
                        selectedTime == null ||
                        _isLoading)
                    ? null
                    : () =>
                        fetchSeatStatus(selectedTime!), // استدعاء دالة الجلب
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label:
                    Text(_isLoading ? "جاري التحديث..." : "تحديث حالة المقاعد"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // لون مميز للزر
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 30),

              const Text("اختيار المقعد البديل:",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.green, "متاح"),
                  const SizedBox(width: 15),
                  _buildLegendItem(Colors.red.shade700, "محجوز"),
                  const SizedBox(width: 15),
                  _buildLegendItem(Colors.orange.shade700, "المقعد الأصلي"),
                ],
              ),
              const SizedBox(height: 15),

              // عرض الخريطة
              Column(children: buildSeatRows()),

              const SizedBox(height: 40),

              ValueListenableBuilder<bool>(
                valueListenable: _isUpdatingNotifier,
                builder: (context, isUpdating, child) {
                  return ElevatedButton.icon(
                    icon: isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)))
                        : const Icon(Icons.check_circle_outline),
                    label:
                        Text(isUpdating ? "جاري التحديث..." : "تأكيد التعديل"),
                    onPressed: (selectedNewSeat == null ||
                            selectedTime == null ||
                            isUpdating)
                        ? null
                        : updateBooking,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        minimumSize: const Size.fromHeight(50)),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("إلغاء والعودة للقائمة")),
            ],
          ),
        ),
      ),
    );
  }
}
