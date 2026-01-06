// metro_ui_design.dart
import 'package:flutter/material.dart';

// ====================================================================
// 1. الثوابت والألوان
// ====================================================================

// لوحة الألوان مستوحاة من هدوء الصحراء والحداثة العمرانية للرياض
const Color primaryColor =
    Color(0xFF047857); // أخضر زمردي عميق - للعمليات الرئيسية
const Color accentColor =
    Color(0xFF4F46E5); // أزرق نيلي - للتفاصيل والعلامة التجارية
const Color surfaceColor = Color(0xFFFFFFFF); // خلفية العناصر البيضاء
const Color backgroundColor = Color(0xFFF0F4F8); // خلفية الصفحة الفاتحة جداً
const Color successColor = Color(0xFF10B981); // للأوامر المكتملة

void main() {
  runApp(const RiyadhMetroBookingApp());
}

// ====================================================================
// 2. كلاس الواجهات الاحترافية (RiyadhMetroUI Class)
// يمثل مكتبة مكونات UI/UX موحدة وقابلة لإعادة الاستخدام.
// ====================================================================

class RiyadhMetroUI {
  // ------------------------------------------------------------------
  // 2.1. حاوية رئيسية أنيقة (ModernContainer)
  // تستخدم لتغليف الأقسام الرئيسية في الشاشات.
  // ------------------------------------------------------------------
  static Widget ModernContainer({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(24),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20), // زوايا كبيرة ومريحة
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------------
  // 2.2. زر الإجراءات الأساسية (ElevatedPrimaryButton)
  // يتميز بظلال قوية وتأثيرات جذابة.
  // ------------------------------------------------------------------
  static Widget ElevatedPrimaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = primaryColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize:
            const Size(double.infinity, 60), // ارتفاع أكبر لسهولة الضغط
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // زوايا أكثر استدارة
        ),
        elevation: 10, // ظلال أعمق
        shadowColor: color.withOpacity(0.4),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        text,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
    );
  }

  // ------------------------------------------------------------------
  // 2.3. حقل إدخال مُحسن (EnhancedInputFormField)
  // تصميم Material 3 مُعبأ وخفيف.
  // ------------------------------------------------------------------
  static Widget EnhancedInputFormField({
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      textAlign: TextAlign.right,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 18, color: Colors.black87),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Icon(icon, color: accentColor, size: 28),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: backgroundColor, // لون تعبئة خفيف للخلفية
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentColor, width: 2.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      ),
    );
  }

  // ------------------------------------------------------------------
  // 2.4. بيانات موجزة (InfoTile)
  // لعرض معلومات مفردة بتصميم واضح وجذاب.
  // ------------------------------------------------------------------
  static Widget InfoTile({
    required String title,
    required String value,
    required IconData icon,
    Color color = accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// 3. التطبيق الرئيسي (RiyadhMetroBookingApp)
// لم يتم التعديل على هذا القسم
// ====================================================================

class RiyadhMetroBookingApp extends StatelessWidget {
  const RiyadhMetroBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حجز مترو الرياض',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: backgroundColor,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          elevation: 0,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

// ====================================================================
// 4. شاشة المصادقة (AuthScreen) - تم تحديثها لاستخدام RiyadhMetroUI
// ====================================================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isElderly = true;
  String? idNumber;

  void _navigateToBooking(BuildContext context) {
    // تحقق بسيط من الهوية (10 أرقام)
    if (idNumber != null && idNumber!.length >= 10) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BookingScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال رقم هوية صحيح (10 أرقام).'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              child: RiyadhMetroUI.ModernContainer(
                // استخدام الحاوية الأنيقة
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      isElderly
                          ? Icons.elderly_rounded
                          : Icons.accessible_forward_rounded,
                      size: 80,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'بوابة دخول خدمة الدعم',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildCategoryToggle(),
                    const SizedBox(height: 30),

                    // استخدام حقل الإدخال المُحسن من RiyadhMetroUI
                    RiyadhMetroUI.EnhancedInputFormField(
                      labelText: 'رقم الهوية الوطنية/الإقامة',
                      icon: Icons.credit_card,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => idNumber = value,
                    ),
                    const SizedBox(height: 40),

                    // استخدام زر الإجراءات الأساسية من RiyadhMetroUI
                    RiyadhMetroUI.ElevatedPrimaryButton(
                      text: 'متابعة الحجز',
                      icon: Icons.arrow_forward_ios_rounded,
                      onPressed: () => _navigateToBooking(context),
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // بناء أزرار التبديل (Chips) بشكل احترافي
  Widget _buildCategoryToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _toggleChip(
              title: 'ذوي الاحتياجات الخاصة',
              isSelected: !isElderly,
              onTap: () => setState(() => isElderly = false),
            ),
          ),
          Expanded(
            child: _toggleChip(
              title: 'كبار السن',
              isSelected: isElderly,
              onTap: () => setState(() => isElderly = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// 5. شاشة الحجز (BookingScreen) - تم تحديثها لاستخدام RiyadhMetroUI
// ====================================================================

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? fromStation;
  String? toStation;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final List<String> metroStations = const [
    'محطة طريق الملك عبد الله',
    'محطة العليا',
    'محطة المركز المالي',
    'محطة جامعة الملك سعود',
    'محطة المطار',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 90)),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                onSurface: Colors.black87,
              ),
            ),
            child:
                Directionality(textDirection: TextDirection.rtl, child: child!),
          );
        });
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                onSurface: Colors.black87,
              ),
            ),
            child:
                Directionality(textDirection: TextDirection.rtl, child: child!),
          );
        });
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _confirmBooking() {
    if (fromStation != null && toStation != null && fromStation != toStation) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TicketScreen(
            from: fromStation!,
            to: toStation!,
            date: selectedDate,
            time: selectedTime,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار محطتي الانطلاق والوصول بشكل صحيح.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجز المقعد المخصص'),
        backgroundColor: primaryColor,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تحديد رحلتك',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 30),

              RiyadhMetroUI.ModernContainer(
                child: _buildStationPicker(),
              ),
              const SizedBox(height: 30),

              _buildDateTimePickers(context),
              const SizedBox(height: 40),

              // استخدام زر الإجراءات الأساسية من RiyadhMetroUI
              RiyadhMetroUI.ElevatedPrimaryButton(
                text: 'تأكيد الحجز والحصول على التذكرة',
                icon: Icons.confirmation_num_rounded,
                onPressed: _confirmBooking,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationPicker() {
    return Column(
      children: [
        _buildDropdown(
          value: fromStation,
          hint: 'محطة الانطلاق (من)',
          icon: Icons.location_on_rounded,
          onChanged: (String? newValue) {
            setState(() => fromStation = newValue);
          },
          items: metroStations,
          iconColor: successColor,
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          value: toStation,
          hint: 'محطة الوصول (إلى)',
          icon: Icons.location_on_rounded,
          onChanged: (String? newValue) {
            setState(() => toStation = newValue);
          },
          items: metroStations,
          iconColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    String? value,
    required String hint,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    required List<String> items,
    required Color iconColor,
  }) {
    // استخدام تصميم RiyadhMetroUI.EnhancedInputFormField للديكوريشن
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: iconColor),
      onChanged: onChanged,
      items: items.map<DropdownMenuItem<String>>((String val) {
        return DropdownMenuItem<String>(
          value: val,
          child: Text(val, style: const TextStyle(fontSize: 16)),
        );
      }).toList(),
      decoration: InputDecoration(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        filled: true,
        fillColor: backgroundColor,
        labelText: hint,
        prefixIcon: Icon(icon, color: iconColor),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: iconColor, width: 2.5),
        ),
      ),
    );
  }

  Widget _buildDateTimePickers(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context),
            // استخدام InfoTile من RiyadhMetroUI
            child: RiyadhMetroUI.InfoTile(
              title: 'تاريخ الرحلة',
              value:
                  '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
              icon: Icons.calendar_month_rounded,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(context),
            // استخدام InfoTile من RiyadhMetroUI
            child: RiyadhMetroUI.InfoTile(
              title: 'وقت المغادرة',
              value: selectedTime.format(context),
              icon: Icons.schedule_rounded,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ====================================================================
// 6. شاشة التذكرة (TicketScreen) - تم تحديثها لاستخدام RiyadhMetroUI
// ====================================================================

class TicketScreen extends StatelessWidget {
  final String from;
  final String to;
  final DateTime date;
  final TimeOfDay time;
  final String bookingId =
      'MTR-KSA-${DateTime.now().millisecondsSinceEpoch % 10000}';

  TicketScreen({
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    super.key,
  });

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد الحجز والتذكرة'),
        backgroundColor: successColor,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.verified_rounded, size: 80, color: successColor),
              const SizedBox(height: 16),
              const Text(
                'تم تأكيد حجزك بنجاح!',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: successColor),
              ),
              const SizedBox(height: 30),

              _buildTicketCard(context),
              const SizedBox(height: 40),

              // استخدام زر الإجراءات الأساسية من RiyadhMetroUI
              RiyadhMetroUI.ElevatedPrimaryButton(
                text: 'العودة للرئيسية',
                icon: Icons.home_rounded,
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context) {
    return RiyadhMetroUI.ModernContainer(
      // حاوية التذكرة من RiyadhMetroUI
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // استخدام InfoTile من RiyadhMetroUI
                RiyadhMetroUI.InfoTile(
                    title: 'من:',
                    value: from,
                    icon: Icons.transit_enterexit,
                    color: primaryColor),
                const SizedBox(height: 10),
                RiyadhMetroUI.InfoTile(
                    title: 'إلى:',
                    value: to,
                    icon: Icons.location_on_rounded,
                    color: accentColor),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: RiyadhMetroUI.InfoTile(
                          title: 'التاريخ',
                          value: _formatDate(date),
                          icon: Icons.date_range,
                          color: Colors.amber.shade700),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RiyadhMetroUI.InfoTile(
                          title: 'الوقت',
                          value: time.format(context),
                          icon: Icons.access_time,
                          color: Colors.blue.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                RiyadhMetroUI.InfoTile(
                    title: 'رقم الحجز',
                    value: bookingId,
                    icon: Icons.confirmation_number,
                    color: Colors.red.shade700),
              ],
            ),
          ),

          _buildDashedDivider(), // فاصل تذكرة

          // رمز الاستجابة السريعة (QR Code) - محاكاة
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(Icons.qr_code_2_rounded,
                        size: 100, color: Colors.grey[500]),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'امسح الرمز عند بوابة الدخول لتأكيد تخصيص المقعد',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  'المقعد المخصص في العربة الأولى (قسم الدعم)',
                  style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // فاصل منقط لمحاكاة تذكرة
  Widget _buildDashedDivider() {
    return Container(
      height: 20,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: backgroundColor),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const dashWidth = 10.0;
          const dashSpace = 8.0;
          final count =
              (constraints.maxWidth / (dashWidth + dashSpace)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(count, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.grey[300]),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
