import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/theme/text_theme.dart';

class ModelList extends StatelessWidget {
  final String selectedModelId;
  final ValueChanged<ModelInfo> onModelSelected;
  final List<ModelInfo> models;

  const ModelList({
    super.key,
    required this.selectedModelId,
    required this.onModelSelected,
    this.models = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return Center(child: Text('暂无模型', style: AppTextStyle.bodySecondary));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: models.length,
      itemBuilder: (context, index) {
        final model = models[index];
        final selected = selectedModelId == model.id;

        Widget? trailing;
        if (model.isRemote) {
          trailing = Tooltip(
            message: '远程模型: ${model.providerName}',
            child: const Icon(FluentIcons.remote),
          );
        } else if (model.isImportManually) {
          trailing = const Padding(
            padding: .only(left: 16),
            child: Icon(FluentIcons.arrow_tall_down_left, size: 10),
          );
        } else if (model.localPath.isNotEmpty) {
          trailing = const Icon(FluentIcons.status_circle_checkmark);
        }

        return ListTile.selectable(
          selected: selected,
          onSelectionChange: (value) {
            if (value) {
              onModelSelected(model);
            }
          },
          trailing: trailing,
          contentPadding: const .only(right: 24),
          title: Text(
            model.name,
            style: AppTextStyle.bodyBold,
            overflow: .ellipsis,
            maxLines: 1,
          ),
        );
      },
    );
  }
}
