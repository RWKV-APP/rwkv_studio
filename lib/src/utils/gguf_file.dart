import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class GgufValueType {
  static const int uint8 = 0;
  static const int int8 = 1;
  static const int uint16 = 2;
  static const int int16 = 3;
  static const int uint32 = 4;
  static const int int32 = 5;
  static const int float32 = 6;
  static const int bool_ = 7;
  static const int string = 8;
  static const int array = 9;
  static const int uint64 = 10;
  static const int int64 = 11;
  static const int float64 = 12;
}

class GgufTypedValue {
  final int type;
  final int? subType; // only for arrays
  final Object? value;

  const GgufTypedValue({required this.type, this.subType, required this.value});

  @override
  String toString() =>
      'GgufTypedValue(type=$type, subType=$subType, value=$value)';
}

class GgufFile {
  static Future<Map<String, GgufTypedValue>> readMetadata(
    String path, {
    Endian endian = Endian.little,
    int? maxArrayElements,
  }) async {
    final raf = await File(path).open();
    final r = _BinReader(raf, endian: endian);

    try {
      final magic = await r.u32();
      const ggufMagic = 0x46554747; // "GGUF"
      if (magic != ggufMagic) {
        throw StateError(
          'Not a GGUF file (magic=0x${magic.toRadixString(16)})',
        );
      }

      final version = await r.u32();
      final tensorCount = await r.u64();
      final kvCount = await r.u64();

      final out = <String, GgufTypedValue>{
        'magic': GgufTypedValue(type: GgufValueType.uint32, value: magic),
        'version': GgufTypedValue(type: GgufValueType.uint32, value: version),
        'tensor_count': GgufTypedValue(
          type: GgufValueType.uint64,
          value: tensorCount,
        ),
        'kv_count': GgufTypedValue(type: GgufValueType.uint64, value: kvCount),
      };

      final n = kvCount.toInt();
      for (var i = 0; i < n; i++) {
        final key = await r.ggufString();
        final type = await r.u32();
        final val = await _readValue(
          r,
          type,
          maxArrayElements: maxArrayElements,
        );
        out[key] = val;
      }

      return out;
    } finally {
      await raf.close();
    }
  }

  static Future<GgufTypedValue> _readValue(
    _BinReader r,
    int type, {
    int? maxArrayElements,
  }) async {
    switch (type) {
      case GgufValueType.uint8:
        return GgufTypedValue(type: type, value: (await r.readN(1))[0]);
      case GgufValueType.int8:
        return GgufTypedValue(
          type: type,
          value: ByteData.sublistView(await r.readN(1)).getInt8(0),
        );
      case GgufValueType.uint16:
        return GgufTypedValue(
          type: type,
          value: ByteData.sublistView(await r.readN(2)).getUint16(0, r.endian),
        );
      case GgufValueType.int16:
        return GgufTypedValue(
          type: type,
          value: ByteData.sublistView(await r.readN(2)).getInt16(0, r.endian),
        );
      case GgufValueType.uint32:
        return GgufTypedValue(type: type, value: await r.u32());
      case GgufValueType.int32:
        return GgufTypedValue(type: type, value: await r.i32());
      case GgufValueType.float32:
        return GgufTypedValue(type: type, value: await r.f32());
      case GgufValueType.float64:
        return GgufTypedValue(type: type, value: await r.f64());
      case GgufValueType.bool_:
        return GgufTypedValue(type: type, value: await r.bool1());
      case GgufValueType.string:
        return GgufTypedValue(type: type, value: await r.ggufString());
      case GgufValueType.uint64:
        return GgufTypedValue(type: type, value: await r.u64());
      case GgufValueType.int64:
        return GgufTypedValue(type: type, value: await r.i64());
      case GgufValueType.array:
        final elemType = await r.u32();
        final len = (await r.u64()).toInt();
        final take = (maxArrayElements != null && len > maxArrayElements)
            ? maxArrayElements
            : len;

        final list = <Object?>[];
        list.length = take;

        for (var i = 0; i < take; i++) {
          // 数组元素本身“没有额外 type 字段”，按 elemType 解码
          final v = await _readValue(
            r,
            elemType,
            maxArrayElements: maxArrayElements,
          );
          list[i] = v.value;
        }

        // 如果你限制了 maxArrayElements，需要把剩余元素“跳过”
        for (var i = take; i < len; i++) {
          await _skipValue(r, elemType);
        }

        return GgufTypedValue(type: type, subType: elemType, value: list);
      default:
        throw StateError('Unknown GGUF value type: $type');
    }
  }

