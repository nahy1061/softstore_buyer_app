import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import 'address_state.dart';

class AddressCubit extends Cubit<AddressState> {
  final AddressService _addressService;

  AddressCubit({AddressService? addressService})
      : _addressService = addressService ?? AddressService(),
        super(const AddressInitial());

  List<Address> get _currentAddresses {
    final s = state;
    if (s is AddressLoaded) return s.addresses;
    if (s is AddressAdding) return s.addresses;
    if (s is AddressAddSuccess) return s.addresses;
    if (s is AddressUpdating) return s.addresses;
    if (s is AddressUpdateSuccess) return s.addresses;
    if (s is AddressDeleting) return s.addresses;
    if (s is AddressDeleteSuccess) return s.addresses;
    return [];
  }

  /// Load all addresses (API Mapping #26)
  Future<void> loadAddresses() async {
    emit(const AddressLoading());
    try {
      final addresses = await _addressService.getAddresses();
      emit(AddressLoaded(addresses: addresses));
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(AddressError(message: cleanMsg));
      emit(AddressLoaded(addresses: _currentAddresses));
    }
  }

  /// Add a new address (API Mapping #27)
  Future<void> addAddress(Address address) async {
    final currentAddresses = _currentAddresses;
    emit(AddressAdding(addresses: currentAddresses));

    try {
      await _addressService.addAddress(address: address);
      
      // Fetch fresh verified list from server DB
      List<Address> freshAddresses;
      try {
        freshAddresses = await _addressService.getAddresses();
      } catch (_) {
        final newId = address.id ?? (DateTime.now().millisecondsSinceEpoch % 1000000);
        final cleanAddress = address.copyWith(id: newId);
        freshAddresses = List<Address>.from(currentAddresses);
        if (cleanAddress.isDefault) {
          freshAddresses = freshAddresses.map((a) => a.copyWith(isDefault: false)).toList();
        }
        freshAddresses.add(cleanAddress);
      }

      emit(AddressAddSuccess(
        addresses: freshAddresses,
        message: 'Address added successfully',
      ));
      emit(AddressLoaded(addresses: freshAddresses));
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(AddressError(message: cleanMsg));
      emit(AddressLoaded(addresses: currentAddresses));
    }
  }

  /// Update an existing address in-place (API Mapping #28 + #27)
  Future<void> updateAddress(Address address) async {
    final currentAddresses = _currentAddresses;
    emit(AddressUpdating(addresses: currentAddresses));

    try {
      await _addressService.updateAddress(address: address);

      // Fetch fresh verified list from server DB
      List<Address> freshAddresses;
      try {
        freshAddresses = await _addressService.getAddresses();
      } catch (_) {
        freshAddresses = List<Address>.from(currentAddresses);
        if (address.isDefault) {
          freshAddresses = freshAddresses.map((a) => a.copyWith(isDefault: false)).toList();
        }
        final index = freshAddresses.indexWhere((a) =>
            (address.id != null && a.id == address.id) ||
            (a.name == address.name && a.address == address.address));
        if (index != -1) {
          freshAddresses[index] = address;
        } else {
          freshAddresses.add(address);
        }
      }

      emit(AddressUpdateSuccess(
        addresses: freshAddresses,
        message: 'Address updated successfully',
      ));
      emit(AddressLoaded(addresses: freshAddresses));
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(AddressError(message: cleanMsg));
      emit(AddressLoaded(addresses: currentAddresses));
    }
  }

  /// Delete an address (API Mapping #28)
  Future<void> deleteAddress(int addressId) async {
    final currentAddresses = _currentAddresses;
    emit(AddressDeleting(addresses: currentAddresses));

    try {
      await _addressService.deleteAddress(addressId);

      // Fetch fresh verified list from server DB
      List<Address> freshAddresses;
      try {
        freshAddresses = await _addressService.getAddresses();
      } catch (_) {
        freshAddresses = currentAddresses.where((a) => a.id != addressId).toList();
      }

      emit(AddressDeleteSuccess(
        addresses: freshAddresses,
        message: 'Address deleted successfully',
      ));
      emit(AddressLoaded(addresses: freshAddresses));
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(AddressError(message: cleanMsg));
      emit(AddressLoaded(addresses: currentAddresses));
    }
  }

  /// Delete an address by item reference
  Future<void> deleteAddressByItem(Address address) async {
    if (address.id != null) {
      await deleteAddress(address.id!);
      return;
    }
    final currentAddresses = _currentAddresses;
    emit(AddressDeleting(addresses: currentAddresses));
    final updatedAddresses = currentAddresses
        .where((a) => !(a.name == address.name && a.address == address.address))
        .toList();
    emit(AddressDeleteSuccess(
      addresses: updatedAddresses,
      message: 'Address deleted successfully',
    ));
    emit(AddressLoaded(addresses: updatedAddresses));
  }

  /// Set default address
  Future<void> setDefault(int addressId) async {
    final currentAddresses = _currentAddresses;
    try {
      final target = currentAddresses.firstWhere((a) => a.id == addressId);
      await updateAddress(target.copyWith(isDefault: true));
    } catch (e) {
      final updated = currentAddresses.map((a) {
        return a.copyWith(isDefault: a.id == addressId);
      }).toList();
      emit(AddressLoaded(addresses: updated));
    }
  }

  void reset() => emit(const AddressInitial());
}
