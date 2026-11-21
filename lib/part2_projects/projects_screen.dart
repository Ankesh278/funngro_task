import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import 'cubit/projects_cubit.dart';
import 'cubit/projects_state.dart';
import 'models/project.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger next page when near bottom
    if (maxScroll - currentScroll <= 250) {
      context.read<ProjectsCubit>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectsCubit, ProjectsState>(
      listenWhen: (prev, curr) => curr.refreshError != null,
      listener: (context, state) {
        if (state.refreshError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Refresh failed: ${state.refreshError}'),
              action: SnackBarAction(
                label: 'Retry',
                textColor: AppColors.warning,
                onPressed: () => context.read<ProjectsCubit>().refresh(),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          context.read<ProjectsCubit>().clearRefreshError();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Projects (Cubit Pagination)'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(32),
              child: Container(
                width: double.infinity,
                color: AppColors.primaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Loaded: ${state.projects.length} projects',
                      style: AppTextStyles.infoHeader.copyWith(color: AppColors.primaryDark),
                    ),
                    Text(
                      state.hasReachedEnd
                          ? 'End of List (Pages 0..7)'
                          : 'Next: Page ${state.nextPage} of 7',
                      style: AppTextStyles.infoHeader.copyWith(
                        color: state.hasReachedEnd ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProjectsState state) {
    if (state.status == ProjectsStatus.firstLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('Loading projects (Page 0)...', style: AppTextStyles.subtitle),
          ],
        ),
      );
    }

    if (state.status == ProjectsStatus.firstLoadError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Initial Load Failed', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                state.initialError ?? 'Server error occurred',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.read<ProjectsCubit>().loadInitial(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Initial Load'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ProjectsCubit>().refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.projects.length + 1,
        itemBuilder: (context, index) {
          if (index < state.projects.length) {
            return _ProjectTile(project: state.projects[index], index: index);
          }
          return _buildFooter(context, state);
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ProjectsState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Loading more projects...', style: AppTextStyles.caption),
            ],
          ),
        ),
      );
    }

    if (state.pageError != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.errorBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Failed to load Page ${state.nextPage}: ${state.pageError}',
                    style: AppTextStyles.errorText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.read<ProjectsCubit>().retryNextPage(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorDark,
                    side: const BorderSide(color: AppColors.errorBorder),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text('Retry Page ${state.nextPage}'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (state.hasReachedEnd) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 26),
            const SizedBox(height: 6),
            const Text("You've reached the end of the projects", style: AppTextStyles.title),
            const SizedBox(height: 2),
            Text(
              'All ${state.projects.length} projects loaded across 8 pages (0..7)',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: 32);
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  final int index;

  const _ProjectTile({required this.project, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Text(
            '#${index + 1}',
            style: AppTextStyles.badge.copyWith(color: AppColors.primaryDark),
          ),
        ),
        title: Text(project.title, style: AppTextStyles.title),
        subtitle: Text(
          '${project.company} • ID: ${project.id}',
          style: AppTextStyles.subtitle,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.successBorder),
          ),
          child: Text('₹${project.payout}', style: AppTextStyles.payout),
        ),
      ),
    );
  }
}
