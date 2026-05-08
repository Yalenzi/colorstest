import 'package:flutter/material.dart';
import '../../data/models/reagent_model.dart';
import 'test_result_page.dart';

class TestDetailsFlowPage extends StatefulWidget {
  final ReagentModel reagent;

  const TestDetailsFlowPage({super.key, required this.reagent});

  @override
  State<TestDetailsFlowPage> createState() => _TestDetailsFlowPageState();
}

class _TestDetailsFlowPageState extends State<TestDetailsFlowPage> {
  bool _isSafetyAcknowledged = false;
  Map<String, dynamic>? _selectedResult;
  final TextEditingController _notesController = TextEditingController();

  Color _parseColor(String colorStr) {
    final s = colorStr.toLowerCase();
    if (s.contains('red') || s.contains('أحمر')) return Colors.red;
    if (s.contains('green') || s.contains('أخضر')) return Colors.green;
    if (s.contains('blue') || s.contains('أزرق')) return Colors.blue;
    if (s.contains('yellow') || s.contains('أصفر')) return Colors.yellow;
    if (s.contains('orange') || s.contains('برتقالي')) return Colors.orange;
    if (s.contains('purple') || s.contains('violet') || s.contains('بنفسجي')) return Colors.purple;
    if (s.contains('brown') || s.contains('بني')) return Colors.brown;
    if (s.contains('pink') || s.contains('وردي')) return Colors.pink;
    if (s.contains('black') || s.contains('أسود')) return Colors.black;
    if (s.contains('white') || s.contains('أبيض')) return Colors.grey.shade200;
    return Colors.grey;
  }

  Color _getRiskColor(String safetyLevel) {
    switch (safetyLevel.toUpperCase()) {
      case 'EXTREME': return Colors.red[900] ?? Colors.red;
      case 'HIGH': return Colors.red;
      case 'MEDIUM': return Colors.orange;
      case 'LOW': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final r = widget.reagent;
    final rName = (isArabic && r.nameAr.isNotEmpty) ? r.nameAr : r.name;
    final rDesc = (isArabic && r.descriptionAr.isNotEmpty) ? r.descriptionAr : r.description;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(rName),
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
              // HEADER CARD
              _buildHeaderCard(rName, rDesc, r.testDuration, r.safetyLevel, isArabic),
              const SizedBox(height: 24),

              // SAFETY SECTION
              _buildSectionTitle(isArabic ? 'معلومات السلامة' : 'Safety Information', Icons.security),
              _buildSafetySection(isArabic),
              const SizedBox(height: 24),

              // INSTRUCTIONS
              _buildSectionTitle(isArabic ? 'التعليمات' : 'Instructions', Icons.format_list_numbered),
              _buildInstructions(isArabic),
              const SizedBox(height: 24),

              // SAFETY ACKNOWLEDGEMENT
              _buildSafetyAcknowledgement(isArabic),
              const SizedBox(height: 32),

              // COLOR SELECTION
              _buildSectionTitle(isArabic ? 'تسجيل النتيجة' : 'Record Result', Icons.palette),
              const SizedBox(height: 8),
              Text(
                isArabic ? 'اختر اللون الذي لاحظته بناءً على التفاعل' : 'Select the observed color based on the reaction',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildColorSelection(isArabic),
              const SizedBox(height: 24),

              // SELECTED RESULT DISPLAY
              if (_selectedResult != null) _buildSelectedResult(isArabic),
              const SizedBox(height: 24),

              // NOTES
              _buildSectionTitle(isArabic ? 'ملاحظات (اختياري)' : 'Notes (Optional)', Icons.notes),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isArabic ? 'أضف ملاحظاتك هنا...' : 'Add your notes here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest ?? Colors.grey[100],
                ),
              ),
              const SizedBox(height: 32),

              // COMPLETE BUTTON
              ElevatedButton(
                onPressed: (_isSafetyAcknowledged && _selectedResult != null)
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TestResultPage(
                              reagent: widget.reagent,
                              selectedResult: _selectedResult!,
                              notes: _notesController.text,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500]
                ),
                child: Text(
                  isArabic ? 'إكمال الاختبار' : 'Complete Test',
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
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(String name, String desc, int duration, String risk, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.science, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildBadge(Icons.timer, '$duration ${isArabic ? 'دقيقة' : 'min'}', Colors.white24),
              const SizedBox(width: 12),
              _buildBadge(Icons.warning, risk, _getRiskColor(risk)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSafetySection(bool isArabic) {
    final r = widget.reagent;
    return Card(
      elevation: 0,
      color: Colors.red.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.withOpacity(0.3)),
      ),
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSafetyList(isArabic ? 'المعدات المطلوبة' : 'Required Equipment', Icons.shield, r.equipment),
            const SizedBox(height: 12),
            _buildSafetyList(isArabic ? 'إجراءات التعامل' : 'Handling Procedures', Icons.pan_tool, r.handlingProcedures),
            const SizedBox(height: 12),
            _buildSafetyList(isArabic ? 'مخاطر محددة' : 'Specific Hazards', Icons.warning_amber, r.specificHazards),
            const SizedBox(height: 12),
            _buildSafetyList(isArabic ? 'التخزين' : 'Storage', Icons.inventory, r.storage),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyList(String title, IconData icon, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
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
    );
  }

  Widget _buildInstructions(bool isArabic) {
    List<dynamic> steps = [];
    if (widget.reagent.testInstructions is List) {
      steps = widget.reagent.testInstructions;
    }

    if (steps.isEmpty) return const Padding(padding: EdgeInsets.only(top: 16), child: Text('No instructions available.'));

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: List.generate(steps.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${index + 1}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[index].toString(),
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSafetyAcknowledgement(bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: _isSafetyAcknowledged ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isSafetyAcknowledged ? Colors.green : Colors.grey.withOpacity(0.3)),
      ),
      child: CheckboxListTile(
        value: _isSafetyAcknowledged,
        onChanged: (val) {
          setState(() {
            _isSafetyAcknowledged = val ?? false;
          });
        },
        activeColor: Colors.green,
        title: Text(
          isArabic ? 'قرأت وفهمت جميع تعليمات السلامة' : 'I have read and understand all safety instructions',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildColorSelection(bool isArabic) {
    final results = widget.reagent.drugResults;
    if (results.isEmpty) return Text(isArabic ? 'لا توجد بيانات للألوان' : 'No color data available');

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: results.map((res) {
        final Map<String, dynamic> item = res as Map<String, dynamic>;
        final colorName = (isArabic && item['color_ar'] != null) ? item['color_ar'].toString() : item['color'].toString();
        final actualColor = _parseColor(colorName);
        final isSelected = _selectedResult == item;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedResult = item;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: isSelected ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: actualColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(colorName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedResult(bool isArabic) {
    final colorName = (isArabic && _selectedResult!['color_ar'] != null) 
        ? _selectedResult!['color_ar'].toString() 
        : _selectedResult!['color'].toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'اللون الملاحظ' : 'Observed Color',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(colorName, style: const TextStyle(fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
