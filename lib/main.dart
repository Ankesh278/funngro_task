import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'part1_earnings/cubit/earnings_cubit.dart';
import 'part1_earnings/earnings_screen_rewritten.dart';
import 'part1_earnings/fake_earnings_api.dart';
import 'part2_projects/cubit/projects_cubit.dart';
import 'part2_projects/projects_api.dart';
import 'part2_projects/projects_screen.dart';

void main() {
  runApp(const FunngroAssessmentApp());
}

class FunngroAssessmentApp extends StatelessWidget {
  final ProjectsApi? projectsApi;
  final FakeEarningsApi? fakeEarningsApi;

  const FunngroAssessmentApp({
    super.key,
    this.projectsApi,
    this.fakeEarningsApi,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Funngro Assessment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AssessmentHomeScreen(
        projectsApi: projectsApi,
        fakeEarningsApi: fakeEarningsApi,
      ),
    );
  }
}

class AssessmentHomeScreen extends StatefulWidget {
  final ProjectsApi? projectsApi;
  final FakeEarningsApi? fakeEarningsApi;

  const AssessmentHomeScreen({
    super.key,
    this.projectsApi,
    this.fakeEarningsApi,
  });

  @override
  State<AssessmentHomeScreen> createState() => _AssessmentHomeScreenState();
}

class _AssessmentHomeScreenState extends State<AssessmentHomeScreen> {
  int _currentIndex = 0;
  late final ProjectsApi _projectsApi;
  late final FakeEarningsApi _fakeEarningsApi;
  late final bool _ownsFakeEarningsApi;

  @override
  void initState() {
    super.initState();
    _projectsApi = widget.projectsApi ?? ProjectsApi();
    if (widget.fakeEarningsApi != null) {
      _fakeEarningsApi = widget.fakeEarningsApi!;
      _ownsFakeEarningsApi = false;
    } else {
      _fakeEarningsApi = FakeEarningsApi();
      _ownsFakeEarningsApi = true;
    }
  }

  @override
  void dispose() {
    if (_ownsFakeEarningsApi) {
      _fakeEarningsApi.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProjectsCubit>(
          create: (_) => ProjectsCubit(api: _projectsApi),
        ),
        BlocProvider<EarningsCubit>(
          create: (_) => EarningsCubit(
            api: _fakeEarningsApi,
            userId: 'teen_user_9921',
          ),
        ),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            ProjectsScreen(),
            RewrittenEarningsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) {
            setState(() {
              _currentIndex = idx;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Part 2: Projects',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Part 1: Earnings',
            ),
          ],
        ),
      ),
    );
  }
}
