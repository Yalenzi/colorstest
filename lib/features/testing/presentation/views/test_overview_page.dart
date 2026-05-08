import 'package:flutter/material.dart';
import '../../data/models/reagent_model.dart';
import 'test_execution_page.dart';

class TestOverviewPage extends StatefulWidget {
  final ReagentModel reagent;

  const TestOverviewPage({super.key, required this.reagent});

  @override
  State<TestOverviewPage> createState() => _TestOverviewPageState();
}

class _TestOverviewPageState extends State<TestOverviewPage> {
  bool _isSafetyAcknowledged = false;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final r = widget.reagent;
    final rName = (isArabic && r.nameAr.isNotEmpty) ? r.nameAr : r.name;
    final rDesc = (isArabic && r.descriptionAr.isNotEmpty) ? r.descriptionAr : r.description;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'نظرة عامة' : 'Test Overview'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science, color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(rName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(rDesc, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SAFETY SECTION
              _buildSectionTitle(isArabic ? 'معلومات السلامة' : 'Safety Information', Icons.security),
              const SizedBox(height: 8),
              Card(
                color: Colors.red.withOpacity(0.05),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSafetyList(isArabic ? 'المعدات المطلوبة' : 'Required Equipment', Icons.shield, r.equipment),
                      _buildSafetyList(isArabic ? 'إجراءات التعامل' : 'Handling Procedures', Icons.pan_tool, r.handlingProcedures),
                      _buildSafetyList(isArabic ? 'مخاطر محددة' : 'Specific Hazards', Icons.warning_amber, r.specificHazards),
                      _buildSafetyList(isArabic ? 'التخزين' : 'Storage', Icons.inventory, r.storage),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // CHEMICAL COMPONENTS
              if (r.chemicals.isNotEmpty) ...[
                _buildSectionTitle(isArabic ? 'المكونات الكيميائية' : 'Chemical Components', Icons.science_outlined),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: r.chemicals.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.toString())),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // TEST INSTRUCTIONS PREVIEW
              _buildSectionTitle(isArabic ? 'خطوات الاختبار' : 'Test Instructions Preview', Icons.format_list_numbered),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (r.testInstructions is List && r.testInstructions.isNotEmpty)
                        Text(r.testInstructions.first.toString())
                      else
                        Text(isArabic ? 'لا توجد خطوات' : 'No instructions'),
                      const SizedBox(height: 8),
                      Text(isArabic ? '... انظر الباقي في الشاشة التالية' : '... view remaining in next screen', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // SAFETY ACKNOWLEDGEMENT
              Container(
                decoration: BoxDecoration(
                  color: _isSafetyAcknowledged ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isSafetyAcknowledged ? Colors.green : Colors.grey.withOpacity(0.3)),
                ),
                child: CheckboxListTile(
                  value: _isSafetyAcknowledged,
                  onChanged: (val) => setState(() => _isSafetyAcknowledged = val ?? false),
                  activeColor: Colors.green,
                  title: Text(
                    isArabic ? 'قرأت وفهمت جميع تعليمات السلامة' : 'I have read and understand all safety instructions',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // START TEST BUTTON
              ElevatedButton(
                onPressed: _isSafetyAcknowledged ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestExecutionPage(reagent: widget.reagent),
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  isArabic ? 'بدء الاختبار' : 'Start Test',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSafetyList(String title, IconData icon, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800])),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 26, right: 26),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.red)),
                Expanded(child: Text(e.toString(), style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
