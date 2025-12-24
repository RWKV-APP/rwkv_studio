import 'package:flutter/material.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class TTSPage extends StatefulWidget {
  const TTSPage({super.key});

  @override
  State<TTSPage> createState() => _TTSPageState();
}

const dynamicLibraryDir = r"D:\dev\rwkv_mobile_flutter\windows\";

class AudioSource extends StreamAudioSource {
  Stream<List<int>> source;

  AudioSource(this.source);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return StreamAudioResponse(
      sourceLength: null,
      contentLength: null,
      offset: start,
      stream: source,
      contentType: 'audio/wav',
    );
  }
}

class _TTSPageState extends State<TTSPage> {
  TextEditingController controller = TextEditingController();
  late RWKV rwkv;
  late final player = AudioPlayer();

  void load() async {
    rwkv = RWKV.isolated();
    await rwkv.init(InitParam(dynamicLibDir: dynamicLibraryDir));
    await rwkv.loadModel(
      LoadModelParam(
        modelPath:
            r'D:\dev\rwkv_dart\example\data\tts\rwkv7-0.4B-g1-respark-voice-tunable_ipa-f16.st',
        tokenizerPath: r'D:\dev\rwkv_dart\example\data\tts\vocab_tts.txt',
        backend: Backend.webRwkv,
        ttsModelConfig: TTSModelConfig(
          textNormalizers: [
            r'D:\dev\rwkv_dart\example\data\tts\date-zh.fst',
            r'D:\dev\rwkv_dart\example\data\tts\number-zh.fst',
            r'D:\dev\rwkv_dart\example\data\tts\phone-zh.fst',
          ],
          wav2vec2ModelPath:
              r'D:\dev\rwkv_dart\example\data\tts\wav2vec2-large-xlsr-53.mnn',
          biCodecTokenizerPath:
              r'D:\dev\rwkv_dart\example\data\tts\BiCodecTokenize.mnn',
          biCodecDetokenizerPath:
              r'D:\dev\rwkv_dart\example\data\tts\BiCodecDetokenize.mnn',
        ),
      ),
    );
  }

  void submit() async {
    final text = controller.text.trim();
    final stream = rwkv.textToSpeech(
      TextToSpeechParam(
        text: text.trim(),
        outputAudioPath: r'D:\dev\rwkv_dart\example\data\tts\out.wav',
        inputAudioPath: r'D:\dev\rwkv_dart\example\data\tts\bailu.wav',
        inputAudioText: '不许你站在半夏旁边！',
      ),
    );

    await player.setAudioSource(
      AudioSource(
        stream.flatMap((e) => Stream.value(e.map((e) => e.toInt()).toList())),
      ),
    );
    player.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TTS')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton(onPressed: load, child: Text('Load')),
          TextField(controller: controller),
          FilledButton(onPressed: submit, child: Text('Submit')),
          Spacer(),
        ],
      ),
    );
  }
}
