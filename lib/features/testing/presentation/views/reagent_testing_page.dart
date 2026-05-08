import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reagents_provider.dart';
import '../../data/models/reagent_model.dart';
import 'test_details_flow_page.dart';

class ReagentTestingPage extends ConsumerStatefulWidget {
  const ReagentTestingPage({super.key});

  @override
  ConsumerState<ReagentTestingPage> createState() => _ReagentTestingPageState();
}

class _ReagentTestingPageState extends ConsumerState<ReagentTestingPage> {
  String searchQuery = '';

  Color _getRiskColor(String safetyLevel) {
    switch (safetyLevel.toUpperCase()) {
      case 'EXTREME': return Colors.red[900] ?? Colors.red;
      case 'HIGH': return Colors.red;
      case 'MEDIUM': return Colors.orange;
      case 'LOW': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getIconForReagent(String safetyLevel) {
    switch (safetyLevel.toUpperCase()) {
      case 'EXTREME': return Icons.warning;
      case 'HIGH': return Icons.bloodtype;
      case 'MEDIUM': return Icons.science;
      case 'LOW': return Icons.check_circle_outline;
      default: return Icons.biotech;
    }
  }

  Future<void> _refreshData() async {
    // Invalidate re-triggers the provider's logic from scratch
    ref.invalidate(reagentsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final reagentsAsync = ref.watch(reagentsProvider);
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? '🧪 اختبار المواد' : '🧪 Reagent Testing'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: isArabic ? 'البحث عن كاشف...' : 'Search reagents...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest ?? Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Reagents Grid / Loading / Error states
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: reagentsAsync.when(
                    loading: () => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Fetching config from Firebase...')
                        ],
                      )
                    ),
                    error: (err, stack) => _buildErrorBanner(err, isArabic),
                    data: (reagents) {
                      final filteredReagents = reagents.where((r) {
                        final name = (isArabic && r.nameAr.isNotEmpty) ? r.nameAr : r.name;
                        return name.toLowerCase().contains(searchQuery.toLowerCase());
                      }).toList();

                      if (filteredReagents.isEmpty) {
                        return CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  isArabic ? 'لا توجد نتائج مطابقة' : 'No matching reagents found',
                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            )
                          ],
                        );
                      }

                      return GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: filteredReagents.length,
                        itemBuilder: (context, index) {
                          final test = filteredReagents[index];
                          final color = _getRiskColor(test.safetyLevel);
                          
                          final displayName = (isArabic && test.nameAr.isNotEmpty) ? test.nameAr : test.name;
                          final displayDesc = (isArabic && test.descriptionAr.isNotEmpty) ? test.descriptionAr : test.description;

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TestDetailsFlowPage(reagent: test),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Card(
                              elevation: 4,
                              shadowColor: color.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_getIconForReagent(test.safetyLevel), color: color),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      displayName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: Text(
                                        displayDesc.isEmpty ? 'No description' : displayDesc,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[700],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        test.safetyLevel,
                                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(Object error, bool isArabic) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'فشل تحميل البيانات من Remote Config' : 'Failed to fetch Data from Remote Config',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: Text(isArabic ? 'إعادة المحاولة' : 'Try Again'),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
