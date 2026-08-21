import 'package:equatable/equatable.dart';
import '../models/address_model.dart';

abstract class AddressState extends Equatable {
  const AddressState();

  @override
  List<Object?> get props => [];
}

class AddressInitial extends AddressState {
  const AddressInitial();
}

class AddressLoading extends AddressState {
  const AddressLoading();
}

class AddressLoaded extends AddressState {
  final List<Address> addresses;

  const AddressLoaded({required this.addresses});

  @override
  List<Object?> get props => [addresses];
}

class AddressAdding extends AddressState {
  final List<Address> addresses;

  const AddressAdding({required this.addresses});

  @override
  List<Object?> get props => [addresses];
}

class AddressAddSuccess extends AddressState {
  final List<Address> addresses;
  final String message;

  const AddressAddSuccess({
    required this.addresses,
    required this.message,
  });

  @override
  List<Object?> get props => [addresses, message];
}

class AddressUpdating extends AddressState {
  final List<Address> addresses;

  const AddressUpdating({required this.addresses});

  @override
  List<Object?> get props => [addresses];
}

class AddressUpdateSuccess extends AddressState {
  final List<Address> addresses;
  final String message;

  const AddressUpdateSuccess({
    required this.addresses,
    required this.message,
  });

  @override
  List<Object?> get props => [addresses, message];
}

class AddressDeleting extends AddressState {
  final List<Address> addresses;

  const AddressDeleting({required this.addresses});

  @override
  List<Object?> get props => [addresses];
}

class AddressDeleteSuccess extends AddressState {
  final List<Address> addresses;
  final String message;

  const AddressDeleteSuccess({
    required this.addresses,
    required this.message,
  });

  @override
  List<Object?> get props => [addresses, message];
}

class AddressError extends AddressState {
  final String message;

  const AddressError({required this.message});

  @override
  List<Object?> get props => [message];
}
