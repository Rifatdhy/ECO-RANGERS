// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:eco_rangers/main.dart';
import 'package:eco_rangers/models/kategori.dart';
import 'package:eco_rangers/models/laporan.dart';

void main() {
  testWidgets('EcoRangersApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoRangersApp());
    expect(find.byType(EcoRangersApp), findsOneWidget);
  });

  test('Laporan.fromJson memetakan field & kategoriLabel menormalkan nilai',
      () {
    final l = Laporan.fromJson({
      'id': 7,
      'judul': 'Sungai kotor',
      'kategori': 'SAMPah',
      'deskripsi': 'banyak sampah',
      'status': 'selesai',
      'vote_count': 12,
      'voted_by_me': true,
      'konfirmasi_user': 'sesuai',
    });
    expect(l.id, 7);
    expect(l.kategori, 'sampah');
    expect(l.voteCount, 12);
    expect(l.votedByMe, isTrue);
    expect(l.konfirmasiUser, 'sesuai');
  });

  test('kategoriLabel menormalkan huruf besar & fallback default', () {
    expect(kategoriLabel('PENCEMARAN'), 'Pencemaran');
    expect(kategoriLabel('tidak-ada'), 'Lainnya');
    expect(kategoriLabel(null), 'Lainnya');
  });
}