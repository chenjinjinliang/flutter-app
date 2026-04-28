import '../../origin_sdk/origin_types.dart';

enum BiliUserVipStatus {
  none(0),
  month(1),
  year(2);

  final int code;
  const BiliUserVipStatus(this.code);
}

/// B 站搜索条目
class BiliSearchItem extends SearchItem {
  BiliSearchItem({
    required super.id,
    required super.title,
    required super.artist,
    required super.album,
    required super.artUri,
    super.duration,
    super.mid,
  });

  factory BiliSearchItem.fromJson(Map json) {
    // 处理嵌套的 owner 字段
    String artist = '';
    if (json['owner'] is Map) {
      artist = json['owner']['name'] ?? '';
    } else if (json.containsKey('author')) {
      artist = json['author'] ?? '';
    } else if (json.containsKey('up') && json['up'] != null) {
      artist = json['up']['name'] ?? '';
    }

    // 处理封面图，优先使用 pic
    String artUri = '';
    if (json.containsKey('pic') && json['pic'] != null) {
      artUri = json['pic'];
    } else if (json.containsKey('cover') && json['cover'] != null) {
      artUri = json['cover'];
    }

    return BiliSearchItem(
      id: BiliId.buildUnicodeId(
        bilibiliBvid: json['bvid'] ?? '',
        bilibiliCid: json['cid']?.toString() ?? '',
        bilibiliAid: json['aid']?.toString() ?? '',
      ),
      title: json['title'] ?? '',
      artist: artist,
      album: json['tag'] ?? '',
      artUri: artUri,
      duration: _parseDuration(json['duration']),
      mid: json['mid']?.toString(),
    );
  }

  static Duration _parseDuration(dynamic duration) {
    if (duration == null) return Duration.zero;
    if (duration is int) return Duration(seconds: duration);
    if (duration is String) {
      final parts = duration.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        return Duration(minutes: m, seconds: s);
      } else if (parts.length == 3) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = int.tryParse(parts[2]) ?? 0;
        return Duration(hours: h, minutes: m, seconds: s);
      }
    }
    return Duration.zero;
  }
}

/// 搜索结果
class BiliSearchResponse extends SearchResponse {
  BiliSearchResponse({
    required super.current,
    required super.total,
    required super.pageSize,
    required super.data,
  });

  factory BiliSearchResponse.fromJson(Map json) {
    // 兼容您的后端代理返回格式：{ code: 0, data: { result: [...] } }
    final resultData = json['data']?['result'] ?? [];

    // 如果 result 已经是 List
    List result = [];
    if (resultData is List) {
      result = resultData;
    } else if (resultData is Map && resultData['result'] is List) {
      result = resultData['result'];
    }

    List<SearchItem> data = [];
    for (var j in result) {
      if (j is Map) {
        // 跳过课堂类型
        if (j['type'] == 'ketang') continue;
        data.add(BiliSearchItem.fromJson(j));
      }
    }

    return BiliSearchResponse(
      current: json['data']?['page'] ?? 1,
      total: json['data']?['numResults'] ?? data.length,
      pageSize: json['data']?['pagesize'] ?? 48,
      data: data,
    );
  }
}

/// 搜索建议条目
class BiliSearchSuggestItem extends SearchSuggestItem {
  BiliSearchSuggestItem({
    required super.keyword,
    required super.title,
  });
}

/// B 站 ID 结构体
class BiliId {
  final String bvid;
  final String? cid;
  final String? aid;
  final String? unicodeId;

  BiliId({
    required this.bvid,
    this.cid,
    this.aid,
    this.unicodeId,
  });

  /// 从 Unicode ID 字符串创建
  factory BiliId.unicode(String id) {
    if (id.startsWith('bilibili:')) {
      final parts = id.substring(9).split('|');
      return BiliId(
        bvid: parts.isNotEmpty ? parts[0] : '',
        cid: parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
        aid: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
        unicodeId: id,
      );
    }
    return BiliId(bvid: id);
  }

  /// 构建 Unicode ID
  static String buildUnicodeId({
    required String bilibiliBvid,
    String? bilibiliCid,
    String? bilibiliAid,
  }) {
    return 'bilibili:$bilibiliBvid|${bilibiliCid ?? ''}|${bilibiliAid ?? ''}';
  }
}

/// B 站用户信息
class BiliUser {
  final String mid;
  final String name;
  final String avatar;
  final BiliUserVipStatus vipStatus;

  BiliUser({
    required this.mid,
    required this.name,
    required this.avatar,
    required this.vipStatus,
  });

  factory BiliUser.fromJson(Map json) {
    return BiliUser(
      mid: json['mid']?.toString() ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? json['face'] ?? '',
      vipStatus: BiliUserVipStatus.values[json['vipStatus'] ?? 0],
    );
  }
}
