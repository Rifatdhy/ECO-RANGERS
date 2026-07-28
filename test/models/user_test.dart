import 'package:flutter_test/flutter_test.dart';
import 'package:eco_rangers/models/user.dart';

void main() {
  group('User.fromJson', () {
    test('parses admin user with is_admin=1', () {
      final json = {
        'id': 1,
        'name': 'Admin',
        'username': 'admin',
        'email': 'admin@example.com',
        'is_admin': 1,
      };
      final user = User.fromJson(json);
      expect(user.id, 1);
      expect(user.name, 'Admin');
      expect(user.isAdmin, true);
    });

    test('parses regular user with is_admin=0', () {
      final json = {
        'id': 2,
        'name': 'User',
        'username': 'user1',
        'email': 'user@example.com',
        'is_admin': 0,
      };
      final user = User.fromJson(json);
      expect(user.id, 2);
      expect(user.isAdmin, false);
    });

    test('parses is_admin as bool true', () {
      final json = {
        'id': 3,
        'name': 'Test',
        'username': 'test',
        'email': 'test@example.com',
        'is_admin': true,
      };
      final user = User.fromJson(json);
      expect(user.isAdmin, true);
    });

    test('handles missing fields with defaults', () {
      final json = {'id': 4};
      final user = User.fromJson(json);
      expect(user.name, '');
      expect(user.username, '');
      expect(user.email, '');
      expect(user.isAdmin, false);
    });
  });
}