import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flame_engine/services/management_api_service.dart';
import 'package:flame_engine/services/api_client.dart';

// ── Fixture data ──────────────────────────────────────────────────────────────

const _boardsJson = '[{"uuid":"b1","name":"Board A","width":4,"height":4}]';
const _piecesJson =
    '[{"uuid":"p1","name":"Zauberer","nfcId":"010062f58cf253"}]';
const _playersJson = '[{"uuid":"u1","name":"Alice","accessToken":"tok_alice"}]';
const _gamesJson =
    '[{"uuid":"f2fd235b-d3f1-4d57-ba18-f64406866c33","name":"Tutorial"},'
    '{"uuid":"683732ac-c7e4-4d8c-b19a-c6d9ea77c8da","name":"Classic"}]';

// Mirrors the real API base so the mock can match by URL path.
const _base = 'https://tokenandboard.schokoladensouffle.eu/api';

http.Response _fixture(String url) {
  if (url.endsWith('/boards')) return http.Response(_boardsJson, 200);
  if (url.endsWith('/pieces')) return http.Response(_piecesJson, 200);
  if (url.endsWith('/players')) return http.Response(_playersJson, 200);
  if (url.endsWith('/games')) return http.Response(_gamesJson, 200);
  return http.Response('not found', 404);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // Reset the singleton state between tests.
  late ManagementApiService svc;

  setUp(() {
    svc = ManagementApiService();
    // ignore: invalid_use_of_visible_for_testing_member
    svc.reset();
    // ignore: invalid_use_of_visible_for_testing_member
    svc.httpClient = MockClient((req) async => _fixture(req.url.toString()));
  });

  // ── ApiGame.fromJson ──────────────────────────────────────────────────────

  group('ApiGame.fromJson', () {
    test('parses uuid and name', () {
      final g = ApiGame.fromJson({
        'uuid': 'f2fd235b-d3f1-4d57-ba18-f64406866c33',
        'name': 'Tutorial',
      });
      expect(g.uuid, 'f2fd235b-d3f1-4d57-ba18-f64406866c33');
      expect(g.name, 'Tutorial');
    });

    test('toString includes name', () {
      final g = ApiGame.fromJson({'uuid': 'abc', 'name': 'Classic'});
      expect(g.toString(), contains('Classic'));
    });

    test('parses all games from real fixture', () {
      final list = (json.decode(_gamesJson) as List<dynamic>)
          .map((e) => ApiGame.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(list, hasLength(2));
      expect(list.map((g) => g.name), containsAll(['Tutorial', 'Classic']));
    });
  });

  // ── ManagementApiService.load() ───────────────────────────────────────────

  group('ManagementApiService.load()', () {
    test('populates games list from API after load', () async {
      await svc.load();

      expect(svc.isLoaded, isTrue);
      expect(svc.games, hasLength(2));
      expect(
        svc.games.map((g) => g.name),
        containsAll(['Tutorial', 'Classic']),
      );
    });

    test('populates boards with mock data and players from API', () async {
      await svc.load();

      expect(svc.boards, hasLength(2));
      expect(svc.players, hasLength(1));
      // pieces are not fetched from API – remain empty unless set elsewhere
      expect(svc.pieces, isEmpty);
    });

    test(
      'players endpoint returning 404 leaves players empty but isLoaded true',
      () async {
        // ignore: invalid_use_of_visible_for_testing_member
        svc.httpClient = MockClient((req) async {
          if (req.url.toString().endsWith('/players')) {
            return http.Response('', 404);
          }
          return _fixture(req.url.toString());
        });

        await svc.load();

        expect(svc.isLoaded, isTrue);
        expect(svc.players, isEmpty);
        // Boards use mock data; games come from API (fixture returns 2 games).
        expect(svc.boards, hasLength(2));
        expect(svc.games, hasLength(2));
      },
    );

    test(
      'players endpoint returning malformed JSON is handled gracefully',
      () async {
        // ignore: invalid_use_of_visible_for_testing_member
        svc.httpClient = MockClient((req) async {
          if (req.url.toString().endsWith('/players')) {
            return http.Response('{bad json}', 200);
          }
          return _fixture(req.url.toString());
        });

        // load() catches exceptions internally and should not throw.
        await expectLater(svc.load(), completes);
        // isLoaded is still true (mock data was set before the error).
        expect(svc.isLoaded, isTrue);
      },
    );

    test('load() does not send auth headers (public endpoints)', () async {
      String? capturedApiKey;
      String? capturedUserKey;
      String? capturedAuth;
      // ignore: invalid_use_of_visible_for_testing_member
      svc.httpClient = MockClient((req) async {
        capturedApiKey = req.headers['x-api-key'];
        capturedUserKey = req.headers['x-user-key'];
        capturedAuth = req.headers['Authorization'];
        return _fixture(req.url.toString());
      });

      await svc.load();

      expect(capturedApiKey, isNull);
      expect(capturedUserKey, isNull);
      expect(capturedAuth, isNull);
    });

    test('correct URL is called for /players', () async {
      final calledUrls = <String>[];
      // ignore: invalid_use_of_visible_for_testing_member
      svc.httpClient = MockClient((req) async {
        calledUrls.add(req.url.toString());
        return _fixture(req.url.toString());
      });

      await svc.load();

      expect(calledUrls, contains('$_base/players'));
      expect(calledUrls, contains('$_base/games'));
      // boards and pieces are still not fetched from API
      expect(calledUrls, isNot(contains('$_base/boards')));
      expect(calledUrls, isNot(contains('$_base/pieces')));
    });
  });

  // ── ApiClient admin operations ────────────────────────────────────────────

  group('ApiClient admin operations', () {
    late ApiClient client;

    setUp(() {
      client = ApiClient(baseUrl: _base);
    });

    test('adminPost sends x-api-key header', () async {
      String? capturedApiKey;
      client = ApiClient(
        baseUrl: _base,
        apiKey: 'test-key-123',
        httpClient: MockClient((req) async {
          capturedApiKey = req.headers['x-api-key'];
          return http.Response('', 204);
        }),
      );

      await client.adminPost('/boards', {
        'name': 'Test',
        'width': 4,
        'height': 4,
      });

      expect(capturedApiKey, equals('test-key-123'));
    });

    test('adminPut sends x-api-key header', () async {
      String? capturedApiKey;
      client = ApiClient(
        baseUrl: _base,
        apiKey: 'test-key-456',
        httpClient: MockClient((req) async {
          capturedApiKey = req.headers['x-api-key'];
          return http.Response('', 204);
        }),
      );

      await client.adminPut('/boards/uuid', {
        'name': 'Updated',
        'width': 4,
        'height': 4,
      });

      expect(capturedApiKey, equals('test-key-456'));
    });

    test('adminDelete sends x-api-key header', () async {
      String? capturedApiKey;
      client = ApiClient(
        baseUrl: _base,
        apiKey: 'test-key-789',
        httpClient: MockClient((req) async {
          capturedApiKey = req.headers['x-api-key'];
          return http.Response('', 204);
        }),
      );

      await client.adminDelete('/boards/uuid');

      expect(capturedApiKey, equals('test-key-789'));
    });

    test('userPost sends x-user-key header', () async {
      String? capturedUserKey;
      client = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((req) async {
          capturedUserKey = req.headers['x-user-key'];
          return http.Response('{"uuid":"s1","joinCode":"ABCD1234"}', 200);
        }),
      );

      final result = await client.userPost('/sessions', {
        'game': 'game-uuid',
      }, 'player-access-token');

      expect(capturedUserKey, equals('player-access-token'));
      expect(result, isNotNull);
      expect(result!['joinCode'], equals('ABCD1234'));
    });

    test('throws ApiException on 4xx response', () async {
      client = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((req) async {
          return http.Response(
            '{"statusCode":401,"message":"Unauthorized"}',
            401,
          );
        }),
      );

      expect(
        () => client.adminPost('/boards', {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Unauthorized'),
        ),
      );
    });
  });

  // ── New model parsing ─────────────────────────────────────────────────────

  group('ApiField.fromJson', () {
    test('parses all fields', () {
      final f = ApiField.fromJson({
        'uuid': 'f1',
        'nfcId': 'abc123',
        'tile': 'grass',
        'position': {'x': 3, 'y': 5},
      });
      expect(f.uuid, 'f1');
      expect(f.tile, 'grass');
      expect(f.position.x, 3);
      expect(f.position.y, 5);
    });
  });

  group('ApiRole.fromJson', () {
    test('parses uuid and name', () {
      final r = ApiRole.fromJson({'uuid': 'r1', 'name': 'Knight'});
      expect(r.uuid, 'r1');
      expect(r.name, 'Knight');
    });
  });

  group('ApiGamePiece.fromJson', () {
    test('parses nullable fields as null', () {
      final gp = ApiGamePiece.fromJson({
        'uuid': 'gp1',
        'role': null,
        'roleName': null,
        'piece': null,
        'pieceName': null,
        'initialField': null,
        'initialFieldPosition': null,
      });
      expect(gp.uuid, 'gp1');
      expect(gp.role, isNull);
      expect(gp.initialFieldPosition, isNull);
    });

    test('parses populated fields', () {
      final gp = ApiGamePiece.fromJson({
        'uuid': 'gp2',
        'role': 'r1',
        'roleName': 'Knight',
        'piece': 'p1',
        'pieceName': 'Zauberer',
        'initialField': 'f1',
        'initialFieldPosition': {'x': 1, 'y': 2},
      });
      expect(gp.roleName, 'Knight');
      expect(gp.initialFieldPosition?.x, 1);
      expect(gp.initialFieldPosition?.y, 2);
    });
  });

  group('ApiSession.fromJson', () {
    test('parses uuid, creator, game', () {
      final s = ApiSession.fromJson({
        'uuid': 's1',
        'creator': 'player-uuid',
        'game': 'game-uuid',
      });
      expect(s.uuid, 's1');
      expect(s.creator, 'player-uuid');
      expect(s.game, 'game-uuid');
    });
  });

  group('ApiSessionCreated.fromJson', () {
    test('parses uuid and joinCode', () {
      final sc = ApiSessionCreated.fromJson({
        'uuid': 's1',
        'joinCode': 'ABCD1234',
      });
      expect(sc.uuid, 's1');
      expect(sc.joinCode, 'ABCD1234');
    });
  });
}
