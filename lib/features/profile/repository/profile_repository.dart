import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';
import '../../auth/models/user_model.dart';

// ─── Address Model ─────────────────────────────────────────────────────────────

class SavedAddress {
  final int? id;
  final String? label;
  final String name;
  final String phone;
  final String address;
  final bool isDefault;

  const SavedAddress({
    this.id,
    this.label,
    required this.name,
    required this.phone,
    required this.address,
    this.isDefault = false,
  });
}

// ─── DashboardStats ────────────────────────────────────────────────────────────

class DashboardStats {
  final int totalOrders;
  final double totalSpent;
  final int wishlistItems;

  const DashboardStats({
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.wishlistItems = 0,
  });
}

// ─── ProfileRepository ────────────────────────────────────────────────────────

class ProfileRepository {
  ProfileRepository._();
  static final ProfileRepository instance = ProfileRepository._();

  final DioClient _client = DioClient();
  final CsrfService _csrf = CsrfService.instance;

  // ─── Profile ───────────────────────────────────────────────────────────────

  Future<User> getProfile() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.profilePage,
        options: Options(responseType: ResponseType.plain),
      );
      return _parseProfile(response.data ?? '');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.profilePage);

      await _client.post<String>(
        ApiEndpoints.updateProfile,
        data: {
          if (csrfToken != null) '_csrf_token': csrfToken,
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'phone': phone.trim(),
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.profilePage);

      final response = await _client.post<String>(
        ApiEndpoints.changePassword,
        data: {
          if (csrfToken != null) '_csrf_token': csrfToken,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      final html = response.data ?? '';
      final error = HtmlParserUtil.extractFormError(html);
      if (error != null) throw ServerFailure(error);
    } on ServerFailure {
      rethrow;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.dashboard,
        options: Options(responseType: ResponseType.plain),
      );
      return _parseDashboard(response.data ?? '');
    } catch (e) {
      // Dashboard may not exist — return empty stats
      return const DashboardStats();
    }
  }

  // ─── Addresses ─────────────────────────────────────────────────────────────

  Future<List<SavedAddress>> getAddresses() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.addresses,
        options: Options(responseType: ResponseType.plain),
      );
      return _parseAddresses(response.data ?? '');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> addAddress({
    required String name,
    required String phone,
    required String address,
    String? label,
    bool setDefault = false,
  }) async {
    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.addresses);

      await _client.post<String>(
        ApiEndpoints.addresses,
        data: {
          if (csrfToken != null) '_csrf_token': csrfToken,
          if (label != null) 'label': label,
          'name': name.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          if (setDefault) 'set_default': 'true',
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      final path = '${ApiEndpoints.addresses}/$id${ApiEndpoints.deleteAddressSuffix}';
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.addresses);

      await _client.post<String>(
        path,
        data: {if (csrfToken != null) '_csrf_token': csrfToken},
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── Parsers ───────────────────────────────────────────────────────────────

  User _parseProfile(String html) {
    final doc = HtmlParserUtil.parse(html);
    String? inputVal(String name) =>
        doc.querySelector('input[name="$name"]')?.attributes['value']?.trim();

    return User(
      firstName: inputVal('first_name') ?? '',
      lastName: inputVal('last_name') ?? '',
      email: inputVal('email') ?? '',
      phone: inputVal('phone'),
    );
  }

  DashboardStats _parseDashboard(String html) {
    final doc = HtmlParserUtil.parse(html);
    final cards = doc.querySelectorAll('.stat-card, .dashboard-stat, .stat-item');
    int orders = 0;
    double spent = 0;
    int wishlist = 0;

    for (final card in cards) {
      final label = card.querySelector('.label, .title, h6, p')?.text.toLowerCase() ?? '';
      final valueText = card.querySelector('.value, .count, h4, h3')?.text ?? '';
      final value = double.tryParse(
              valueText.replaceAll(',', '').replaceAll('PKR', '').trim()) ??
          0;

      if (label.contains('order')) orders = value.toInt();
      if (label.contains('spent') || label.contains('total')) spent = value;
      if (label.contains('wishlist')) wishlist = value.toInt();
    }

    return DashboardStats(
        totalOrders: orders, totalSpent: spent, wishlistItems: wishlist);
  }

  List<SavedAddress> _parseAddresses(String html) {
    final doc = HtmlParserUtil.parse(html);
    final cards = doc.querySelectorAll('.address-card, .address-item');
    final addresses = <SavedAddress>[];

    for (final card in cards) {
      final idAttr = card.attributes['data-id'] ??
          card.querySelector('button[data-id]')?.attributes['data-id'];
      final id = int.tryParse(idAttr ?? '');
      final label = card.querySelector('.label, .address-label')?.text.trim();
      final name = card.querySelector('.name')?.text.trim() ?? '';
      final phone = card.querySelector('.phone')?.text.trim() ?? '';
      final address = card.querySelector('.address, .address-text')?.text.trim() ?? '';
      final isDefault = card.classes.contains('default') ||
          card.querySelector('.badge-default') != null;

      if (name.isNotEmpty || address.isNotEmpty) {
        addresses.add(SavedAddress(
          id: id,
          label: label,
          name: name,
          phone: phone,
          address: address,
          isDefault: isDefault,
        ));
      }
    }

    return addresses;
  }

  Failure _mapError(DioException e) {
    developer.log('[Profile] DioException: ${e.message}', name: 'profile');
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('No internet connection.');
    }
    return ServerFailure(e.message ?? 'Server error',
        statusCode: e.response?.statusCode);
  }
}
