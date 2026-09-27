import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:financial_recording/core.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/repositories/account_group_repository.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';
import 'package:financial_recording/presentation/categories/controller/categories_controller.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

/// Every list the user files things under — expense and income categories
/// (with sub-categories) and account groups — editable in one place.
class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key, this.initialTab});

  /// Set when opened on its own from a form ("Atur kategori"): 0 =
  /// Pengeluaran, 1 = Pemasukan. Null inside the app shell.
  final int? initialTab;

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> with SingleTickerProviderStateMixin {
  late final tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab ?? 0);

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> _add(CategoriesController c) async {
    if (tabController.index == 2) {
      await _editGroup(context, c, null);
      return;
    }
    final typeCode = tabController.index == 0 ? 1 : 0;
    final result = await showAdaptiveSheet<TxCategoryModel>(
      context,
      builder: (_) => _CategoryEditor(typeCode: typeCode, controller: c),
    );
    if (result != null) await c.save(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CategoriesController(), tag: 'categories');

    return Scaffold(
      // Pushed as its own route there's no shell painting behind it.
      backgroundColor: widget.initialTab == null ? Colors.transparent : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Kategori'),
        actions: [
          // In the app bar rather than a FAB: on phones a FAB sits under the
          // floating bottom bar.
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilledButton.tonalIcon(
              onPressed: () => _add(c),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah'),
            ),
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: const [Tab(text: 'Pengeluaran'), Tab(text: 'Pemasukan'), Tab(text: 'Akun')],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _CategoryList(typeCode: 1, controller: c),
          _CategoryList(typeCode: 0, controller: c),
          _GroupList(controller: c),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Income / expense categories

enum _CatAction { edit, addSub, up, down, delete }

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.typeCode, required this.controller});
  final int typeCode;
  final CategoriesController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: ContentShell(
        child: Obx(() {
          final roots = typeCode == 1 ? controller.expenseRoots : controller.incomeRoots;
          if (roots.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text('Belum ada kategori. Tambahkan dengan tombol "Tambah" di atas.'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Ketuk kategori untuk mengubah nama, emoji, dan warnanya. Buka ▾ untuk sub-kategori.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
              for (var i = 0; i < roots.length; i++)
                _RootCard(
                  root: roots[i],
                  controller: controller,
                  isFirst: i == 0,
                  isLast: i == roots.length - 1,
                ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          );
        }),
      ),
    );
  }
}

class _RootCard extends StatelessWidget {
  const _RootCard({required this.root, required this.controller, required this.isFirst, required this.isLast});
  final TxCategoryModel root;
  final CategoriesController controller;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final children = controller.childrenOf(root.id);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: _EmojiAvatar(emoji: root.emoji, color: root.colorValue),
          title: InkWell(
            onTap: () => _editCategory(context, controller, root),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(root.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          subtitle: Text(
            children.isEmpty ? 'Tanpa sub-kategori' : '${children.length} sub-kategori',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.expand_more_rounded, color: colors.textTertiary),
              _CategoryMenu(category: root, controller: controller, isFirst: isFirst, isLast: isLast, canAddSub: true),
            ],
          ),
          children: [
            for (var i = 0; i < children.length; i++)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 72, right: 4),
                title: Text(children[i].name),
                onTap: () => _editCategory(context, controller, children[i]),
                trailing: _CategoryMenu(
                  category: children[i],
                  controller: controller,
                  isFirst: i == 0,
                  isLast: i == children.length - 1,
                  canAddSub: false,
                ),
              ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              leading: Icon(Icons.add_rounded, size: 18, color: colors.primary),
              minLeadingWidth: 0,
              title: Text('Tambah sub-kategori', style: TextStyle(color: colors.primary)),
              onTap: () => _addSub(context, controller, root),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryMenu extends StatelessWidget {
  const _CategoryMenu({
    required this.category,
    required this.controller,
    required this.isFirst,
    required this.isLast,
    required this.canAddSub,
  });
  final TxCategoryModel category;
  final CategoriesController controller;
  final bool isFirst;
  final bool isLast;
  final bool canAddSub;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CatAction>(
      tooltip: 'Opsi ${category.name}',
      icon: Icon(Icons.more_vert_rounded, size: 20, color: context.colors.textSecondary),
      onSelected: (action) async {
        switch (action) {
          case _CatAction.edit:
            await _editCategory(context, controller, category);
          case _CatAction.addSub:
            await _addSub(context, controller, category);
          case _CatAction.up:
            await controller.move(category, -1);
          case _CatAction.down:
            await controller.move(category, 1);
          case _CatAction.delete:
            await _deleteCategory(context, controller, category);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: _CatAction.edit, child: Text('Ubah')),
        if (canAddSub) const PopupMenuItem(value: _CatAction.addSub, child: Text('Tambah sub-kategori')),
        if (!isFirst) const PopupMenuItem(value: _CatAction.up, child: Text('Pindah ke atas')),
        if (!isLast) const PopupMenuItem(value: _CatAction.down, child: Text('Pindah ke bawah')),
        const PopupMenuItem(value: _CatAction.delete, child: Text('Hapus')),
      ],
    );
  }
}

