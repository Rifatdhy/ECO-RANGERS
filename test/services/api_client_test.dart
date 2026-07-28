import 'package:flutter_test/flutter_test.dart';
import 'package:eco_rangers/services/api_client.dart';
import 'package:eco_rangers/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient', () {
    setUp(() async {
      await dotenv.load(fileName: ".env");
      await ensureBaseUrl();
      SharedPreferences.setMockInitialValues({'token': 'test_token'});
    });

    test('getReports returns data on 200', () async {
      final client = ApiClient();
      client.httpClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test_token');
        return http.Response(
          jsonEncode([{'id': 1, 'judul': 'Test', 'deskripsi': 'Desc', 'status': 'pending', 'created_at': '2024-01-01T00:00:00'}]),
          200,
        );
      });

      final result = await client.getReports();
      expect(result.length, 1);
    });

    test('getReports throws ApiException on server error', () async {
      final client = ApiClient();
      client.httpClient = MockClient((_) async {
        return http.Response('Error', 500);
      });

      expect(
        () => client.getReports(),
        throwsA(isA<ApiException>()),
      );
    });

    test('deleteReport returns on success', () async {
      final client = ApiClient();
      client.httpClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response(jsonEncode({}), 200);
      });

      await client.deleteReport(1);
    });

    test('deleteReport throws on not found', () async {
      final client = ApiClient();
      client.httpClient = MockClient((_) async {
        return http.Response('Not found', 404);
      });

      expect(
        () => client.deleteReport(999),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
