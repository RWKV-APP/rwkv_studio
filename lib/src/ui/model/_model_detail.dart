import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/model/_model_tag_badge.dart';
import 'package:url_launcher/url_launcher.dart';

import '_model_actions.dart';

class ModelDetail extends StatelessWidget {
  final ModelInfo? model;

  const ModelDetail({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    if (model == null) {
      return const Center(child: Text('未选择模型'));
    }

    String fileSize = '';
    if (model!.fileSize > 1024 * 1024 * 1024) {
      fileSize =
          '${(model!.fileSize / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
    } else {
      fileSize = '${(model!.fileSize / 1024 / 1024).toStringAsFixed(2)}MB';
    }

    String datetime = '0000-00-00';
    if (model!.updatedAt > 0) {
      datetime = DateTime.fromMillisecondsSinceEpoch(
        model!.updatedAt,
      ).toString();
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
                            "https://huggingface.co/${model!.url.replaceFirst('resolve', 'blob')}",
                          );
                          await launchUrl(uri);
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              model!.name,
                              style: AppTextTheme.headingL,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ModelSuggestBadge(model: model!),
                  ],
                ),
                const SizedBox(height: 8),
                Text("更新时间:  $datetime", style: AppTextTheme.caption),
                const SizedBox(height: 8),
                _buildLabel("模型ID: ${model!.id}"),
                _buildLabel("参数大小: ${model!.modelSize}B"),
                _buildLabel("量化方式: ${model!.quantization}"),
                _buildLabel("推理后端: ${model!.backend.name}"),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLabel("标签: "),
                    for (final tag in model!.tags) ModelTagBadge(tag: tag),
                  ],
                ),
                _buildLabel("分组: ${model!.groups.join(', ')}"),
                _buildLabel("文件大小: $fileSize"),
                if (model!.sha256.isNotEmpty)
                  _buildLabel("SHA256: ${model!.sha256}"),
                // _buildLabel("路径: ${model!.url}"),
                if (model!.localPath.isNotEmpty)
                  _buildLabel("本地路径: ${File(model!.localPath).absolute.path}"),
                _buildLabel(
                  "支持平台: ${model!.backend.platforms.map((e) => e.name).join(', ')}",
                ),
              ],
            ),
          ),
          Row(
            children: [
              Spacer(),
              ModelItemActions(model: model!, compact: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SelectableText(text, style: AppTextTheme.body),
    );
  }
}

class ModelSuggestBadge extends StatelessWidget {
  final ModelInfo model;

  const ModelSuggestBadge({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: '推荐下载',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: context.theme.colorScheme.surfaceContainerLow,
            ),
            child: Text(
              '👍推荐',
              style: AppTextTheme.body.copyWith(
                color: context.theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: '不推荐',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: context.theme.colorScheme.errorContainer,
            ),
            child: Text(
              '❗不推荐',
              style: AppTextTheme.body.copyWith(
                color: context.theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
