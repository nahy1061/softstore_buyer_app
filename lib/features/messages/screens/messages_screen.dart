import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../auth/screens/login_screen.dart';
import '../models/conversation_model.dart';
import '../presentation/cubits/messages_list_cubit.dart';
import '../presentation/cubits/messages_list_state.dart';
import '../presentation/widgets/conversation_card.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthCubit>().state;
        final cubit = MessagesListCubit();
        cubit.loadConversations(
          forceRefresh: true,
          isAuthenticated: authState is AuthAuthenticated,
        );
        return cubit;
      },
      child: const _MessagesScreenView(),
    );
  }
}

class _MessagesScreenView extends StatefulWidget {
  const _MessagesScreenView();

  @override
  State<_MessagesScreenView> createState() => _MessagesScreenViewState();
}

class _MessagesScreenViewState extends State<_MessagesScreenView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onThreadTap(BuildContext context, ConversationThread conversation) {
    context.read<MessagesListCubit>().markAsRead(conversation.threadUrl);
    context.push(
      AppRoutes.sellerChat,
      extra: {
        'threadUrl': conversation.threadUrl,
        'threadInfo': conversation,
        'productId': conversation.productId,
        'productName': conversation.productName,
        'productImage': conversation.productImage,
        'sellerName': conversation.sellerName,
      },
    ).then((_) {
      if (context.mounted) {
        final authState = context.read<AuthCubit>().state;
        context.read<MessagesListCubit>().loadConversations(
              forceRefresh: true,
              isAuthenticated: authState is AuthAuthenticated,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, authState) {
        context.read<MessagesListCubit>().loadConversations(
              forceRefresh: true,
              isAuthenticated: authState is AuthAuthenticated,
            );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Colors.black12,
          automaticallyImplyLeading: false,
          title: Text(
            'Messages',
            style: AppTypography.sectionHeading.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: false,
        ),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
        body: BlocBuilder<MessagesListCubit, MessagesListState>(
          builder: (context, state) {
            if (state is MessagesListUnauthenticated) {
              return _buildUnauthenticatedView(context);
            }

            if (state is MessagesListLoading || state is MessagesListInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is MessagesListError) {
              return _buildErrorView(context, state.message);
            }

            if (state is MessagesListEmpty) {
              return _buildEmptyView(context);
            }

            if (state is MessagesListLoaded) {
              return _buildLoadedView(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, MessagesListLoaded state) {
    final list = state.filteredConversations;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final authState = context.read<AuthCubit>().state;
        await context.read<MessagesListCubit>().refresh(
              isAuthenticated: authState is AuthAuthenticated,
            );
      },
      child: Column(
        children: [
          // Search Box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  context.read<MessagesListCubit>().searchConversations(val),
              decoration: InputDecoration(
                hintText: 'Search chats or sellers...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textDisabled,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<MessagesListCubit>()
                              .searchConversations('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppDimensions.radiusMd,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Conversations Feed
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textDisabled,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No conversations found',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return ConversationCard(
                        conversation: item,
                        onTap: () => _onThreadTap(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Messages Yet',
              style: AppTypography.sectionHeading.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'When you contact store sellers from product pages, your conversations will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Explore Products'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.radiusMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sign In to Chat',
              style: AppTypography.sectionHeading.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sign in to your account to send inquiries to sellers and view your message history.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () async {
                final result = await LoginScreen.showAsModal(context);
                if (result == true && context.mounted) {
                  context.read<MessagesListCubit>().loadConversations(
                        forceRefresh: true,
                        isAuthenticated: true,
                      );
                }
              },
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Sign In / Register'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.radiusMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to Load Messages',
              style: AppTypography.sectionHeading.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () {
                final authState = context.read<AuthCubit>().state;
                context.read<MessagesListCubit>().loadConversations(
                      forceRefresh: true,
                      isAuthenticated: authState is AuthAuthenticated,
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.radiusMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