  static Future<void> _skipValue(_BinReader r, int type) async {
    // 只用于“跳过数组剩余元素”，实现尽量完整一点
    int szOfScalar(int t) {
      switch (t) {
        case GgufValueType.uint8:
        case GgufValueType.int8:
        case GgufValueType.bool_:
          return 1;
        case GgufValueType.uint16:
        case GgufValueType.int16:
          return 2;
        case GgufValueType.uint32:
        case GgufValueType.int32:
        case GgufValueType.float32:
          return 4;
        case GgufValueType.uint64:
        case GgufValueType.int64:
        case GgufValueType.float64:
          return 8;
        default:
          return -1;
      }
    }

    if (type == GgufValueType.string) {
      await r.ggufString();
      return;
    }

    if (type == GgufValueType.array) {
      final elemType = await r.u32();
      final len = (await r.u64()).toInt();
      for (var i = 0; i < len; i++) {
        await _skipValue(r, elemType);
      }
      return;
    }

    final sz = szOfScalar(type);
    if (sz < 0) throw StateError('Cannot skip unknown type: $type');
    await r.readN(sz); // discard
  }
}

class _BinReader {
  _BinReader(this.f, {this.endian = Endian.little});

  final RandomAccessFile f;
  final Endian endian;

  Future<Uint8List> readN(int n) async {
    final buf = Uint8List(n);
    final got = await f.readInto(buf);
    if (got != n) throw StateError('Unexpected EOF');
    return buf;
  }

  Future<int> u32() async {
    final b = await readN(4);
    return ByteData.sublistView(b).getUint32(0, endian);
  }

  Future<int> i32() async {
    final b = await readN(4);
    return ByteData.sublistView(b).getInt32(0, endian);
  }

  Future<double> f32() async {
    final b = await readN(4);
    return ByteData.sublistView(b).getFloat32(0, endian);
  }

  Future<double> f64() async {
    final b = await readN(8);
    return ByteData.sublistView(b).getFloat64(0, endian);
  }

  Future<bool> bool1() async {
    final b = await readN(1);
    if (b[0] == 0) return false;
    if (b[0] == 1) return true;
    throw StateError('Invalid bool value ${b[0]}');
  }

  Future<BigInt> u64() async {
    final b = await readN(8);
    BigInt x = BigInt.zero;
    if (endian == Endian.little) {
      for (var i = 7; i >= 0; i--) {
        x = (x << 8) | BigInt.from(b[i]);
      }
    } else {
      for (var i = 0; i < 8; i++) {
        x = (x << 8) | BigInt.from(b[i]);
      }
    }
    return x;
  }

  Future<BigInt> i64() async {
    final b = await readN(8);
    // read as unsigned then convert two's complement if sign bit set
    BigInt u = BigInt.zero;
    if (endian == Endian.little) {
      for (var i = 7; i >= 0; i--) {
        u = (u << 8) | BigInt.from(b[i]);
      }
    } else {
      for (var i = 0; i < 8; i++) {
        u = (u << 8) | BigInt.from(b[i]);
      }
    }
    final signBit = BigInt.one << 63;
    if ((u & signBit) == BigInt.zero) return u;
    final mod = BigInt.one << 64;
    return u - mod;
  }

  Future<String> ggufString() async {
    final lenBI = await u64();
    final len = lenBI.toInt(); // 现实里不会大到爆 int
    if (len == 0) return '';
    final b = await readN(len);
    return utf8.decode(b, allowMalformed: true);
  }
}
