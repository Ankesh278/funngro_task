import 'package:flutter_test/flutter_test.dart';
import 'package:funngro/main.dart';
import 'package:funngro/part1_earnings/fake_earnings_api.dart';
import 'package:funngro/part2_projects/models/project.dart';
import 'package:funngro/part2_projects/projects_api.dart';

void main() {
  testWidgets('Funngro assessment smoke test', (WidgetTester tester) async {
    final fakeEarningsApi = FakeEarningsApi(enableBackgroundTicker: false);

    await tester.pumpWidget(
      FunngroAssessmentApp(
        fakeEarningsApi: fakeEarningsApi,
      ),
    );

    // Initial check: layout rendered
    expect(find.text('Projects (Cubit Pagination)'), findsOneWidget);
    expect(find.text('Part 2: Projects'), findsOneWidget);
    expect(find.text('Part 1: Earnings'), findsOneWidget);

    // Advance fake async time to resolve the 900ms delay in ProjectsApi
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    fakeEarningsApi.dispose();
  });

  test('ProjectsApi returns 20 items on valid page or throws ApiException', () async {
    final api = ProjectsApi();
    int attempts = 0;
    bool hadSuccess = false;

    // Retry up to 10 times to account for the 20% random failure rate
    while (attempts < 10 && !hadSuccess) {
      attempts++;
      try {
        final projects = await api.fetchProjects(0);
        expect(projects.length, 20);
        expect(projects.first.id, 'p0');
        hadSuccess = true;
      } on ApiException {
        // Expected random failure (1 in 5 calls)
      }
    }
    expect(hadSuccess, isTrue);

    // Page > 7 must return empty list [] (retry if random 20% failure happens)
    bool emptyVerified = false;
    int emptyAttempts = 0;
    while (emptyAttempts < 10 && !emptyVerified) {
      emptyAttempts++;
      try {
        final emptyProjects = await api.fetchProjects(8);
        expect(emptyProjects.isEmpty, isTrue);
        emptyVerified = true;
      } on ApiException {
        // Expected random failure
      }
    }
    expect(emptyVerified, isTrue);
  });
}
