import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:softstore_buyer_app/core/network/dio_client.dart';
import 'package:softstore_buyer_app/core/network/http_overrides.dart';
import 'package:softstore_buyer_app/features/catalog/repository/catalog_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  test('Test CatalogRepository.getHomepage() live fetching with initialized DioClient', () async {
    HttpOverrides.global = SoftStoreHttpOverrides();

    print('Initializing DioClient...');
    await DioClient().init();

    print('Calling CatalogRepository.instance.getHomepage()...');
    final data = await CatalogRepository.instance.getHomepage();

    print('Hero Banners count: ${data.heroBanners.length}');
    print('Categories count: ${data.categories.length}');
    print('Top Deals count: ${data.topDeals.length}');
    print('Featured Products count: ${data.featuredProducts.length}');

    for (var i = 0; i < data.featuredProducts.length; i++) {
      final p = data.featuredProducts[i];
      print('Product #$i: id=${p.id}, name="${p.name}", price=${p.displayPrice}, slug="${p.slug}", img="${p.imageUrl}"');
    }

    for (var i = 0; i < data.categories.length; i++) {
      final c = data.categories[i];
      print('Category #$i: name="${c.name}", slug="${c.slug}"');
    }

    print('\nTesting category product fetching for general...');
    final catRes = await CatalogRepository.instance.searchProducts(query: '', category: 'general');
    print('Category general products: ${catRes.products.length}');
    for (var p in catRes.products) {
      print('  - ${p.name} (Rs ${p.displayPrice}) img: ${p.imageUrl}');
    }

    print('\nTesting product image direct download from server...');
    if (catRes.products.isNotEmpty && catRes.products.first.imageUrl != null) {
      final imgUrl = catRes.products.first.imageUrl!;
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      client.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';
      final request = await client.getUrl(Uri.parse(imgUrl));
      final response = await request.close();
      print('HttpClient Image fetch result for $imgUrl: status=${response.statusCode}, contentLength=${response.contentLength}');
      client.close();
    }
  });
}
