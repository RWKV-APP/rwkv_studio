import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rwkv_dart/rwkv_dart.dart';

class ChatPage2 extends StatefulWidget {
  const ChatPage2({super.key});

  @override
  State<ChatPage2> createState() => _ChatPageState();
}

final RWKV rwkv = RWKV.isolated();

class _ChatPageState extends State<ChatPage2> {
  bool? loading;
  TextEditingController controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  String model = '';
  Set keyPressed = {};
  bool initialized = false;

  String tokenizerPath =
      r'/data/data/com.example.rwkv_studio/cache.dart/b_rwkv_vocab_v20230424.txt';

  String dynamicLibraryDir = r"D:\dev\rwkv_dart\windows\";

  Future selectFiles() async {
    // const XTypeGroup typeGroup = XTypeGroup(
    //   label: '',
    //   extensions: <String>['txt', 'so', 'gguf'],
    // );
    // final XFile? file = await openFile(
    //   acceptedTypeGroups: <XTypeGroup>[typeGroup],
    // );
    final file = File('path');
    final f = File(file.path).parent;
    print(f.path);
    setState(() {
      dynamicLibraryDir = "";
      tokenizerPath = "${f.path}/b_rwkv_vocab_v20230424.txt";
    });
  }

  void init() async {
    if (Platform.isAndroid) {
      // await selectFiles();
    }
    if (!initialized) {
      final dir = await getApplicationCacheDirectory();
      await rwkv.init(
        InitParam(
          // dynamicLibDir: dynamicLibraryDir,
          // logLevel: RWKVLogLevel.info,
          qnnLibDir: "${dir.path}/qnn",
        ),
      );
      setState(() {
        initialized = true;
      });
    }
  }

  void onLoadModelTap() async {
    final dir = await getApplicationCacheDirectory();
    if (Platform.isAndroid) {
      model = "${dir.path}/rwkv7-g1a-0.1b-20250728-ctx4096-a16w8-8gen3.bin";
      setState(() {});
    } else {
      final file = File('path');
      setState(() {
        model = file.path;
        loading = true;
      });
    }
    try {
      print('init runtime: ${model}');
      await rwkv.loadModel(
        LoadModelParam(
          modelPath: model,
          tokenizerPath: tokenizerPath,
          backend: Backend.qnn,
        ),
      );
    } catch (e) {
      print(e);
    }
    controller.text = "User: ";
    setState(() {
      loading = false;
    });
  }

  void onSubmit() async {
    final content = controller.text;
    final history = content
        .split(RegExp('(User:|Assistant:)'))
        .map((e) => e.trim())
        .where((h) => h.isNotEmpty)
        .toList();
    for (final h in history) {
      print("=>$h");
    }
    rwkv
        .chat(history)
        .listen(
          (e) {
            controller.text = '$content\nAssistant: $e\n';
            final max = scrollController.position.maxScrollExtent;
            final remain = max - scrollController.position.pixels;
            if (0 < remain && remain < 80) {
              scrollController.jumpTo(max);
            }
          },
          onError: (e) {
            print(e);
          },
          onDone: () async {
            print('chat done');
            controller.text = '${controller.text}\nUser: ';
            await Future.delayed(const Duration(milliseconds: 200));
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 24),
            Wrap(
              children: [
                if (!initialized)
                  FilledButton(onPressed: init, child: Text('Init RWKV')),
                if (!initialized) const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onLoadModelTap,
                  label: Text(model.isEmpty ? 'Load Model' : model),
                  icon: loading == true
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 4,
                          ),
                        )
                      : (loading == false
                            ? Icon(Icons.check_circle_outline_rounded)
                            : null),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    controller.text = 'User: ';
                    await rwkv.clearState();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('State Cleared')),
                    );
                  },
                  child: Text('Clear State'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    await rwkv.stopGenerate();
                  },
                  child: Text('Stop'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    await rwkv.setGenerationConfig(
                      GenerationConfig(
                        maxTokens: 4000,
                        thinkingToken: GenerationConfig.thinkingTokenFree,
                        chatReasoning: true,
                        completionStopToken: 0,
                        returnWholeGeneratedResult: false,
                        prompt: "",
                      ),
                    );
                  },
                  child: Text('Model Param'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (e) {
                  if (e is KeyDownEvent) {
                    keyPressed.add(e.physicalKey);
                  }
                  if (e is KeyUpEvent) {
                    keyPressed.remove(e.physicalKey);
                  }
                  if (keyPressed.length == 2 &&
                      keyPressed.contains(PhysicalKeyboardKey.enter) &&
                      keyPressed.contains(PhysicalKeyboardKey.controlLeft)) {
                    onSubmit();
                  }
                },
                child: TextField(
                  scrollController: scrollController,
                  controller: controller,
                  onSubmitted: (s) {
                    onSubmit();
                  },
                  onChanged: (v) {
                    if (v.endsWith('\n')) {
                      onSubmit();
                    }
                  },
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  maxLines: 1000,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
