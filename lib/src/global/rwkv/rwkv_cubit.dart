import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';

part 'rwkv_state.dart';

extension Ext on BuildContext {
  RwkvCubit get rwkv => BlocProvider.of<RwkvCubit>(this);

  RwkvState get rwkvState => rwkv.state;
}

class RwkvCubit extends Cubit<RwkvState> {
  RwkvCubit() : super(RwkvState.initial());

  void init() async {
    //
  }

  Future stop(String modelInstanceId) async {
    final instance = state.models[modelInstanceId]!;
    await instance.rwkv.stopGenerate();
  }

  Stream<String> generate(String prompt, String modelInstanceId) {
    final instance = state.models[modelInstanceId]!;
    return instance.rwkv.generate(prompt);
  }

  Future<ModelInstanceState> loadModel(ModelInfo model) async {
    final rwkv = RWKV.isolated();
    await rwkv.init(InitParam(logLevel: RWKVLogLevel.verbose));
    emit(
      state.copyWith(
        modelLoadState: ModelLoadState(model: model, loading: true, error: ''),
      ),
    );
    try {
      await rwkv.loadModel(
        LoadModelParam(
          modelPath: model.localPath,
          tokenizerPath:
              r'E:\dev\rwkv_studio\examples\b_rwkv_vocab_v20230424.txt',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          modelLoadState: ModelLoadState(
            model: model,
            loading: false,
            error: e.toString(),
          ),
        ),
      );
    }
    final instance = ModelInstanceState(rwkv: rwkv, info: model);
    emit(
      state.copyWith(
        models: {...state.models, instance.id: instance},
        modelLoadState: ModelLoadState.initial(),
      ),
    );

    rwkv.generationStateStream().listen((e) {
      final inst = state.models[instance.id];
      emit(
        state.copyWith(
          models: {
            ...state.models,
            instance.id: inst!.copyWith(state: e),
          },
        ),
      );
    });

    return instance;
  }
}
