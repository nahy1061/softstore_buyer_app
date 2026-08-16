import '../core/networking/web_session_client.dart';

class FollowService {
  final _client = WebSessionClient.shared;

  Future<bool> followStore(String storeId) async {
    final csrf = await _client.fetchCsrf('/store/$storeId');
    await _client.postForm('/store/follow', {
      '_csrf_token': csrf,
      'store_id': storeId,
    });
    return true;
  }

  Future<bool> unfollowStore(String storeId) async {
    final csrf = await _client.fetchCsrf('/store/$storeId');
    await _client.postForm('/store/unfollow', {
      '_csrf_token': csrf,
      'store_id': storeId,
    });
    return false;
  }

  Future<bool> toggleFollow(String storeId, {required bool currentlyFollowing}) async {
    return currentlyFollowing ? await unfollowStore(storeId) : await followStore(storeId);
  }
}