Future<void> _editCategory(BuildContext context, CategoriesController c, TxCategoryModel category) async {
  final result = await showAdaptiveSheet<TxCategoryModel>(
    context,
    builder: (_) => _CategoryEditor(typeCode: category.typeCode, existing: category, controller: c),
  );
  if (result != null) await c.save(result);
}

Future<void> _addSub(BuildContext context, CategoriesController c, TxCategoryModel parent) async {
  final result = await showAdaptiveSheet<TxCategoryModel>(
    context,
    builder: (_) => _CategoryEditor(typeCode: parent.typeCode, parentId: parent.id, controller: c),
  );
  if (result != null) await c.save(result);
}

Future<void> _deleteCategory(BuildContext context, CategoriesController c, TxCategoryModel category) async {
  final subs = c.childrenOf(category.id).length;
  final used = c.usageCount(category.id);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Hapus "${category.name}"?'),
      content: Text([
        if (subs > 0) '$subs sub-kategorinya ikut terhapus.',
        if (used > 0)
          '$used transaksi memakai kategori ini — transaksinya tetap ada, tetapi menjadi "Tanpa kategori".'
        else
          'Belum ada transaksi yang memakai kategori ini.',
      ].join('\n\n')),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ctx.colors.danger),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (ok == true) await c.delete(category.id);
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.typeCode, required this.controller, this.existing, this.parentId});
  final int typeCode;
  final CategoriesController controller;
  final TxCategoryModel? existing;
  final String? parentId;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late String name = widget.existing?.name ?? '';
  late String emoji = widget.existing?.emoji ?? '📦';
  late int colorValue = widget.existing?.colorValue ?? 0xFF64748B;
  late String? parentId = widget.existing?.parentId ?? widget.parentId;
  late int typeCode = widget.existing?.typeCode ?? widget.typeCode;

  bool get _hasChildren => widget.existing != null && widget.controller.childrenOf(widget.existing!.id).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final roots = widget.controller.repository.roots(typeCode).where((r) => r.id != widget.existing?.id).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Ubah kategori' : (parentId != null ? 'Sub-kategori baru' : 'Kategori baru'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  child: QTextField(label: 'Emoji', value: emoji, onChanged: (v) => setState(() => emoji = v), maxLength: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: QTextField(label: 'Nama kategori', value: name, onChanged: (v) => name = v)),
              ],
            ),
            // Moving a category between income and expense (or under another
            // parent) is only safe while it has no sub-categories of its own.
            if (isEditing && !_hasChildren)
              QDropdownField(
                label: 'Jenis',
                value: typeCode,
                items: const [
                  {'value': 1, 'label': 'Pengeluaran'},
                  {'value': 0, 'label': 'Pemasukan'},
                ],
                onChanged: (v, _) => setState(() {
                  final next = v as int? ?? typeCode;
                  if (next != typeCode) parentId = null;
                  typeCode = next;
                }),
              ),
            if (!_hasChildren)
              QDropdownField(
                label: 'Induk',
                value: parentId ?? '',
                items: [
                  {'value': '', 'label': '— Kategori utama —'},
                  for (final r in roots) {'value': r.id, 'label': r.displayName},
                ],
                onChanged: (v, _) => setState(() {
                  final s = v as String?;
                  parentId = (s == null || s.isEmpty) ? null : s;
                }),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text('Warna', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            _ColorRow(selected: colorValue, onSelected: (v) => setState(() => colorValue = v)),
            const SizedBox(height: AppSpacing.xl),
            QButton(
              label: 'Simpan',
              onPressed: () {
                if (name.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama kategori tidak boleh kosong')));
                  return;
                }
                final model = widget.existing ??
                    TxCategoryModel(id: const Uuid().v4(), name: name, typeCode: typeCode, parentId: parentId);
                model
                  ..name = name.trim()
                  ..emoji = emoji.trim()
                  ..colorValue = colorValue
                  ..typeCode = typeCode
                  ..parentId = parentId;
                Navigator.of(context).pop(model);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account groups

enum _GroupAction { edit, up, down, reset, delete }

class _GroupList extends StatelessWidget {
  const _GroupList({required this.controller});
  final CategoriesController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      child: ContentShell(
        child: Obx(() {
          final groups = controller.accountGroups;
          final counts = controller.accountCounts;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Kelompok untuk mengelompokkan rekening & dompet di halaman Akun. Ganti nama, ikon, urutan, '
                  'atau buat kelompok sendiri.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < groups.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        leading: _EmojiAvatar(emoji: groups[i].icon, color: 0xFF64748B),
                        title: Text(
                          groups[i].label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: groups[i].hidden ? colors.textTertiary : null,
                          ),
                        ),
                        subtitle: Text(
                          [
                            '${counts[groups[i].code] ?? 0} akun',
                            if (groups[i].isLiabilityDefault) 'utang',
                            if (groups[i].hidden) 'disembunyikan',
                            if (!groups[i].builtIn) 'buatan sendiri',
                          ].join(' · '),
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                        onTap: () => _editGroup(context, controller, groups[i]),
                        trailing: PopupMenuButton<_GroupAction>(
                          tooltip: 'Opsi ${groups[i].label}',
                          icon: Icon(Icons.more_vert_rounded, size: 20, color: colors.textSecondary),
                          onSelected: (a) async {
                            final g = groups[i];
                            switch (a) {
                              case _GroupAction.edit:
                                await _editGroup(context, controller, g);
                              case _GroupAction.up:
                                await controller.moveGroup(g, -1);
                              case _GroupAction.down:
                                await controller.moveGroup(g, 1);
                              case _GroupAction.reset:
                                await controller.resetGroup(g.code);
                              case _GroupAction.delete:
                                await _deleteGroup(context, controller, g);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: _GroupAction.edit, child: Text('Ubah')),
                            if (i > 0) const PopupMenuItem(value: _GroupAction.up, child: Text('Pindah ke atas')),
                            if (i < groups.length - 1)
                              const PopupMenuItem(value: _GroupAction.down, child: Text('Pindah ke bawah')),
                            if (groups[i].builtIn)
                              const PopupMenuItem(value: _GroupAction.reset, child: Text('Kembalikan nama bawaan'))
                            else
                              const PopupMenuItem(value: _GroupAction.delete, child: Text('Hapus')),
                          ],
                        ),
                      ),
                    ],
                  ],
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

Future<void> _editGroup(BuildContext context, CategoriesController c, AccountGroup? group) async {
  final result = await showAdaptiveSheet<AccountGroup>(context, builder: (_) => _GroupEditor(existing: group));
  if (result == null) return;
  if (group == null) {
    await c.createGroup(label: result.label, icon: result.icon, isLiabilityDefault: result.isLiabilityDefault);
  } else {
    await c.saveGroup(result);
  }
}

Future<void> _deleteGroup(BuildContext context, CategoriesController c, AccountGroup group) async {
  final n = c.accountCounts[group.code] ?? 0;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Hapus kelompok "${group.label}"?'),
      content: Text(n > 0 ? '$n akun di kelompok ini dipindah ke "Lainnya". Saldo dan transaksinya tidak berubah.' : 'Kelompok ini belum dipakai akun mana pun.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ctx.colors.danger),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (ok == true) await c.deleteGroup(group.code);
}

class _GroupEditor extends StatefulWidget {
  const _GroupEditor({this.existing});
  final AccountGroup? existing;

  @override
  State<_GroupEditor> createState() => _GroupEditorState();
}

class _GroupEditorState extends State<_GroupEditor> {
  late String label = widget.existing?.label ?? '';
  late String icon = widget.existing?.icon ?? '📁';
  late bool liability = widget.existing?.isLiabilityDefault ?? false;
  late bool hidden = widget.existing?.hidden ?? false;

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final builtInLabel = existing != null && existing.builtIn ? AccountGroupType.fromCode(existing.code).label : null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(existing == null ? 'Kelompok akun baru' : 'Ubah kelompok akun', style: Theme.of(context).textTheme.titleLarge),
            if (builtInLabel != null && builtInLabel != label)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Nama bawaan: $builtInLabel', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 88, child: QTextField(label: 'Ikon', value: icon, onChanged: (v) => icon = v, maxLength: 2)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: QTextField(label: 'Nama kelompok', value: label, onChanged: (v) => label = v)),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: liability,
              onChanged: (v) => setState(() => liability = v),
              title: const Text('Akun baru dianggap utang'),
              subtitle: const Text('Mis. kartu kredit / PayLater. Bisa diubah per akun.'),
            ),
            if (existing != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: hidden,
                onChanged: (v) => setState(() => hidden = v),
                title: const Text('Sembunyikan dari pilihan'),
                subtitle: const Text('Akun yang sudah ada di kelompok ini tetap tampil.'),
              ),
            const SizedBox(height: AppSpacing.lg),
            QButton(
              label: 'Simpan',
              onPressed: () {
                if (label.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama kelompok tidak boleh kosong')));
                  return;
                }
                final icn = icon.trim().isEmpty ? '📁' : icon.trim();
                final result = existing?.copyWith(label: label.trim(), icon: icn, isLiabilityDefault: liability, hidden: hidden) ??
                    AccountGroup(code: 0, label: label.trim(), icon: icn, isLiabilityDefault: liability, builtIn: false);
                Navigator.of(context).pop(result);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmojiAvatar extends StatelessWidget {
  const _EmojiAvatar({required this.emoji, required this.color});
  final String? emoji;
  final int color;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        backgroundColor: Color(color).withValues(alpha: 0.15),
        child: Text(emoji == null || emoji!.isEmpty ? '📦' : emoji!),
      );
}

const _palette = [
  0xFF64748B,
  0xFFEF4444,
  0xFFF59E0B,
  0xFF10B981,
  0xFF0EA5E9,
  0xFF4F46E5,
  0xFF8B5CF6,
  0xFFEC4899,
];

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final c in _palette)
            Semantics(
              button: true,
              selected: c == selected,
              child: InkResponse(
                onTap: () => onSelected(c),
                radius: 22,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(c),
                  child: c == selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              ),
            ),
        ],
      );
}
