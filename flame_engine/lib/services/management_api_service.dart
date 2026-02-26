import 'dart:convert';
import 'package:http/http.dart' as http;

const String _kApiBase = 'https://tokenandboard.schokoladensouffle.eu/api';
// Pass via: --dart-define=API_TOKEN=<your_token>
// Falls back to the development token when not provided.
const String _kApiToken = String.fromEnvironment(
  'API_TOKEN',
  defaultValue: 'leuheidaeJoo1aNgeethei0sho0iek8i',
);

// ── Models ────────────────────────────────────────────────────────────────────

/// A game board (grid) from the management API.
class ApiBoard {
  final String uuid;
  final String name;
  final int width;
  final int height;

  const ApiBoard({
    required this.uuid,
    required this.name,
    required this.width,
    required this.height,
  });

  factory ApiBoard.fromJson(Map<String, dynamic> json) {
    final uuid = json['uuid'] as String?;
    final name = json['name'] as String?;
    final width = json['width'] as num?;
    final height = json['height'] as num?;

    if (uuid == null || name == null || width == null || height == null) {
      throw FormatException(
        'ApiBoard missing required fields: uuid=$uuid, name=$name, width=$width, height=$height',
      );
    }

    return ApiBoard(
      uuid: uuid,
      name: name,
      width: width.toInt(),
      height: height.toInt(),
    );
  }

  @override
  String toString() => 'ApiBoard($name, ${width}x$height)';
}

/// An NFC-tagged physical piece (figure) from the management API.
class ApiPiece {
  /// UUID from the management system.
  final String uuid;

  /// Display name, e.g. "Controller" or "Engineer".
  final String name;

  /// Raw hex NFC ID as returned by the API (e.g. "010062f58cf253").
  final String nfcIdRaw;

  /// NFC tag ID in uppercase colon-separated reversed-byte format used by the
  /// Flutter NFC scanner (e.g. "53:F2:8C:F5:62:00:01").
  final String nfcTagId;

  ApiPiece({required this.uuid, required this.name, required this.nfcIdRaw})
    : nfcTagId = _convertNfcId(nfcIdRaw);

  /// Convert raw hex (e.g. "010062f58cf253") to colon-separated reversed-byte
  /// uppercase format (e.g. "53:F2:8C:F5:62:00:01").
  static String _convertNfcId(String raw) {
    final bytes = <String>[];
    for (int i = 0; i + 1 < raw.length; i += 2) {
      bytes.add(raw.substring(i, i + 2));
    }
    return bytes.reversed.join(':').toUpperCase();
  }

  /// Infer the character class string (matches CharacterClass enum name) from
  /// the piece name.
  String get characterClass {
    final lower = name.toLowerCase();
    if (lower.contains('controller') || lower.contains('kontroll')) {
      return 'controller';
    }
    if (lower.contains('engineer') || lower.contains('ingenieur')) {
      return 'engineer';
    }
    if (lower.contains('striker') || lower.contains('schlag')) {
      return 'striker';
    }
    if (lower.contains('vanguard') || lower.contains('vorhut')) {
      return 'vanguard';
    }
    return lower;
  }

  factory ApiPiece.fromJson(Map<String, dynamic> json) {
    final uuid = json['uuid'] as String?;
    final name = json['name'] as String?;
    final nfcId = json['nfcId'] as String?;

    if (uuid == null || name == null || nfcId == null) {
      throw FormatException(
        'ApiPiece missing required fields: uuid=$uuid, name=$name, nfcId=$nfcId',
      );
    }

    return ApiPiece(uuid: uuid, name: name, nfcIdRaw: nfcId);
  }

  /// Build the mock NFC payload map used by [NFCService.triggerMockScan].
  Map<String, dynamic> toMockPayload() => {
    'tagId': nfcTagId,
    'uuid': uuid,
    'characterName': name,
    'characterClass': characterClass,
  };

  @override
  String toString() => 'ApiPiece($name, nfcTagId: $nfcTagId)';
}

/// A game from the management API (maps to a playable scenario on a board).
class ApiGame {
  final String uuid;
  final String name;

  const ApiGame({required this.uuid, required this.name});

  factory ApiGame.fromJson(Map<String, dynamic> json) {
    final uuid = json['uuid'] as String?;
    final name = json['name'] as String?;

    if (uuid == null || name == null) {
      throw FormatException(
        'ApiGame missing required fields: uuid=$uuid, name=$name',
      );
    }

    return ApiGame(uuid: uuid, name: name);
  }

  @override
  String toString() => 'ApiGame($name)';
}

/// A player registered in the management system.
class ApiPlayer {
  final String uuid;
  final String name;
  final String accessToken;

  const ApiPlayer({
    required this.uuid,
    required this.name,
    required this.accessToken,
  });

  factory ApiPlayer.fromJson(Map<String, dynamic> json) {
    final uuid = json['uuid'] as String?;
    final name = json['name'] as String?;
    final accessToken = json['accessToken'] as String?;

    if (uuid == null || name == null || accessToken == null) {
      throw FormatException(
        'ApiPlayer missing required fields: uuid=$uuid, name=$name, accessToken=$accessToken',
      );
    }

    return ApiPlayer(uuid: uuid, name: name, accessToken: accessToken);
  }

