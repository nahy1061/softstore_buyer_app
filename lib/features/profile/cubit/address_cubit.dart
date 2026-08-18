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
      emit(AddressError(message: e.toString()));
    }
  }

  /// Add a new address (API Mapping #27)
  Future<void> addAddress(Address address) async {
    final currentAddresses = _currentAddresses;
    emit(AddressAdding(addresses: currentAddresses));
    try {
      await _addressService.addAddress(address: address);
      final updatedAddresses = [...currentAddresses, address];
      emit(AddressAddSuccess(
        addresses: updatedAddresses,
        message: 'Address added successfully',
      ));
      emit(AddressLoaded(addresses: updatedAddresses));
    } catch (e) {
      emit(AddressError(message: e.toString()));
      emit(AddressLoaded(addresses: currentAddresses));
    }
  }

  /// Delete an address (API Mapping #28)
  Future<void> deleteAddress(int addressId) async {
    final currentAddresses = _currentAddresses;
    emit(AddressDeleting(addresses: currentAddresses));
    try {
      await _addressService.deleteAddress(addressId);
      final updatedAddresses =
          currentAddresses.where((a) => a.id != addressId).toList();
      emit(AddressDeleteSuccess(
        addresses: updatedAddresses,
        message: 'Address deleted successfully',
      ));
      emit(AddressLoaded(addresses: updatedAddresses));
    } catch (e) {
      emit(AddressError(message: e.toString()));
      emit(AddressLoaded(addresses: currentAddresses));
    }
  }

  /// Set default address (client-side)
  void setDefault(int addressId) {
    final currentAddresses = _currentAddresses;
    final updated = currentAddresses.map((a) {
      return a.copyWith(isDefault: a.id == addressId);
    }).toList();
    emit(AddressLoaded(addresses: updated));
  }

  void reset() => emit(const AddressInitial());
}
