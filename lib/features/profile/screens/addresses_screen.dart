import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../app/router.dart';
import '../cubit/address_cubit.dart';
import '../cubit/address_state.dart';
import '../models/address_model.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<AddressCubit>();
    if (cubit.state is AddressInitial) {
      cubit.loadAddresses();
    }
  }

  void _delete(Address address) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (address.id != null) {
                context.read<AddressCubit>().deleteAddress(address.id!);
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Saved Addresses', style: AppTypography.screenTitle),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<AddressCubit, AddressState>(
        listener: (context, state) {
          if (state is AddressAddSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AddressDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AddressError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AddressLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final addresses = state is AddressLoaded
              ? state.addresses
              : state is AddressAdding
                  ? state.addresses
                  : state is AddressAddSuccess
                      ? state.addresses
                      : state is AddressDeleting
                          ? state.addresses
                          : state is AddressDeleteSuccess
                              ? state.addresses
                              : <Address>[];

          if (addresses.isEmpty) {
            return _EmptyAddresses(onAdd: () => context.go(AppRoutes.addressAdd));
          }

          return ListView.separated(
            padding: AppSpacing.paddingLg,
            itemCount: addresses.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _AddressCard(
                address: address,
                onSetDefault: () {
                  if (address.id != null) {
                    context.read<AddressCubit>().setDefault(address.id!);
                  }
                },
                onEdit: () =>
                    context.go('/addresses/edit/${address.id}'),
                onDelete: () => _delete(address),
              );
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<AddressCubit, AddressState>(
        builder: (context, state) {
          final addresses = state is AddressLoaded
              ? state.addresses
              : state is AddressAdding
                  ? state.addresses
                  : state is AddressAddSuccess
                      ? state.addresses
                      : state is AddressDeleting
                          ? state.addresses
                          : state is AddressDeleteSuccess
                              ? state.addresses
                              : <Address>[];

          if (addresses.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => context.go(AppRoutes.addressAdd),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Address',
                style: TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.radiusMd,
        border: Border.all(
          color: address.isDefault ? AppColors.primary : AppColors.divider,
          width: address.isDefault ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppDimensions.radiusSm,
                ),
                child: Text(
                  address.label,
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.primary),
                ),
              ),
              if (address.isDefault) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: AppDimensions.radiusSm,
                  ),
                  child: Text(
                    'Default',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.success),
                  ),
                ),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                  if (value == 'default') onSetDefault();
                },
                itemBuilder: (_) => [
                  if (!address.isDefault)
                    const PopupMenuItem(
                        value: 'default',
                        child: Text('Set as Default')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
                child: const Icon(Icons.more_vert,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(address.name,
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(address.phone,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            address.city.isNotEmpty
                ? '${address.address}, ${address.city}'
                : address.address,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyAddresses({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_outlined,
                size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.lg),
            Text('No Saved Addresses',
                style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add a delivery address to speed up your checkout',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Address'),
            ),
          ],
        ),
      ),
    );
  }
}
