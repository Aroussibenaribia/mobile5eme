import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/editorial_widgets.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../../models/service_category_model.dart';
import '../../../services/professional_service.dart';
import '../widgets/pro_card.dart';

class ProListScreen extends StatefulWidget {
  final String? initialCategory;
  const ProListScreen({super.key, this.initialCategory});
  @override
  State<ProListScreen> createState() => _ProListScreenState();
}

class _ProListScreenState extends State<ProListScreen> {
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    final source = context.read<ProfessionalService>();
    _search.text = source.searchQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      source.setCategory(widget.initialCategory ?? 'Tous');
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = context.watch<ProfessionalService>();
    final pros = source.filteredProfessionals;
    final categories = [
      'Tous',
      ...ServiceCategoryModel.defaultCategories.map((c) => c.title)
    ];
    return Scaffold(
        appBar: AppBar(title: const Text('Les artisans')),
        body: ContentWidth(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Le bon savoir-faire,\nau bon endroit.',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 20),
                    TextField(
                        controller: _search,
                        onChanged: source.setSearchQuery,
                        textInputAction: TextInputAction.search,
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        decoration: InputDecoration(
                            hintText: 'Métier, prestation ou ville',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Effacer la recherche',
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      _search.clear();
                                      source.setSearchQuery('');
                                    }))),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                        initialValue:
                            categories.contains(source.selectedCategory)
                                ? source.selectedCategory
                                : 'Tous',
                        key: ValueKey(source.selectedCategory),
                        decoration: const InputDecoration(labelText: 'Métier'),
                        items: categories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) source.setCategory(v);
                        }),
                    const SizedBox(height: 16),
                    Text('${pros.length} artisan(s) · tarifs par prestation',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ])),
          if (source.isLoading) const LinearProgressIndicator(),
          Expanded(
              child: source.errorMessage != null
                  ? FeatureEmpty(
                      title: source.errorMessage!,
                      action: TextButton(
                          onPressed: source.loadProfessionals,
                          child: const Text('Réessayer')))
                  : pros.isEmpty
                      ? FeatureEmpty(
                          title: 'Aucun artisan trouvé',
                          description:
                              'Essayez un autre métier ou une autre ville.',
                          action: TextButton(
                              onPressed: () {
                                _search.clear();
                                source.setSearchQuery('');
                                source.setCategory('Tous');
                              },
                              child: const Text('Réinitialiser la recherche')))
                      : RefreshIndicator(
                          onRefresh: source.loadProfessionals,
                          child: ListView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                              itemCount: pros.length,
                              itemBuilder: (_, i) =>
                                  ProCard(professional: pros[i])))),
        ])));
  }
}
