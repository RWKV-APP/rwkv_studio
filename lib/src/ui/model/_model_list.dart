import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/native_utils.dart';
import 'package:rwkv_studio/src/utils/string_utils.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

import '_model_actions.dart';

class ModelList extends StatelessWidget {
  final List<ModelInfo> models;

  const ModelList({super.key, this.models = const []});

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return Center(
        child: Text('No models found', style: AppTextStyle.bodySecondary),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: models.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _ModelListItem(model: models[index]),
    );
  }
}

class _ModelListItem extends StatefulWidget {
  final ModelInfo model;

  const _ModelListItem({required this.model});

  @override
  State<_ModelListItem> createState() => _ModelListItemState();
}

class _ModelListItemState extends State<_ModelListItem> {
  bool _hovering = false;

  ModelInfo get model => widget.model;

  @override
  Widget build(BuildContext context) {
    final borderColor = _hovering
        ? Colors.blue.withValues(alpha: 0.35)
        : context.fluent.inactiveBackgroundColor;

    final tags = [
      model.providerName,
      if (model.fileSize > 0) model.fileSize.formatFileSize,
      _updatedAtText(model.updatedAt),
      model.quantization,
      if (model.backend != .unknown) model.backend.displayName,
    ].where((e) => e.isNotEmpty);

    return BlocSelector<
      ModelManageCubit,
      ModelManageState,
      ModelDownloadState?
    >(
      selector: (state) => state.modelStates[model.id],
      builder: (context, downloadState) {
        return MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: context.fluent.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      model.name,
                      style: AppTextStyle.bodyBold,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (final t in tags) _InfoChip(text: t),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      if (model.localPath.isNotEmpty)
                        Tooltip(
                          message: 'Open folder',
                          child: IconButton(
                            icon: const Icon(WindowsIcons.folder),
                            onPressed: () => NativeUtils.showInFolder(
                              model.localPath,
                            ).withToast(context),
                          ),
                        ),

                      if (!model.isRemote && !model.isImportManually)
                        ModelItemActions(model: model, compact: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;

  const _InfoChip({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
      ),
      child: Text(text, style: AppTextStyle.caption),
    );
  }
}

String _updatedAtText(int updatedAt) {
  if (updatedAt <= 0) {
    return '';
  }
  return DateTime.fromMillisecondsSinceEpoch(updatedAt).dateString;
}
