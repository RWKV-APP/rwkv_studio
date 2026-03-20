import 'package:rwkv_studio/src/network/bean/model_provider_bean.dart';
import 'package:rwkv_studio/src/network/http.dart';

interface class CommonApi {
  static Future<Map<String, ModelProviderBean>>
  getModelProviderModelCatalog() => HTTP.get(
    'https://models.dev/api.json',
    decoder: (v) {
      return {
        for (var item in v.entries)
          item.key: ModelProviderBean.fromJson(item.value),
      };
    },
  );

  static Future downloadProviderLogoSvg(String providerName, String savePath) =>
      HTTP.download('https://models.dev/logos/$providerName.svg', savePath);
}
