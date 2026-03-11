import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/utils/file_util.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/string_utils.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ImportModelDialog extends StatefulWidget {
  final String path;

  const ImportModelDialog._({required this.path});

  static Future<ModelInfo?> show(BuildContext context, String path) async {
    return showDialog<ModelInfo?>(
      context: context,
      builder: (context) {
        return ImportModelDialog._(path: path);
      },
    );
  }

  @override
  State<ImportModelDialog> createState() => _ImportModelDialogState();
}

class _ImportModelDialogState extends State<ImportModelDialog> {
  ModelInfo? model;
  ModelInfo? existingModel;
  String? message;

  List<ModelBackend> backends = [];
  List<ModelGroup> groups = [];
  List<ModelTag> tags = [];

  bool calculating = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        setState(() {
          message = 'Loading model metadata...';
        });
        await context.modelManage.ensureRuntimeReady();
        if (!mounted) {
          return;
        }
        backends = [ModelBackend.unknown, ...context.modelManage.state.backends];
        tags = context.modelManage.state.getDisplayTags();
        groups = context.modelManage.state.getDisplayGroups();
        setState(() {
          message = 'Resolving model info...';
        });
        await resolve();
      } catch (e) {
        if (mounted) {
          setState(() {
            message = 'Failed to resolve model info\n$e';
          });
        }
      }
    });
  }

  Future<void> calculateMd5() async {
    calculating = true;
    setState(() {});
    final md5 = await File(widget.path).md5();
    if (!mounted) {
      return;
    }
    existingModel = context.modelManage.findModelByMD5(md5);
    model = model?.copyWith(md5: md5);
    calculating = false;
    setState(() {});
  }

  void resolveModelSizeFromName() {
    try {
      final regex = RegExp(r'[^\p{L}]\d+(\.\d+)?[Bb][^\p{L}]');
      final match = regex.firstMatch(model!.name);
      if (match != null) {
        final m = match.group(0);
        if (m != null) {
          final size = m.substring(1, m.length - 2);
          logd('model size: $size');
          model = model!.copyWith(modelSize: num.tryParse(size.trim()) ?? -1);
        }
      }
    } catch (e) {
      logw(e);
    }
  }

  Future<void> resolve() async {
    final file = File(widget.path);
    final size = await file.length();
    const sha256 = '';
    const md5 = '';

    model = ModelInfo.base(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: file.name,
      url: '',
      groups: ['chat'],
      fileSize: size,
      backend: ModelBackend.conjecture(file.extension) ?? ModelBackend.unknown,
      sha256: sha256,
      md5: md5,
      localPath: widget.path,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    resolveModelSizeFromName();

    setState(() {});

    await calculateMd5();
  }

  void onConfirmTap() {
    if (model!.name.isEmpty) {
      context.toast('Please enter a model name');
      return;
    }
    Navigator.of(context).pop(model);
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600),
      title: Text(model == null ? 'Please wait...' : 'Import model'),
      content: model == null
          ? Text(message ?? '...')
          : SingleChildScrollView(child: buildModelInfo()),
      actions: [
        Button(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: model == null ? null : onConfirmTap,
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Widget modelExists() {
    if (existingModel != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'A model with the same MD5 already exists: ${existingModel?.name}',
          style: const TextStyle(color: Colors.errorPrimaryColor),
        ),
      );
    }
    return const SizedBox();
  }

  Widget buildModelInfo() {
    final model = this.model!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Path   ${widget.path}', overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        const ToggleSwitch(
          checked: false,
          onChanged: null,
          content: Text('Copy into model directory'),
        ),
        const SizedBox(height: 12),
        modelExists(),
        Row(
          children: [
            const SizedBox(width: 90, child: Text('Model name')),
            Expanded(
              child: TextBox(
                maxLines: 1,
                controller: TextEditingController(text: model.name),
                onChanged: (v) {
                  this.model = model.copyWith(name: v.trim());
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 90, child: Text('Model size')),
            Expanded(
              child: TextBox(
                placeholder: 'Unknown',
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (v) {
                  this.model = model.copyWith(modelSize: num.tryParse(v));
                },
                controller: TextEditingController(
                  text: model.modelSize <= 0 ? '' : model.modelSize.toString(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 90, child: Text('Vocab')),
            Flexible(
              child: ComboBox(
                value: 'b_rwkv_vocab_v20230424.txt',
                onChanged: (v) {
                  this.model = model.copyWith(vocabId: v);
                },
                items: const [
                  ComboBoxItem(
                    value: 'b_rwkv_vocab_v20230424.txt',
                    child: Text(
                      'b_rwkv_vocab_v20230424.txt',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 90, child: Text('File size')),
            Expanded(child: Text(model.fileSize.formatFileSize)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 90, child: Text('MD5')),
            if (model.md5.isNotEmpty) Expanded(child: SelectableText(model.md5)),
            if (calculating)
              const SizedBox(width: 24, height: 24, child: ProgressRing()),
            if (!calculating)
              Button(onPressed: calculateMd5, child: const Text('Calculate')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 90, child: Text('Backend')),
            Expanded(
              child: RadioGroup(
                groupValue: model.backend,
                onChanged: (v) {
                  this.model = model.copyWith(backend: v);
                  setState(() {});
                },
                child: Wrap(
                  runSpacing: 6,
                  spacing: 8,
                  children: [
                    for (final backend in backends)
                      RadioButton(
                        value: backend,
                        content: Text(backend.displayName),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 90, child: Text('Group')),
            Expanded(
              child: RadioGroup(
                groupValue: model.groups.firstOrNull ?? '',
                onChanged: (v) {
                  this.model = model.copyWith(groups: [v ?? '']);
                  setState(() {});
                },
                child: Wrap(
                  runSpacing: 6,
                  spacing: 8,
                  children: [
                    for (final group in groups)
                      RadioButton(value: group.name, content: Text(group.name)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 90, child: Text('Tags')),
            Expanded(
              child: Wrap(
                runSpacing: 6,
                spacing: 8,
                children: [
                  for (final tag in tags)
                    Checkbox(
                      checked: model.tags.contains(tag.name),
                      onChanged: (v) {
                        if (v == true) {
                          this.model = model.copyWith(
                            tags: {...model.tags, tag.name}.toList(),
                          );
                        } else {
                          this.model = model.copyWith(
                            tags: model.tags.where((e) => e != tag.name).toList(),
                          );
                        }
                        setState(() {});
                      },
                      content: Text(tag.name),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
