import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:financial_recording/data/models/memo_model/memo_model.dart';
import 'package:financial_recording/presentation/memo/controller/memo_controller.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/responsive/content_shell.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

const _memoColors = [0xFFF6C76B, 0xFF66D6BF, 0xFFB7A4E5, 0xFFEF4444, 0xFF64748B];

class MemoView extends StatelessWidget {
  const MemoView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MemoController(), tag: 'memo');
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Memo')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, c, null),
        child: const Icon(Icons.add_rounded),
      ),
      body: SingleChildScrollView(
        child: ContentShell(
          child: Obx(() {
            if (c.memos.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Center(
                  child: Text('Belum ada memo. Ketuk + untuk menambah.', style: TextStyle(color: colors.textSecondary)),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final m in c.memos)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      onTap: () => _openEditor(context, c, m),
                      leading: Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(color: Color(m.colorValue), shape: BoxShape.circle),
                      ),
                      title: Row(
                        children: [
                          if (m.pinned) Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin_rounded, size: 14, color: colors.primary),
                          ),
                          Expanded(
                            child: Text(
                              m.title.isEmpty ? '(Tanpa judul)' : m.title,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${DateFormat('d MMM y', 'id_ID').format(m.date)}${m.body.isEmpty ? '' : ' · ${m.body}'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, MemoController c, MemoModel? existing) {
    showAdaptiveSheet<bool>(context, builder: (_) => _MemoEditorSheet(controller: c, existing: existing));
  }
}

class _MemoEditorSheet extends StatefulWidget {
  const _MemoEditorSheet({required this.controller, this.existing});
  final MemoController controller;
  final MemoModel? existing;

  @override
  State<_MemoEditorSheet> createState() => _MemoEditorSheetState();
}

class _MemoEditorSheetState extends State<_MemoEditorSheet> {
  late DateTime date = widget.existing?.date ?? DateTime.now();
  late String title = widget.existing?.title ?? '';
  late String body = widget.existing?.body ?? '';
  late int colorValue = widget.existing?.colorValue ?? _memoColors.first;
  late bool pinned = widget.existing?.pinned ?? false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEditing = widget.existing != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEditing ? 'Ubah Memo' : 'Memo Baru', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: Text(DateFormat('EEEE, d MMMM y', 'id_ID').format(date)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => date = picked);
              },
            ),
            TextFormField(
              initialValue: title,
              decoration: const InputDecoration(labelText: 'Judul'),
              onChanged: (v) => title = v,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: body,
              decoration: const InputDecoration(labelText: 'Memo'),
              maxLines: 5,
              onChanged: (v) => body = v,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final c in _memoColors)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => colorValue = c),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(c),
                        child: colorValue == c ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: pinned ? 'Lepas pin' : 'Pin memo',
                  icon: Icon(pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: colors.primary),
                  onPressed: () => setState(() => pinned = !pinned),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (isEditing) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await widget.controller.delete(widget.existing!.id);
                        if (context.mounted) Navigator.of(context).pop(true);
                      },
                      child: Text('Hapus', style: TextStyle(color: colors.danger)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      final memo = widget.existing ?? MemoModel(id: const Uuid().v4(), date: date);
                      memo
                        ..date = date
                        ..title = title.trim()
                        ..body = body.trim()
                        ..colorValue = colorValue
                        ..pinned = pinned;
                      await widget.controller.save(memo);
                      if (context.mounted) Navigator.of(context).pop(true);
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
