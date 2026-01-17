import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/common/backend_badge.dart';
import 'package:rwkv_studio/src/ui/model/_model_tag_badge.dart';
import 'package:rwkv_studio/src/utils/string_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '_model_actions.dart';

class ModelDetail extends StatelessWidget {
  final ModelInfo model;

  const ModelDetail({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    String fileSize = '';
    if (model.fileSize > 1024 * 1024 * 1024) {
      fileSize =
          '${(model.fileSize / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
    } else {
      fileSize = '${(model.fileSize / 1024 / 1024).toStringAsFixed(2)}MB';
    }

    String datetime = '0000-00-00';
    if (model.updatedAt > 0) {
      datetime = DateTime.fromMillisecondsSinceEpoch(
        model.updatedAt,
      ).dateString;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(
                            "https://huggingface.co/${model.url.replaceFirst('resolve', 'blob')}",
                          );
                          await launchUrl(uri);
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              model.name,
                              style: AppTextStyle.headingL,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ModelSuggestBadge(model: model),
                  ],
                ),
                const SizedBox(height: 8),
                if (model.updatedAt > 0)
                  Text("更新时间:  $datetime", style: AppTextStyle.caption),
                if (model.updatedAt > 0) const SizedBox(height: 8),
                _buildLabel("模型ID: ${model.id}"),
                if (model.modelSize > 0)
                  _buildLabel("参数大小: ${model.modelSize}B"),
                if (model.quantization.isNotEmpty)
                  _buildLabel("量化方式: ${model.quantization}"),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLabel("推理后端: "),
                    ModelBackendBadge(info: model),
                    const SizedBox(width: 8),
                    _buildLabel(model.backend.name),
                  ],
                ),
                if (model.tags.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildLabel("标签: "),
                      for (final tag in model.tags) ModelTagBadge(tag: tag),
                    ],
                  ),
                if (model.groups.isNotEmpty)
                  _buildLabel("分组: ${model.groups.join(', ')}"),
                if (model.fileSize > 0) _buildLabel("文件大小: $fileSize"),
                if (model.sha256.isNotEmpty)
                  _buildLabel("SHA256: ${model.sha256}"),
                // _buildLabel("路径: ${model.url}"),
                if (model.localPath.isNotEmpty)
                  _buildLabel("文件路径: ${model.localPath}"),
                _buildLabel(
                  "支持平台: ${model.backend.platforms.map((e) => e.name).join(', ')}",
                ),
              ],
            ),
          ),
          Row(
            children: [
              Spacer(),
              if (model is! RemoteModelInfo)
                ModelItemActions(model: model, compact: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SelectableText(text, style: AppTextStyle.body),
    );
  }
}

class ModelSuggestBadge extends StatelessWidget {
  final ModelInfo model;

  const ModelSuggestBadge({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final suggested = model.modelSize > 1;
    final isTextModel =
        model.groups.contains('chat') ||
        model.groups.contains('albatross') ||
        model.groups.contains('roleplay');
    final showNotSuggest = !suggested && model.modelSize > 0 && isTextModel;
    return Row(
      children: [
        if (suggested)
          Tooltip(
            message: '推荐下载',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.green.withAlpha(50),
              ),
              child: Text(
                '👍推荐',
                style: AppTextStyle.body.copyWith(color: Colors.green),
              ),
            ),
          ),
        const SizedBox(width: 8),
        if (showNotSuggest)
          Tooltip(
            message: '不推荐',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.red.withAlpha(50),
              ),
              child: Text(
                '❗不推荐',
                style: AppTextStyle.body.copyWith(color: Colors.red.light),
              ),
            ),
          ),
      ],
    );
  }
}
