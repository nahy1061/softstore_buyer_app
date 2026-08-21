import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:softstore_buyer_app/features/messages/data/messages_repository.dart';
import 'package:softstore_buyer_app/features/messages/models/chat_message_model.dart';
import 'package:softstore_buyer_app/features/messages/models/conversation_model.dart';
import 'package:softstore_buyer_app/features/messages/presentation/cubits/messages_list_cubit.dart';
import 'package:softstore_buyer_app/features/messages/presentation/cubits/messages_list_state.dart';
import 'package:softstore_buyer_app/features/messages/presentation/cubits/seller_chat_cubit.dart';
import 'package:softstore_buyer_app/features/messages/presentation/cubits/seller_chat_state.dart';

class MockMessagesRepository extends Mock implements MessagesRepository {}

void main() {
  late MockMessagesRepository mockRepository;

  final sampleThread = ConversationThread(
    id: '101',
    threadUrl: '/store/messages/101',
    sellerName: 'Tech Zone',
    productName: 'Fast Charger',
    productImage: 'https://softstore.pk/media/charger.jpg',
    lastMessage: 'Your order is ready',
    lastMessageTime: DateTime(2026, 8, 21, 10, 0),
    unreadCount: 1,
    isUnread: true,
  );

  final sampleMessage = ChatMessage(
    id: 1,
    threadUrl: '/store/messages/101',
    sender: MessageSender.buyer,
    text: 'Is this available in black?',
    sentAt: DateTime(2026, 8, 21, 10, 0),
    status: MessageStatus.sent,
  );

  setUp(() {
    mockRepository = MockMessagesRepository();
    when(() => mockRepository.cachedConversations).thenReturn([]);
    when(() => mockRepository.getCachedMessages(any())).thenReturn([]);
    when(() => mockRepository.getCachedThreadUrlForProduct(any())).thenReturn(null);
  });

  group('MessagesListCubit Tests', () {
    test('initial state is MessagesListInitial', () {
      final cubit = MessagesListCubit(repository: mockRepository);
      expect(cubit.state, const MessagesListInitial());
    });

    blocTest<MessagesListCubit, MessagesListState>(
      'emits [MessagesListUnauthenticated] when user is not authenticated',
      build: () => MessagesListCubit(repository: mockRepository),
      act: (cubit) => cubit.loadConversations(isAuthenticated: false),
      expect: () => [
        const MessagesListUnauthenticated(),
      ],
    );

    blocTest<MessagesListCubit, MessagesListState>(
      'emits [MessagesListLoading, MessagesListLoaded] when fetchConversations succeeds with data',
      build: () {
        when(() => mockRepository.fetchConversations(forceRefresh: any(named: 'forceRefresh')))
            .thenAnswer((_) async => [sampleThread]);
        return MessagesListCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.loadConversations(),
      expect: () => [
        const MessagesListLoading(),
        MessagesListLoaded(conversations: [sampleThread]),
      ],
    );

    blocTest<MessagesListCubit, MessagesListState>(
      'emits [MessagesListLoading, MessagesListEmpty] when fetchConversations returns empty list',
      build: () {
        when(() => mockRepository.fetchConversations(forceRefresh: any(named: 'forceRefresh')))
            .thenAnswer((_) async => []);
        return MessagesListCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.loadConversations(),
      expect: () => [
        const MessagesListLoading(),
        const MessagesListEmpty(),
      ],
    );

    blocTest<MessagesListCubit, MessagesListState>(
      'filters conversations correctly on search',
      build: () => MessagesListCubit(repository: mockRepository),
      seed: () => MessagesListLoaded(conversations: [sampleThread]),
      act: (cubit) => cubit.searchConversations('Charger'),
      expect: () => [
        MessagesListLoaded(
          conversations: [sampleThread],
          searchQuery: 'Charger',
          filteredConversations: [sampleThread],
        ),
      ],
    );

    blocTest<MessagesListCubit, MessagesListState>(
      'markAsRead clears unread count and flag on matching thread',
      build: () => MessagesListCubit(repository: mockRepository),
      seed: () => MessagesListLoaded(conversations: [sampleThread]),
      act: (cubit) => cubit.markAsRead('/store/messages/101'),
      expect: () => [
        MessagesListLoaded(
          conversations: [
            sampleThread.copyWith(isUnread: false, unreadCount: 0),
          ],
        ),
      ],
    );
  });

  group('SellerChatCubit Tests', () {
    test('initial state is SellerChatInitial', () {
      final cubit = SellerChatCubit(repository: mockRepository);
      expect(cubit.state, const SellerChatInitial());
    });

    blocTest<SellerChatCubit, SellerChatState>(
      'loads thread messages and emits [SellerChatLoading, SellerChatLoaded]',
      build: () {
        when(() => mockRepository.getThreadMessages('/store/messages/101', forceRefresh: any(named: 'forceRefresh')))
            .thenAnswer((_) async => [sampleMessage]);
        return SellerChatCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.loadThread('/store/messages/101', threadInfo: sampleThread),
      expect: () => [
        const SellerChatLoading(),
        SellerChatLoaded(
          threadUrl: '/store/messages/101',
          messages: [sampleMessage],
          threadInfo: sampleThread,
          productId: sampleThread.productId,
          productName: sampleThread.productName,
          productImage: sampleThread.productImage,
          sellerName: sampleThread.sellerName,
        ),
      ],
    );

    blocTest<SellerChatCubit, SellerChatState>(
      'startChatWithProduct starts a new conversation and loads thread',
      build: () {
        when(() => mockRepository.startConversation(
              productId: 456,
              message: 'Hello seller',
              productName: 'Fast Charger',
              productImage: null,
              sellerName: 'Tech Zone',
            )).thenAnswer((_) async => '/store/messages/101');
        when(() => mockRepository.getCachedMessages('/store/messages/101'))
            .thenReturn([sampleMessage]);
        return SellerChatCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.startChatWithProduct(
        productId: 456,
        initialMessage: 'Hello seller',
        productName: 'Fast Charger',
        sellerName: 'Tech Zone',
      ),
      expect: () => [
        const SellerChatLoading(),
        SellerChatLoaded(
          threadUrl: '/store/messages/101',
          messages: [sampleMessage],
          productId: 456,
          productName: 'Fast Charger',
          sellerName: 'Tech Zone',
        ),
      ],
    );

    blocTest<SellerChatCubit, SellerChatState>(
      'sendMessage optimistically inserts sending message then confirms on success',
      build: () {
        when(() => mockRepository.sendMessage(
              threadUrl: '/store/messages/101',
              message: 'How fast is delivery?',
            )).thenAnswer((_) async => ChatMessage(
              id: 2,
              threadUrl: '/store/messages/101',
              sender: MessageSender.buyer,
              text: 'How fast is delivery?',
              sentAt: DateTime.now(),
              status: MessageStatus.sent,
            ));
        return SellerChatCubit(repository: mockRepository);
      },
      seed: () => SellerChatLoaded(
        threadUrl: '/store/messages/101',
        messages: [sampleMessage],
      ),
      act: (cubit) => cubit.sendMessage('How fast is delivery?'),
      expect: () => [
        isA<SellerChatLoaded>()
            .having((s) => s.isSending, 'isSending', isTrue)
            .having((s) => s.messages.length, 'messages.length', 2)
            .having((s) => s.messages.last.status, 'last.status', MessageStatus.sending),
        isA<SellerChatLoaded>()
            .having((s) => s.isSending, 'isSending', isFalse)
            .having((s) => s.messages.length, 'messages.length', 2)
            .having((s) => s.messages.last.status, 'last.status', MessageStatus.sent),
      ],
    );
  });
}
