import 'package:flutter/material.dart';
import '../../data/models/reagent_model.dart';
import '../../../../core/navigation/main_navigation_page.dart';

class TestResultPage extends StatelessWidget {
  final ReagentModel reagent;
  final Map<String, dynamic> selectedResult;
  final String notes;

  const TestResultPage({
    super.key,
    required this.reagent,
    required this.selectedResult,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final rName = (isArabic && reagent.nameAr.isNotEmpty) ? reagent.nameAr : reagent.name;
    final colorName = (isArabic && selectedResult['color_ar'] != null)
        ? selectedResult['color_ar'].toString()
        : selectedResult['color'].toString();
    
    // Confidence is a mock static percentage for now, ideally derived from logic or model.
    final double confidence = 92.5; 
    final drugName = selectedResult['drugName'] ?? 'Unknown substance';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'نتيجة الاختبار' : 'Test Result'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Result Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, color: Colors.green, size: 64),
              ),
              const SizedBox(height: 24),

              Text(
                isArabic ? 'اكتمل التحليل' : 'Analysis Complete',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                rName,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Match Card
              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        isArabic ? 'مؤشر محتمل بناءً على تفاعل اللون' : 'Possible indication based on color reaction',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        drugName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(isArabic ? 'نسبة الثقة التقديرية' : 'Estimated Confidence', '$confidence%', Colors.green),
                          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
                          _buildStatColumn(isArabic ? 'اللون الملاحظ' : 'Observed Color', colorName, Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Probabilistic disclaimer
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          isArabic
                              ? 'هذه النتائج تقديرية ولا تضمن تحديداً دقيقاً للمواد.'
                              : 'These results are estimations and do not guarantee accurate substance identification.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notes
              if (notes.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.yellow.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.note, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Text(isArabic ? 'ملاحظات' : 'Notes', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(notes),
                    ],
                  ),
                ),
              const SizedBox(height: 48),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigationPage()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isArabic ? 'العودة للرئيسية' : 'Return to Home',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, Color valueColor) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
