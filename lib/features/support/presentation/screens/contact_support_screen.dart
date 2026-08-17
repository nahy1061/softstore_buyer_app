import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../models/support_category.dart';
import '../../models/support_ticket_form.dart';
import '../../models/ticket_model.dart';
import '../cubits/support_cubit.dart';
import '../cubits/support_state.dart';

/// Temporary until AuthCubit / profile API is wired (matches profile hub mock).
const _mockLoggedInUserName = 'Arwah Imran';
const _mockLoggedInUserEmail = 'arwah@example.com';
const _mockIsLoggedIn = true;

class ContactSupportScreen extends StatefulWidget {
  final String? orderReference;
  final int? orderId;
  final String? initialSubject;
  final String? initialCategoryLabel;

  const ContactSupportScreen({
    super.key,
    this.orderReference,
    this.orderId,
    this.initialSubject,
    this.initialCategoryLabel,
  });

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String? _selectedCategory;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    if (widget.orderReference != null) {
      _orderNumberController.text = widget.orderReference!;
    }
    if (widget.initialSubject != null) {
      _subjectController.text = widget.initialSubject!;
    }
    _selectedCategory = widget.initialCategoryLabel;
    if (_mockIsLoggedIn) {
      _nameController.text = _mockLoggedInUserName;
      _emailController.text = _mockLoggedInUserEmail;
    }
  }

  int? get _resolvedOrderId =>
      widget.orderId ?? parseNumericOrderId(_orderNumberController.text);

  bool get _hasLinkedOrder => _resolvedOrderId != null;

  bool get _showsInvoiceReferenceOnly {
    final input = _orderNumberController.text.trim();
    if (input.isEmpty) return false;
    return !_hasLinkedOrder && validateOrderReference(input) == null;
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() => _submitError = 'Please select a category');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final submitData = SupportTicketSubmitData.fromForm(
        subject: _subjectController.text,
        message: _messageController.text,
        categoryLabel: _selectedCategory!,
        orderId: _resolvedOrderId,
      );

      if (!mounted) return;
      context.read<SupportCubit>().createTicket(
            subject: submitData.subject,
            message: submitData.message,
            category: submitData.categoryApiValue,
            orderId: submitData.orderId,
            email: _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
            guestName: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : null,
          );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.message;
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog(Ticket ticket) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.radiusLg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 36),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Ticket Submitted!',
              style: AppTypography.sectionHeading
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your ticket ${ticket.displayId} has been created. Our team will respond within 24 hours.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push(AppRoutes.supportTickets);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.radiusMd),
                ),
                child: Text(
                  'View My Tickets',
                  style: AppTypography.buttonText.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                child: Text(
                  'Back to Support',
                  style: AppTypography.buttonText
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupportCubit, SupportState>(
      listener: (context, state) {
        if (state is TicketCreated) {
          setState(() => _isSubmitting = false);
          _showSuccessDialog(state.ticket);
        } else if (state is SupportError) {
          setState(() {
            _isSubmitting = false;
            _submitError = state.message;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Colors.black12,
          leading: const BackButton(color: AppColors.textPrimary),
          title: Text(
            'Contact Support',
            style: AppTypography.screenTitle.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.orderReference != null) _buildOrderContextBanner(),
              _buildTicketFormSection(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderContextBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: AppDimensions.radiusMd,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Reporting an issue for order ${widget.orderReference}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketFormSection() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              'SUBMIT A TICKET',
              style: AppTypography.overline.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _FormCard(
              title: 'Your Details',
              subtitle: _mockIsLoggedIn
                  ? 'Taken from your profile'
                  : 'We\'ll use this to follow up with you',
              icon: Icons.person_outline_rounded,
              child: _mockIsLoggedIn
                  ? _buildProfileSummary()
                  : Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Your Name',
                          hint: 'Enter your full name',
                          icon: Icons.person_outline,
                          validator: Validators.fullName,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            _FormCard(
              title: 'Issue Details',
              subtitle: 'Tell us what happened',
              icon: Icons.description_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _orderNumberController,
                    label: 'Order Number',
                    hint: 'e.g. SS-20240801-0042 (optional)',
                    icon: Icons.receipt_outlined,
                    required: false,
                    readOnly: widget.orderReference != null,
                    validator: validateOrderReference,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_showsInvoiceReferenceOnly) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Order reference saved. It will be linked when the ticket is submitted.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _buildDropdown(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTextField(
                    controller: _subjectController,
                    label: 'Subject',
                    hint: 'Brief description of your issue',
                    icon: Icons.title_rounded,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Subject is required';
                      if (value!.length < 5) return 'Subject is too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTextField(
                    controller: _messageController,
                    label: 'Message',
                    hint: 'Describe your issue in detail...',
                    maxLines: 5,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Message is required';
                      if (value!.length < 20) {
                        return 'Please provide more detail (at least 20 characters)';
                      }
                      return null;
                    },
                  ),
                  if (_submitError != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: AppDimensions.radiusSm,
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _submitError!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.touchTarget,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitTicket,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppDimensions.radiusMd),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Submit Ticket',
                              style: AppTypography.buttonText
                                  .copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: AppDimensions.radiusMd,
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _emailController.text,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Contact details are managed in your profile.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool required = true,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary),
            ),
            if (required)
              Text(' *',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
          onChanged: onChanged,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium
                .copyWith(color: AppColors.textDisabled),
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.textSecondary, size: 20)
                : null,
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: AppDimensions.radiusMd,
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppDimensions.radiusMd,
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppDimensions.radiusMd,
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppDimensions.radiusMd,
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppDimensions.radiusMd,
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle:
                AppTypography.errorText.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Category',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.textPrimary)),
            Text(' *',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          hint: Text('Select a category',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textDisabled)),
          items: kSupportCategories.map((category) {
            return DropdownMenuItem(
              value: category.label,
              child: Text(category.label,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textPrimary)),
            );
          }).toList(),
          onChanged: (value) => setState(() {
            _selectedCategory = value;
            _submitError = null;
          }),
          validator: (value) =>
              value == null ? 'Please select a category' : null,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.category_outlined,
                color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: AppDimensions.radiusMd,
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppDimensions.radiusMd,
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppDimensions.radiusMd,
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppDimensions.radiusMd,
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppDimensions.radiusMd,
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle:
                AppTypography.errorText.copyWith(color: AppColors.error),
          ),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _FormCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.radiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: AppDimensions.radiusSm,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
