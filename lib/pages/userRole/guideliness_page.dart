import 'package:flutter/material.dart';
import '../../utils/utils.dart';

class GuidelinesPage extends StatelessWidget {
  const GuidelinesPage({super.key});

  

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guidelines & Tips',
            style: AppStyles.headingStyle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 20),
          
          // App Usage Guide Section
          Text(
            'كيفية استخدام التطبيق',
            style: AppStyles.headingStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 10),
          const Text(
            'للاستفادة من التطبيق لحجز امتحان القيادة بسهولة، اتبع الخطوات التالية:\n'
            '- افتح التطبيق وتأكد من تسجيل الدخول باستخدام بياناتك الشخصية.\n'
            '- اختر خيار "Book Exam" من القائمة السفلية.\n'
            '- حدد نوع الامتحان (نظري أو عملي) من القائمة المنسدلة.\n'
            '- اختر مركز الاختبار المناسب من القائمة المتاحة.\n'
            '- اضغط على حقل التاريخ لتحديد يوم الامتحان باستخدام التقويم.\n'
            '- اختر وقت الامتحان المتاح من القائمة المنسدلة بعد اختيار المركز والتاريخ.\n'
            '- اضغط على "Book Now" لتأكيد الحجز، وستظهر رسالة نجاح إذا تم كل شيء بشكل صحيح.\n'
            '- تحقق من قسم "Appointments" لمراجعة الحجوزات الخاصة بك.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 30),

          // Theoretical Test Section
          Text(
            'الامتحان النظري - نصائح ومصادر',
            style: AppStyles.headingStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 10),
          const Text(
            '• نصائح للامتحان النظري:\n'
            '  - راجع جميع إشارات المرور وقواعد الطريق\n'
            '  - تدرب على الأسئلة السابقة\n'
            '  - احرص على فهم القوانين وليس حفظها فقط\n'
            '  - خذ قسطاً كافياً من النوم قبل الامتحان\n'
            '  - اقرأ الأسئلة بعناية قبل الإجابة\n\n',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            '• المستندات المطلوبة:\n'
           '  • بطاقة الهوية الشخصية سارية المفعول\n'
                    '  • تصريح تعلم القيادة\n'
                    '  • إيصال دفع رسوم الامتحان\n'
                    '  • نتيجة اجتياز الامتحان النظري\n'
                    '  • سجل التدريب العملي موقع من المدرب',
            style: TextStyle(color: Colors.white),
          ),
                    const SizedBox(height: 10),
           const Text(
            '• قبل الامتحان:\n'
            '  • تأكد من صلاحية المركبة للامتحان\n'
                    '  • راجع جميع المناورات الأساسية\n'
                    '  • تحقق من مستوى الوقود والزيت\n'
                    '  • احضر قبل موعد الامتحان بـ 30 دقيقة\n'
                    '  • تأكد من نظافة المركبة',
            style: TextStyle(color: Colors.white),
          ),
                    const SizedBox(height: 10),

           const Text(
            '• خلال الامتحان:\n'
             '  • التحقق من المرايا قبل التحرك\n'
                    '  • استخدام إشارات الانعطاف\n'
                    '  • الالتزام بحدود السرعة\n'
                    '  • الانتباه للمشاة وإشارات المرور\n'
                    '  • الحفاظ على مسافة آمنة\n'
                    '  • تنفيذ تعليمات الفاحص بدقة',
            style: TextStyle(color: Colors.white),
          ),
                    const SizedBox(height: 10),






 
       
         
        ],
      ),
    );
  }
}