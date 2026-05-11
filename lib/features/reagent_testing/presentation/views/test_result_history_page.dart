import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/test_result_entity.dart';
import '../providers/reagent_testing_providers.dart';
import '../states/test_result_history_state.dart';
import '../../../../l10n/app_localizations.dart';

class TestResultHistoryPage extends ConsumerStatefulWidget {
  const TestResultHistoryPage({super.key});

  @override
  ConsumerState<TestResultHistoryPage> createState() =>
      _TestResultHistoryPageState();
}

class _TestResultHistoryPageState extends ConsumerState<TestResultHistoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedReagentFilter = '__ALL__'; // Use a constant value for "All"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load test results when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(testResultHistoryControllerProvider.notifier).loadTestResults();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(testResultHistoryControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.testHistory),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(HeroIcons.arrow_path),
            onPressed: () => ref
                .read(testResultHistoryControllerProvider.notifier)
                .loadTestResults(),
            tooltip: l10n.refresh,
          ),
          PopupMenuButton<String>(
            icon: Icon(HeroIcons.ellipsis_vertical),
            onSelected: (value) => _handleMenuAction(value, l10n),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(HeroIcons.trash, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      l10n.clearAll,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(HeroIcons.clock), text: l10n.testHistory),
            Tab(icon: Icon(HeroIcons.chart_bar), text: l10n.statistics),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(state, theme, l10n),
          _buildStatisticsTab(state, theme, l10n),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(
    TestResultHistoryState state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return state.when(
      initial: () => Center(child: Text(l10n.loading)),
      loading: () => const Center(child: CircularProgressIndicator()),
      loaded: (results) => _buildHistoryList(results, theme, l10n),
      error: (message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              HeroIcons.exclamation_triangle,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(l10n.error(message)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(testResultHistoryControllerProvider.notifier)
                  .loadTestResults(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    List<TestResultEntity> results,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              HeroIcons.clock,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noTestHistory,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noTestHistoryDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Filter results based on search and reagent filter
    final filteredResults = _filterResults(results);

    return Column(
      children: [
        _buildSearchAndFilter(theme, l10n),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredResults.length,
            itemBuilder: (context, index) {
              final result = filteredResults[index];
              return _buildResultCard(result, theme, l10n);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchBySubstanceOrNotes,
              prefixIcon: Icon(HeroIcons.magnifying_glass),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(HeroIcons.x_mark),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                HeroIcons.funnel,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(l10n.filterByReagent, style: theme.textTheme.bodyMedium),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _selectedReagentFilter,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(
                      HeroIcons.chevron_down,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    items: _getReagentFilterOptions(l10n).map((option) {
                      return DropdownMenuItem(
                        value: option.value,
                        child: Row(
                          children: [
                            if (option.value != '__ALL__') ...[
                              Icon(
                                HeroIcons.beaker,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(child: Text(option.display)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(
                        () => _selectedReagentFilter = value ?? '__ALL__',
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    TestResultEntity result,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    result.reagentName,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(result.testCompletedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  icon: Icon(HeroIcons.trash, size: 20),
                  onPressed: () => _showDeleteConfirmation(result, l10n),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  HeroIcons.swatch,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.observedColorLabel}: ${result.observedColor}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  HeroIcons.beaker,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.possibleSubstances}: ${result.possibleSubstances.join(', ')}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  HeroIcons.chart_bar_square,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.confidenceWithPercentage(
                      result.confidencePercentage.toString(),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: _getConfidenceColor(result.confidencePercentage),
                  ),
                ),
              ],
            ),
            if (result.notes != null && result.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    HeroIcons.document_text,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(
    TestResultHistoryState state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return state.when(
      initial: () => Center(child: Text(l10n.loading)),
      loading: () => const Center(child: CircularProgressIndicator()),
      loaded: (results) => _buildStatistics(results, theme, l10n),
      error: (message) => Center(child: Text(l10n.error(message))),
    );
  }

  Widget _buildStatistics(
    List<TestResultEntity> results,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (results.isEmpty) {
      return Center(child: Text(l10n.noTestResultsYet));
    }

    final controller = ref.read(testResultHistoryControllerProvider.notifier);
    final stats = controller.getStatistics();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(
            l10n.totalTests,
            stats['totalTests'].toString(),
            HeroIcons.beaker,
            theme,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            l10n.mostUsedReagent,
            stats['mostUsedReagent'],
            HeroIcons.heart,
            theme,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            l10n.averageConfidence,
            '${stats['averageConfidence'].toStringAsFixed(1)}%',
            HeroIcons.chart_bar_square,
            theme,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.testsByReagent,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildReagentBreakdown(stats['testsByReagent'], theme),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReagentBreakdown(
    Map<String, int> testsByReagent,
    ThemeData theme,
  ) {
    final total = testsByReagent.values.fold(0, (sum, count) => sum + count);

    return testsByReagent.entries.map((entry) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(entry.key, style: theme.textTheme.bodyMedium),
            ),
            Expanded(
              flex: 3,
              child: LinearProgressIndicator(
                value: entry.value / total,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${entry.value} ($percentage%)',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }).toList();
  }

  List<TestResultEntity> _filterResults(List<TestResultEntity> results) {
    var filtered = results;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((result) {
        final query = _searchQuery.toLowerCase();
        return result.possibleSubstances.any(
              (substance) => substance.toLowerCase().contains(query),
            ) ||
            (result.notes?.toLowerCase().contains(query) ?? false) ||
            result.observedColor.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by reagent - use constant value check
    if (_selectedReagentFilter != '__ALL__') {
      filtered = filtered
          .where((result) => result.reagentName == _selectedReagentFilter)
          .toList();
    }

    return filtered;
  }

  List<DropdownOption> _getReagentFilterOptions(AppLocalizations l10n) {
    final state = ref.watch(testResultHistoryControllerProvider);
    return state.maybeWhen(
      loaded: (results) {
        final reagents = results.map((r) => r.reagentName).toSet().toList()
          ..sort();
        return [
          DropdownOption(value: '__ALL__', display: l10n.all),
          ...reagents.map(
            (reagent) => DropdownOption(value: reagent, display: reagent),
          ),
        ];
      },
      orElse: () => [DropdownOption(value: '__ALL__', display: l10n.all)],
    );
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  void _handleMenuAction(String action, AppLocalizations l10n) {
    switch (action) {
      case 'clear':
        _showClearAllConfirmation(l10n);
        break;
    }
  }

  void _showDeleteConfirmation(TestResultEntity result, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTest),
        content: Text(l10n.deleteTestConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(testResultHistoryControllerProvider.notifier)
                  .deleteTestResult(result.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirmation(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllData),
        content: Text(l10n.clearAllConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(testResultHistoryControllerProvider.notifier)
                  .clearAllResults();
            },
            child: Text(
              l10n.clearAll,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for dropdown options
class DropdownOption {
  final String value;
  final String display;

  DropdownOption({required this.value, required this.display});
}