  @override
  String toString() => 'ApiPlayer($name)';
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Singleton service that fetches and caches data from the Token & Board
/// management API (https://tokenandboard.schokoladensouffle.eu/api).
class ManagementApiService {
  static final ManagementApiService _instance =
      ManagementApiService._internal();
  factory ManagementApiService() => _instance;
  ManagementApiService._internal();

  static const _headers = {
    'Authorization': 'Bearer $_kApiToken',
    'Accept': 'application/json',
  };

  List<ApiBoard> boards = [];
  List<ApiPiece> pieces = [];
  List<ApiPlayer> players = [];
  List<ApiGame> games = [];

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Fetch all three endpoints in parallel. On success, [isLoaded] becomes
  /// `true` and [boards], [pieces], [players] are populated.
  Future<void> load() async {
    print('═══════════════════════════════════════════════════════════');
    print('🌐 ManagementApiService: Starting API connection...');
    print('   Base URL: $_kApiBase');
    print('   Token: ${_kApiToken.substring(0, 8)}...');
    print('═══════════════════════════════════════════════════════════');

    try {
      print('📡 Fetching data from 3 endpoints in parallel...');
      print('   • GET $_kApiBase/boards');
      print('   • GET $_kApiBase/pieces');
      print('   • GET $_kApiBase/players');

      final results = await Future.wait([
        http.get(Uri.parse('$_kApiBase/boards'), headers: _headers),
        http.get(Uri.parse('$_kApiBase/pieces'), headers: _headers),
        http.get(Uri.parse('$_kApiBase/players'), headers: _headers),
        http.get(Uri.parse('$_kApiBase/games'), headers: _headers),
      ]);

      print('\n✓ API requests completed!');

      print('\n📋 BOARDS endpoint:');
      print('   Status: ${results[0].statusCode}');
      if (results[0].statusCode == 200) {
        print('   ✓ Success!');
        final data = json.decode(results[0].body) as List<dynamic>;
        boards = data
            .map((e) => ApiBoard.fromJson(e as Map<String, dynamic>))
            .toList();
        print('   Loaded ${boards.length} board(s)');
      } else {
        print('   ✗ Failed: ${results[0].reasonPhrase}');
        print(
          '   Response: ${results[0].body.substring(0, results[0].body.length > 200 ? 200 : results[0].body.length)}',
        );
      }

      print('\n🎲 PIECES endpoint:');
      print('   Status: ${results[1].statusCode}');
      if (results[1].statusCode == 200) {
        print('   ✓ Success!');
        final data = json.decode(results[1].body) as List<dynamic>;
        pieces = data
            .map((e) => ApiPiece.fromJson(e as Map<String, dynamic>))
            .toList();
        print('   Loaded ${pieces.length} piece(s)');
      } else {
        print('   ✗ Failed: ${results[1].reasonPhrase}');
        print(
          '   Response: ${results[1].body.substring(0, results[1].body.length > 200 ? 200 : results[1].body.length)}',
        );
      }

      print('\n👥 PLAYERS endpoint:');
      print('   Status: ${results[2].statusCode}');
      if (results[2].statusCode == 200) {
        print('   ✓ Success!');
        final data = json.decode(results[2].body) as List<dynamic>;
        players = data
            .map((e) => ApiPlayer.fromJson(e as Map<String, dynamic>))
            .toList();
        print('   Loaded ${players.length} player(s)');
      } else {
        print('   ✗ Failed: ${results[2].reasonPhrase}');
        print(
          '   Response: ${results[2].body.substring(0, results[2].body.length > 200 ? 200 : results[2].body.length)}',
        );
      }

      print('\n🎮 GAMES endpoint:');
      print('   Status: ${results[3].statusCode}');
      if (results[3].statusCode == 200) {
        print('   ✓ Success!');
        final data = json.decode(results[3].body) as List<dynamic>;
        games = data
            .map((e) => ApiGame.fromJson(e as Map<String, dynamic>))
            .toList();
        print('   Loaded ${games.length} game(s)');
      } else {
        print('   ✗ Failed: ${results[3].reasonPhrase}');
      }

      _loaded = true;

      print('\n═══════════════════════════════════════════════════════════');
      print('✅ API LOAD COMPLETE');
      print(
        '\n   Total: ${boards.length} boards, ${pieces.length} pieces, ${players.length} players, ${games.length} games',
      );
      print('═══════════════════════════════════════════════════════════');

      if (pieces.isNotEmpty) {
        print('\n🎲 PIECES LOADED:');
        for (final p in pieces) {
          print('   • $p');
        }
      }

      if (players.isNotEmpty) {
        print('\n👥 PLAYERS LOADED:');
        for (final pl in players) {
          print('   • $pl');
        }
      }

      if (boards.isNotEmpty) {
        print('\n📋 BOARDS LOADED:');
        for (final b in boards) {
          print('   • $b');
        }
      }

      print('\n');
    } catch (e, stackTrace) {
      print('\n═══════════════════════════════════════════════════════════');
      print('❌ API LOAD FAILED');
      print('   Error: $e');
      print('   Stack trace:');
      print('$stackTrace');
      print('═══════════════════════════════════════════════════════════\n');
    }
  }

  /// Returns the first (primary) board, or null if none loaded.
  ApiBoard? get primaryBoard => boards.isNotEmpty ? boards.first : null;
}
