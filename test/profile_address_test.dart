import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:softstore_buyer_app/features/profile/cubit/address_cubit.dart';
import 'package:softstore_buyer_app/features/profile/cubit/address_state.dart';
import 'package:softstore_buyer_app/features/profile/models/address_model.dart';
import 'package:softstore_buyer_app/features/profile/services/address_service.dart';

class MockAddressService extends Mock implements AddressService {}

void main() {
  late MockAddressService mockAddressService;

  setUp(() {
    mockAddressService = MockAddressService();
  });

  group('Address Model', () {
    test('toJson and fromJson work correctly', () {
      const address = Address(
        id: 101,
        label: 'Home',
        name: 'Ali Khan',
        phone: '03001234567',
        address: 'House 1, Street 2',
        city: 'Islamabad',
        isDefault: true,
      );

      final json = address.toJson();
      expect(json['label'], 'Home');
      expect(json['name'], 'Ali Khan');
      expect(json['phone'], '03001234567');
      expect(json['address'], 'House 1, Street 2');
      expect(json['city'], 'Islamabad');
      expect(json['set_default'], true);

      final fromJson = Address.fromJson({
        'id': 101,
        'label': 'Home',
        'name': 'Ali Khan',
        'phone': '03001234567',
        'address': 'House 1, Street 2',
        'city': 'Islamabad',
        'is_default': true,
      });
      expect(fromJson, equals(address));
    });
  });

  group('AddressCubit', () {
    const testAddress = Address(
      id: 1,
      label: 'Home',
      name: 'John Doe',
      phone: '03001234567',
      address: '123 Main St',
      city: 'Lahore',
      isDefault: true,
    );

    blocTest<AddressCubit, AddressState>(
      'loadAddresses emits [AddressLoading, AddressLoaded] on success',
      build: () {
        when(() => mockAddressService.getAddresses())
            .thenAnswer((_) async => [testAddress]);
        return AddressCubit(addressService: mockAddressService);
      },
      act: (cubit) => cubit.loadAddresses(),
      expect: () => [
        const AddressLoading(),
        const AddressLoaded(addresses: [testAddress]),
      ],
      verify: (_) {
        verify(() => mockAddressService.getAddresses()).called(1);
      },
    );

    blocTest<AddressCubit, AddressState>(
      'loadAddresses emits [AddressLoading, AddressError, AddressLoaded] on failure',
      build: () {
        when(() => mockAddressService.getAddresses())
            .thenThrow(Exception('Server unreachable'));
        return AddressCubit(addressService: mockAddressService);
      },
      act: (cubit) => cubit.loadAddresses(),
      expect: () => [
        const AddressLoading(),
        const AddressError(message: 'Server unreachable'),
        const AddressLoaded(addresses: []),
      ],
    );

    blocTest<AddressCubit, AddressState>(
      'addAddress emits [AddressAdding, AddressAddSuccess, AddressLoaded] on success',
      build: () {
        when(() => mockAddressService.addAddress(address: testAddress))
            .thenAnswer((_) async {});
        when(() => mockAddressService.getAddresses())
            .thenAnswer((_) async => [testAddress]);
        return AddressCubit(addressService: mockAddressService);
      },
      act: (cubit) => cubit.addAddress(testAddress),
      expect: () => [
        const AddressAdding(addresses: []),
        const AddressAddSuccess(
          addresses: [testAddress],
          message: 'Address added successfully',
        ),
        const AddressLoaded(addresses: [testAddress]),
      ],
      verify: (_) {
        verify(() => mockAddressService.addAddress(address: testAddress)).called(1);
      },
    );

    blocTest<AddressCubit, AddressState>(
      'deleteAddress emits [AddressDeleting, AddressDeleteSuccess, AddressLoaded] on success',
      build: () {
        when(() => mockAddressService.deleteAddress(1))
            .thenAnswer((_) async {});
        when(() => mockAddressService.getAddresses())
            .thenAnswer((_) async => []);
        return AddressCubit(addressService: mockAddressService);
      },
      act: (cubit) => cubit.deleteAddress(1),
      expect: () => [
        const AddressDeleting(addresses: []),
        const AddressDeleteSuccess(
          addresses: [],
          message: 'Address deleted successfully',
        ),
        const AddressLoaded(addresses: []),
      ],
      verify: (_) {
        verify(() => mockAddressService.deleteAddress(1)).called(1);
      },
    );
  });
}
