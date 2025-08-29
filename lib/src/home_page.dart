import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rwkv_dart/rwkv_dart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

final RWKV rwkv = RWKV.isolated();

class _HomePageState extends State<HomePage> {
  bool? loading;
  TextEditingController controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  String model = '';
  Set keyPressed = {};
  bool initialized = false;

  String tokenizerPath =
      r'D:\dev\RWKV_APP\assets\config\chat\b_rwkv_vocab_v20230424.txt';

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
    if (file == null) {
      return;
    }
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
      await rwkv.init(
        InitParam(
          // dynamicLibDir: dynamicLibraryDir,
          // logLevel: RWKVLogLevel.info,
        ),
      );
      setState(() {
        initialized = true;
      });
    }
  }

  void onLoadModelTap() async {
    if (Platform.isAndroid) {
      // final dir = await getApplicationCacheDirectory();
      model = "${''}/rwkv7-g1-0.1b-20250307-ctx4096_Q8_0.gguf";
      setState(() {});
    } else {
      final file = File('path');
      if (file == null) {
        return;
      }
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
          backend: Backend.webRwkv,
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
            controller.text = '$content\n\nAssistant: $e\n';
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
                    await rwkv.stopGeneration();
                  },
                  child: Text('Stop'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    await rwkv.setGenerationParam(
                      GenerationParam(
                        maxTokens: 4000,
                        thinkingToken: GenerationParam.thinkingTokenFree,
                        chatReasoning: true,
                        completionStopToken: 0,
                        returnWholeGeneratedResult: false,
                        prompt: "",
                      ),
                    );
                  },
                  child: Text('Model Param'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    // Navigator.pushNamed(context, '/test');
                    Navigator.pushNamed(context, '/parse_midi');
                  },
                  child: Text('Parse'),
                ),
                FilledButton(
                  onPressed: () async {
                    // Navigator.pushNamed(context, '/test');
                    Navigator.pushNamed(context, '/devices');
                  },
                  child: Text('Midi'),
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
