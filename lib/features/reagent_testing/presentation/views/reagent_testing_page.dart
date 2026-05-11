import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../domain/entities/reagent_entity.dart';

import '../providers/reagent_testing_providers.dart';
import '../states/reagent_testing_state.dart';
import '../widgets/reagent_card.dart';
import 'reagent_detail_page.dart';
import '../../../../l10n/app_localizations.dart';

class ReagentTestingPage extends ConsumerStatefulWidget {
  const ReagentTestingPage({super.key});

  @override
  ConsumerState<ReagentTestingPage> createState() => _ReagentTestingPageState();
}

class _ReagentTestingPageState extends ConsumerState<ReagentTestingPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reagentTestingControllerProvider.notifier).loadAllReagents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(reagentTestingControllerProvider);
    final controller = ref.read(reagentTestingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reagentTesting),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(HeroIcons.arrow_path),
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(controller, l10n),
          Expanded(child: _buildContent(state, controller, l10n)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(controller, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildSearchBar(controller, l10n),
    );
  }

  Widget _buildSearchBar(controller, AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: l10n.searchReagents,
        prefixIcon: Icon(HeroIcons.magnifying_glass),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(HeroIcons.x_mark),
                onPressed: () {
                  _searchController.clear();
                  controller.clearFilters();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      onChanged: (value) {
        setState(() {});
        if (value.trim().isEmpty) {
          controller.clearFilters();
        } else {
          controller.searchReagents(value);
        }
      },
    );
  }

  Widget _buildContent(
    ReagentTestingState state,
    controller,
    AppLocalizations l10n,
  ) {
    if (state is ReagentTestingInitial) {
      return _buildInitialState();
    } else if (state is ReagentTestingLoading) {
      return _buildLoadingState(l10n);
    } else if (state is ReagentTestingLoaded) {
      return _buildLoadedState(state);
    } else if (state is ReagentTestingError) {
      return _buildErrorState(state, controller, l10n);
    } else if (state is ReagentTestingEmpty) {
      return _buildEmptyState(state, controller, l10n);
    } else {
      return _buildErrorState(
        const ReagentTestingError('Unknown state'),
        controller,
        l10n,
      );
    }
  }

  Widget _buildInitialState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(HeroIcons.beaker, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Initializing reagent data...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.loadingReagents, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildLoadedState(ReagentTestingLoaded state) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(reagentTestingControllerProvider.notifier).refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: state.reagents.length,
        itemBuilder: (context, index) {
          final reagent = state.reagents[index];
          return ReagentCard(
            reagent: reagent,
            onTap: () => _navigateToDetail(context, reagent),
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, ReagentEntity reagent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReagentDetailPage(reagent: reagent),
      ),
    );
  }

  Widget _buildErrorState(
    ReagentTestingError state,
    controller,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              HeroIcons.exclamation_triangle,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingReagents,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.refresh(),
              icon: Icon(HeroIcons.arrow_path),
              label: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ReagentTestingEmpty state,
    controller,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(HeroIcons.beaker, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.noReagentsAvailable,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.unableToLoadReagentData,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.refresh(),
              icon: Icon(HeroIcons.arrow_path),
              label: Text(l10n.retryLoading),
            ),
          ],
        ),
      ),
    );
  }
}
