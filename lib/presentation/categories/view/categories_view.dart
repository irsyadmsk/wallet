import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:financial_recording/core.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/presentation/categories/controller/categories_controller.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> with SingleTickerProviderStateMixin {
  late final tabController = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CategoriesController(), tag: 'categories');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Kategori'),
        bottom: TabBar(controller: tabController, tabs: const [Tab(text: 'Pengeluaran'), Tab(text: 'Pemasukan')]),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_rounded),
        onPressed: () async {
          final typeCode = tabController.index == 0 ? 1 : 0;
          final result = await showAdaptiveSheet<TxCategoryModel>(
            context,
            builder: (_) => _CategoryEditor(typeCode: typeCode),
          );
          if (result != null) await c.save(result);
        },
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _CategoryList(typeCode: 1, controller: c),
          _CategoryList(typeCode: 0, controller: c),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.typeCode, required this.controller});
  final int typeCode;
  final CategoriesController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ContentShell(
        child: Obx(() {
          final roots = typeCode == 1 ? controller.expenseRoots : controller.incomeRoots;
          if (roots.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text('Belum ada kategori.'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final root in roots)
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(root.colorValue).withValues(alpha: 0.15),
                      child: Text(root.emoji ?? '📦'),
                    ),
                    title: Text(root.name),
                    onExpansionChanged: null,
                    children: [
                      for (final child in controller.childrenOf(root.id))
                        ListTile(
                          title: Text(child.name),
                          onTap: () async {
                            final result = await showAdaptiveSheet<TxCategoryModel>(
                              context,
                              builder: (_) => _CategoryEditor(typeCode: typeCode, existing: child),
                            );
                            if (result != null) await controller.save(result);
                          },
                        ),
                      ListTile(
                        leading: const Icon(Icons.add_rounded, size: 18),
                        title: const Text('Tambah sub-kategori'),
                        onTap: () async {
                          final result = await showAdaptiveSheet<TxCategoryModel>(
                            context,
                            builder: (_) => _CategoryEditor(typeCode: typeCode, parentId: root.id),
                          );
                          if (result != null) await controller.save(result);
                        },
                      ),
                    ],
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          final result = await showAdaptiveSheet<TxCategoryModel>(
                            context,
                            builder: (_) => _CategoryEditor(typeCode: typeCode, existing: root),
                          );
                          if (result != null) await controller.save(result);
                        } else if (v == 'delete') {
                          await controller.delete(root.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Ubah')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          );
        }),
      ),
    );
  }
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.typeCode, this.existing, this.parentId});
  final int typeCode;
  final TxCategoryModel? existing;
  final String? parentId;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late String name = widget.existing?.name ?? '';
  late String emoji = widget.existing?.emoji ?? '📦';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing != null ? 'Ubah kategori' : 'Kategori baru', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            QTextField(label: 'Emoji', value: emoji, onChanged: (v) => emoji = v, maxLength: 2),
            QTextField(label: 'Nama kategori', value: name, onChanged: (v) => name = v),
            const SizedBox(height: AppSpacing.lg),
            QButton(
              label: 'Simpan',
              onPressed: () {
                if (name.trim().isEmpty) return;
                final model = widget.existing ??
                    TxCategoryModel(
                      id: const Uuid().v4(),
                      name: name,
                      typeCode: widget.typeCode,
                      parentId: widget.parentId,
                    );
                model
                  ..name = name.trim()
                  ..emoji = emoji.trim();
                Navigator.of(context).pop(model);
              },
            ),
          ],
        ),
      ),
    );
  }
}
