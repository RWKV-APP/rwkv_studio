import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    show PopupMenuButton, PopupMenuItem, Icons, TextButton, VerticalDivider;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/global/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/model/_model_detail.dart';
import 'package:rwkv_studio/src/ui/model/_model_list_item.dart';

class ModelListPage extends StatefulWidget {
  const ModelListPage({super.key});

  @override
  State<ModelListPage> createState() => _ModelListPageState();
}

class _ModelListPageState extends State<ModelListPage>
    with AutomaticKeepAliveClientMixin {
  ModelInfo? _selectedModel;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bar = Row(
      children: [
        Text('浏览模型', style: AppTextTheme.heading),
        const Spacer(),
        //
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            //
          },
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
    final list = BlocBuilder<ModelManageCubit, ModelManageState>(
      buildWhen: (previous, current) => previous.models != current.models,
      builder: (context, state) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: state.models.length,
          itemBuilder: (context, index) {
            final model = state.models[index];
            return ListTile.selectable(
              // decoration: _selectedModel?.id != model.id
              //     ? null
              //     : BoxDecoration(
              //         borderRadius: BorderRadius.circular(8),
              //         color: context.theme.colorScheme.surfaceContainerHigh,
              //       ),
              selected: _selectedModel?.id == model.id,
              title: ModelListItem(
                model: model,
                onTap: () {
                  setState(() {
                    _selectedModel = model;
                  });
                },
              ),
            );
          },
        );
      },
    );

    final filter = Container(
      color: context.theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              context.modelManage.updateConfig();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          Spacer(),
          TextButton.icon(
            onPressed: () {
              //
            },
            label: const Text('时间 ↓'),
            icon: const Icon(Icons.filter_list_rounded),
          ),
          TextButton.icon(
            onPressed: () {
              //
            },
            label: const Text('全部'),
            icon: const Icon(Icons.filter_alt_outlined),
          ),
        ],
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: bar,
        ),
        Divider(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    filter,
                    Expanded(child: list),
                  ],
                ),
              ),
              VerticalDivider(width: .5, thickness: .5),
              Expanded(flex: 5, child: ModelDetail(model: _selectedModel)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceSelector extends StatelessWidget {
  const _SourceSelector();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ModelManageCubit, ModelManageState, DownloadSource>(
      selector: (state) => state.downloadSource,
      builder: (context, state) {
        return PopupMenuButton(
          initialValue: state,
          onSelected: (source) {
            context.modelManage.changeDownloadSource(source);
          },
          itemBuilder: (context) {
            final sources = [
              DownloadSource.auto,
              DownloadSource.aiFastHub,
              DownloadSource.hfMirror,
              DownloadSource.huggingface,
              DownloadSource.googleApis,
            ];
            return [
              for (final source in sources)
                PopupMenuItem(value: source, child: Text(source.name)),
            ];
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.theme.colorScheme.outline),
            ),
            child: Text('下载源: ${state.name}', style: AppTextTheme.label),
          ),
        );
      },
    );
  }
}
