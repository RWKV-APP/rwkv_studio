import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/models/model/model_identity.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/theme/text_theme.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';

class RemoteModelProviderTabBody extends StatefulWidget {
  const RemoteModelProviderTabBody({super.key});

  @override
  State<RemoteModelProviderTabBody> createState() =>
      _RemoteModelProviderTabBodyState();
}

class _RemoteModelProviderTabBodyState
    extends State<RemoteModelProviderTabBody> {
  final TextEditingController _controllerSearch = TextEditingController();
  String _keywords = '';

  late final Set<ModelIdentity> _disabled = context
      .modelManage
      .state
      .disabledModelIds
      .toSet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModelManageCubit, ModelManageState>(
      buildWhen: (p, c) => p.remoteModels != c.remoteModels,
      builder: (BuildContext context, ModelManageState state) {
        final e = state.remoteModels.groupBy(
          (e) => '${e.providerName} (${e.providerUrl})',
        );
        final list = <dynamic>[];
        for (final k in e.entries) {
          list.add(k.key);
          for (final v in k.value) {
            if (_keywords.isEmpty || v.id.toLowerCase().contains(_keywords)) {
              list.add(v);
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              TextBox(
                controller: _controllerSearch,
                placeholder: '搜索模型',
                onChanged: (v) {
                  _keywords = v;
                  setState(() {});
                },
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (model, index) {
                    final item = list[index];
                    if (item is String) {
                      return Padding(
                        padding: const .symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text(item, style: context.fluent.typography.bodyStrong)),
                            IconButton(
                              icon: const Text('全部禁用'),
                              onPressed: () {
                                final ids = list
                                    .whereType<ModelInfo>()
                                    .where(
                                      (e) =>
                                          "${e.providerName} (${e.providerUrl})" ==
                                          item,
                                    )
                                    .map((e) => e.getIdentity());
                                _disabled.addAll(ids);
                                setState(() {});
                                context.modelManage.setDisabledModels(
                                  _disabled.toList(),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Text('全部启用'),
                              onPressed: () {
                                final provider = item.split(' ').first;
                                _disabled.removeWhere(
                                  (e) => provider == e.provider,
                                );
                                setState(() {});
                                context.modelManage.setDisabledModels(
                                  _disabled.toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    if (item is! ModelInfo) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      title: Text(item.name, style: AppTextStyle.body),
                      onPressed: () {
                        //
                      },
                      trailing: Checkbox(
                        checked: !_disabled.contains(item.getIdentity()),
                        onChanged: (v) {
                          if (v == true) {
                            _disabled.remove(item.getIdentity());
                          } else {
                            _disabled.add(item.getIdentity());
                          }
                          setState(() {});
                          context.modelManage.setDisabledModels(
                            _disabled.toList(),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
