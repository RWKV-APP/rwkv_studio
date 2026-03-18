import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/custom_widgets/custom_divider.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:rwkv_studio/src/theme/theme.dart';

class Markdown extends StatelessWidget {
  final String text;
  final TextStyle? style;

  static final List<MarkdownComponent> _components = [
    _CodeBlockMd(),
    LatexMathMultiLine(),
    NewLines(),
    BlockQuote(),
    TableMd(),
    _HeadingTag(),
    UnOrderedList(),
    OrderedList(),
    RadioButtonMd(),
    CheckBoxMd(),
    HrLine(),
    IndentMd(),

    //
    ATagMd(),
    ImageMd(),
    TableMd(),
    StrikeMd(),
    BoldMd(),
    ItalicMd(),
    UnderLineMd(),
    LatexMath(),
    LatexMathMultiLine(),
    _HighlightedText(),
    SourceTag(),
  ];

  const Markdown({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return GptMarkdown(
      text,
      style: style,
      components: _components,
      imageBuilder: (ctx, uri) {
        if (uri.startsWith("http://") || uri.startsWith("https://")) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Image.network(uri),
          );
        } else {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Image.file(File(uri)),
          );
        }
      },
    );
  }
}

class _HeadingTag extends BlockMd {
  @override
  String get expString => (r"(?<hash>#{1,6})\ (?<data>[^\n]+?)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var theme = GptMarkdownTheme.of(context);
    var match = exp.firstMatch(text.trim());
    var conf = config.copyWith(
      style: [
        theme.h1,
        theme.h2,
        theme.h3,
        theme.h4,
        theme.h5,
        theme.h6,
      ][match![1]!.length - 1],
    );
    return config.getRich(
      TextSpan(
        children: [
          ...(MarkdownComponent.generate(
            context,
            "${match.namedGroup('data')}",
            conf,
            false,
          )),
          if (match.namedGroup('hash')!.length == 1) ...[
            const TextSpan(
              text: "\n ",
              style: TextStyle(fontSize: 0, height: 0),
            ),
            WidgetSpan(
              child: CustomDivider(
                height: theme.hrLineThickness,
                color: config.style?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CodeBlockMd extends BlockMd {
  @override
  String get expString => r"```(.*?)\n((.*?)(:?\n\s*?```)|(.*)(:?\n```)?)$";

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    String codes = exp.firstMatch(text)?[2] ?? "";
    String name = exp.firstMatch(text)?[1] ?? "";
    codes = codes.replaceAll(r"```", "");

    final isDark = context.isDark;

    return Padding(
      padding: const .symmetric(vertical: 6),
      child: Container(
        width: .infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[150] : Colors.grey[20],
          borderRadius: .circular(6),
        ),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: .center,
              children: [
                const SizedBox(width: 12),
                const Icon(FluentIcons.embed),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    height: 1,
                    fontSize: 12,
                    fontWeight: .bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(FluentIcons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: codes));
                  },
                ),
                const SizedBox(width: 12),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: .horizontal,
              padding: const .only(top: 6, left: 12, right: 12),
              child: Text(
                codes,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  package: "gpt_markdown",
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedText extends InlineMd {
  @override
  RegExp get exp => RegExp(r"`(?!`)(.+?)(?<!`)`(?!`)");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());
    var highlightedText = match?[1] ?? "";
    final isDark = context.isDark;
    return WidgetSpan(
      child: Container(
        padding: const .symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[140] : Colors.grey[30],
          borderRadius: .circular(4),
        ),
        child: Text(
          highlightedText,
          style: TextStyle(color: Colors.blue.lightest),
        ),
      ),
    );
    // return TextSpan(text: highlightedText, style: style);
  }
}
