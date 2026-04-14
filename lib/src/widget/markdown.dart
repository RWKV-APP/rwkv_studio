import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/custom_widgets/custom_divider.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/native_utils.dart';
import 'package:rwkv_studio/src/widget/markdown_table.dart';

class Markdown extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const Markdown({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return GptMarkdown(
      text,
      style: style,
      components: [
        _CodeBlockMd(),
        _LatexMathMultiLine(),
        _LatexMathMultiLine2(),
        NewLines(),
        BlockQuote(),
        AppTableMd(),
        _HeadingTag(),
        UnOrderedList(),
        OrderedList(),
        RadioButtonMd(),
        _CheckBoxMd(),
        HrLine(),
        IndentMd(),
      ],
      inlineComponents: [
        ATagMd(),
        ImageMd(),
        AppTableMd(),
        StrikeMd(),
        BoldMd(),
        ItalicMd(),
        UnderLineMd(),
        _LatexMath(),
        _LatexMath2(),
        _LatexMathMultiLine(),
        _LatexMathMultiLine2(),
        _HighlightedText(),
        SourceTag(),
      ],
      linkBuilder: (ctx, span, a, style) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              NativeUtils.openUri(a);
            },
            child: Text(
              span.toPlainText(),
              style: style.copyWith(color: Colors.blue),
            ),
          ),
        );
      },
      imageBuilder: (ctx, uri) {
        if (uri.startsWith("http://") || uri.startsWith("https://")) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Image.network(uri),
          );
        } else {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Image.file(File(uri.replaceFirst('file:///', ''))),
          );
        }
      },
    );
  }
}

class _LatexMath extends LatexMath {
  @override
  RegExp get exp => RegExp(r"\\\((.*?)\\\)", dotAll: true);
}

class _LatexMath2 extends LatexMath {
  @override
  RegExp get exp => RegExp(r"(?<!\\)\$((?:\\.|[^$])*?)\$(?!\\)", dotAll: true);
}

class _LatexMathMultiLine extends LatexMathMultiLine {
  @override
  RegExp get exp =>
      RegExp(r"\s*\\\[([\s\S]*?)\\\]", dotAll: true, multiLine: true);

  @override
  Widget build(BuildContext context, String text, GptMarkdownConfig config) {
    final s = super.build(context, text, config);
    return Container(
      alignment: .center,
      width: .infinity,
      margin: const .symmetric(vertical: 12),
      child: s,
    );
  }
}

class _LatexMathMultiLine2 extends _LatexMathMultiLine {
  @override
  RegExp get exp =>
      RegExp(r"\s*\$\$([\s\S]*?)\$\$", dotAll: true, multiLine: true);
}

class _HeadingTag extends HTag {
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
    final rich = config.getRich(
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
    return Container(
      padding: const .only(bottom: 6),
      margin: const .only(bottom: 12),
      width: .infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[40], width: .5)),
      ),
      child: rich,
    );
  }
}

class _CheckBoxMd extends BlockMd {
  @override
  String get expString => (r"\[((?:\x|\ ))\]\ (\S[^\n]*?)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    var match = exp.firstMatch(text.trim());

    return Directionality(
      textDirection: .ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Text.rich(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 6, end: 6),
                child: Checkbox(
                  checked: ("${match?[1]}" == "x"),
                  onChanged: (value) {},
                ),
              ),
            ),
          ),
          Flexible(
            child: MdWidget(context, "${match?[2]}", false, config: config),
          ),
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
          mainAxisSize: .min,
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: SingleChildScrollView(
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
