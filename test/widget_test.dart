import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tp5_widget/main.dart';

void main() {
  testWidgets('La page du TP5 affiche la mesure initiale', (tester) async {
    await tester.pumpWidget(const AppTp5());
    expect(find.text('Ruche connectée'), findsOneWidget);
    expect(find.text('34.0 °C'), findsWidgets);
    expect(find.text('ALERTE'), findsNothing);
  });

  testWidgets('Les trois sections de navigation sont accessibles', (
    tester,
  ) async {
    await tester.pumpWidget(const AppTp5());

    await tester.tap(find.text('Historique'));
    await tester.pumpAndSettle();
    expect(find.text('Aucun historique disponible'), findsOneWidget);

    await tester.tap(find.text('Paramètres'));
    await tester.pumpAndSettle();
    expect(find.text('Mode sombre'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(2));
    await tester.tap(find.text('Mode sombre'));
    await tester.pumpAndSettle();
    expect(find.text('Thème sombre activé'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Envoyer au widget'), findsOneWidget);
  });

  testWidgets('Le tableau de bord reste utilisable sur un petit écran', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AppTp5());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ruche connectée'), findsOneWidget);
  });
}
