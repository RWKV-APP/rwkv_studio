import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:rwkv_studio/objectbox.g.dart';
import 'package:rwkv_studio/src/entity.dart';

import 'app.dart' show rwkv;

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  String model = '';
  List<String> documents = [];
  List<Embeddings> searchResults = [];
  late ObjectBox obx;
  late Box<Embeddings> embeddings;
  TextEditingController controller = TextEditingController();

  void search() async {
    final c = embeddings.count();
    print(c);
  }

  void initEmbedding() async {
    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[XTypeGroup()],
    );
    if (file == null) {
      return;
    }
    await rwkv.loadEmbedding(file.path);
    setState(() {
      model = file.name;
    });
  }

  void addDocument() async {
    print('add');
    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[XTypeGroup()],
    );
    if (file == null) {
      return;
    }

    String text = """
水, 火, 山, 河, 树, 花, 草, 太阳, 月亮, 星星, 云, 雨, 雪, 风, 土地, 海洋, 沙漠, 森林, 石头, 沙子, 狗, 猫, 鸟, 鱼, 马, 牛, 老虎, 蝴蝶, 蜜蜂, 蚂蚁, 人, 手, 脚, 眼睛, 家庭, 朋友, 老师, 医生, 学生, 孩子, 城市, 村庄, 道路, 桥梁, 学校, 医院, 商店, 书籍, 语言, 音乐, 艺术, 电影, 节日, 宗教, 法律, 战争, 和平, 权力, 自由, 正义, 桌子, 椅子, 灯, 门, 窗户, 汽车, 飞机, 火车, 船, 电脑, 手机, 网络, 机器人, 电力, 引擎, 工具, 钥匙, 钟表, 镜子, 衣服, 数据, 算法, 密码, 屏幕, 电池, 苹果, 面包, 米饭, 牛奶, 咖啡, 蔬菜, 肉, 糖, 盐, 房子, 床, 厨房, 钱, 游戏, 球, 礼物, 照片, 纸张, 笔, 时间, 空间, 爱, 恨, 快乐, 悲伤, 知识, 思想, 梦, 记忆, 原因, 结果, 变化, 速度, 温度, 颜色, 形状, 数字, 系统, 概率, 原子, 细胞, 基因, 氧气, 磁场, 重力, 光速, 货币, 交易, 市场, 工资, 利润, 债务, 病毒, 疫苗, 器官, 手术, 疼痛, 地震, 火山, 彩虹, 季节, 潮汐, 工程师, 农民, 厨师, 警察, 作家, 狮子, 大象, 鲨鱼, 蜘蛛, 鸽子, 玫瑰, 松树, 麦田, 湖泊, 岛屿, 冰川, 流星, 雾气, 雷电, 冰雹, 父亲, 母亲, 兄弟, 姐妹, 邻居, 同事, 领导, 顾客, 游客, 婴儿, 青年, 老人, 国王, 总统, 士兵, 法官, 律师, 教授, 歌手, 演员, 首都, 机场, 港口, 公园, 博物馆, 图书馆, 教堂, 寺庙, 监狱, 工厂, 农场, 办公室, 卧室, 浴室, 餐厅, 花园, 钢琴, 吉他, 舞蹈, 绘画, 雕塑, 诗歌, 小说, 戏剧, 电视, 广播, 报纸, 杂志, 相机, 冰箱, 烤箱, 洗衣机, 空调, 电梯, 自行车, 摩托车, 卡车, 地铁, 火箭, 卫星, 芯片, 软件, 程序, 网站, 账户, 文件, 文件夹, 打印机, 键盘, 鼠标, 耳机, 喇叭, 香蕉, 橙子, 葡萄, 鸡蛋, 奶酪, 茶, 果汁, 啤酒, 葡萄酒, 巧克力, 蛋糕, 饼干, 面条, 饺子, 披萨, 汉堡, 沙发, 地毯, 窗帘, 花瓶, 相框, 玩具, 拼图, 卡片, 蜡烛, 香水, 肥皂, 牙刷, 毛巾, 枕头, 戒指, 项链, 手表, 钱包, 背包, 雨伞, 眼镜, 帽子, 鞋子, 衬衫, 裙子, 裤子, 外套, 勇气, 恐惧, 希望, 失望, 信任, 怀疑, 诚实, 欺骗, 智慧, 愚蠢, 美丽, 丑陋, 力量, 弱点, 成功, 失败, 开始, 结束, 机会, 风险, 证据, 理论, 事实, 观点, 问题, 答案, 方法, 策略, 计划, 目标, 质量, 数量, 程度, 比例, 中心, 边缘, 表面, 深度, 高度, 宽度, 长度, 体积, 重量, 压力, 能量, 声音, 光线, 阴影, 图像, 模型, 结构, 功能, 过程, 状态, 事件, 经历, 关系, 区别, 矛盾, 平衡, 混乱, 秩序, 模式, 趋势, 发展, 进步, 衰退, 增长, 减少, 创造, 破坏, 建设, 生产, 消费, 需求, 供给, 价值, 价格, 成本, 利润, 收入, 支出, 税收, 利息, 贷款, 投资, 储蓄, 财产, 资源, 材料, 金属, 塑料, 木材, 玻璃, 陶瓷, 棉花, 丝绸, 皮革, 橡胶, 煤炭, 石油, 天然气, 黄金, 白银, 钻石, 铜, 铁, 铝, 氧气, 氮气, 氢气, 二氧化碳, 酸, 碱, 盐, 蛋白质, 脂肪, 维生素, 纤维, 淀粉, 激素, 酶, 抗体, 细菌, 真菌, 病毒, 寄生虫, 花粉, 种子, 根, 茎, 叶, 果实, 树皮, 年轮, 羽毛, 鳞片, 爪子, 牙齿, 舌头, 鼻子, 耳朵, 皮肤, 血液, 骨骼, 肌肉, 神经, 大脑, 心脏, 肺, 胃, 肝, 肾, 肠, 血管, 细胞膜, 染色体, DNA, RNA, 蛋白质合成, 基因表达, 进化, 遗传, 变异, 物种, 生态系统, 食物链, 栖息地, 污染, 回收, 能源, 太阳能, 风能, 水能, 核能, 生物燃料, 温室效应, 臭氧层, 生物多样性, 自然保护区, 天气预报, 气候, 温度计, 气压计, 湿度, 干旱, 洪水, 台风, 龙卷风, 海啸, 雪崩, 火灾, 事故, 急救, 康复, 治疗, 诊断, 症状, 疾病, 健康, 营养, 锻炼, 瑜伽, 冥想, 心理, 情绪, 压力, 焦虑, 抑郁, 快乐, 满足, 幸福, 悲伤, 愤怒, 惊讶, 恐惧, 厌恶, 信任, 爱慕, 嫉妒, 羞愧, 骄傲, 谦虚, 礼貌, 粗鲁, 耐心, 急躁, 宽容, 苛刻, 慷慨, 吝啬, 勇敢, 懦弱, 诚实, 虚伪, 忠诚, 背叛, 责任, 义务, 权利, 特权, 公平, 偏见, 歧视, 平等, 自由, 正义, 法律, 规则, 政策, 制度, 政府, 民主, 专制, 选举, 投票, 革命, 改革, 传统, 创新, 文化, 习俗, 仪式, 语言, 方言, 文字, 符号, 数字, 字母, 单词, 句子, 语法, 意义, 语境, 翻译, 解释, 理解, 误解, 沟通, 对话, 争论, 协议, 合同, 承诺, 保证, 证据, 证明, 理论, 假设, 实验, 观察, 数据, 统计, 样本, 误差, 精度, 可靠性, 有效性, 质量, 标准, 测量, 计算, 公式, 方程, 几何, 代数, 微积分, 概率, 统计, 逻辑, 推理, 演绎, 归纳, 悖论, 谜题, 游戏, 策略, 竞争, 合作, 团队, 组织, 公司, 企业, 产业, 市场, 经济, 金融, 银行, 货币, 交易, 价格, 价值, 成本, 利润, 投资, 风险, 收益, 资产, 负债, 股票, 债券, 基金, 利息, 汇率, 通货膨胀, 衰退, 增长, 发展, 创新, 技术, 科学, 研究, 发现, 发明, 专利, 版权, 商标, 互联网, 计算机, 软件, 硬件, 网络, 数据, 信息, 知识, 智慧, 教育, 学习, 教学, 培训, 学校, 大学, 课程, 考试, 学位, 证书, 技能, 能力, 经验, 职业, 工作,
    """;
    final lines = text
        .split(RegExp('(，|。|\n|；|,)'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    print('read ${lines.length} lines');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.length > 200) {
        final ss = line
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        for (var j = 0; j < ss.length; j++) {
          final s = ss[j];
          final v = await rwkv.embed(s);
          final eb = Embeddings()
            ..name = s
            ..segment = v.map((e) => e.toDouble()).toList();
          print('put $i.$j => ${s.length}');
          await embeddings.putAsync(eb);
        }
      } else {
        final v = await rwkv.embed(line);
        final eb = Embeddings()
          ..segment = v.map((e) => e.toDouble()).toList()
          ..name = line;
        print('put $i => ${line.length}');
        await embeddings.putAsync(eb);
      }
    }
    print('done');
  }

  void initObx() async {
    obx = await ObjectBox.create();
    embeddings = obx.store.box<Embeddings>();
  }

  void onSearch(String keywords) async {
    if (keywords == '-') {
      final r = embeddings.removeAll();
      print('remove $r');
      return;
    }
    if (keywords == " ") {
      setState(() {
        searchResults = embeddings.getAll();
      });
      return;
    }
    print('search $keywords');
    final v = await rwkv.embed(keywords);
    print('vec: $v');
    final res = embeddings
        .query(
          Embeddings_.segment.nearestNeighborsF32(
            v.map((e) => e.toDouble()).toList(),
            40,
          ),
        )
        .build()
        .find();
    setState(() {
      searchResults = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Documents',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(onPressed: addDocument, icon: Icon(Icons.add)),
                  ],
                ),
                Divider(),
              ],
            ),
          ),
          VerticalDivider(),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    FilledButton(onPressed: initObx, child: Text('init obx')),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: initEmbedding,
                      child: Text(model.isEmpty ? 'init embedding' : model),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(onPressed: search, child: Text('Search')),
                  ],
                ),
                const SizedBox(height: 16),
                SearchBar(onSubmitted: onSearch),
                Expanded(
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (c, i) {
                      final t = searchResults[i];
                      return ListTile(
                        title: Text(t.name ?? '-'),
                        subtitle: Text(
                          t.segment.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
