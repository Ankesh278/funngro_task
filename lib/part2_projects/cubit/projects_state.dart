import '../models/project.dart';

enum ProjectsStatus { initial, firstLoading, success, firstLoadError }

class ProjectsState {
  final ProjectsStatus status;
  final List<Project> projects;
  final int nextPage;
  final bool hasReachedEnd;
  final bool isLoadingMore;
  final String? initialError;
  final String? pageError;
  final String? refreshError;

  const ProjectsState({
    this.status = ProjectsStatus.initial,
    this.projects = const [],
    this.nextPage = 0,
    this.hasReachedEnd = false,
    this.isLoadingMore = false,
    this.initialError,
    this.pageError,
    this.refreshError,
  });

  ProjectsState copyWith({
    ProjectsStatus? status,
    List<Project>? projects,
    int? nextPage,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    String? initialError,
    String? pageError,
    String? refreshError,
    bool clearPageError = false,
    bool clearRefreshError = false,
    bool clearInitialError = false,
  }) {
    return ProjectsState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      nextPage: nextPage ?? this.nextPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      initialError: clearInitialError ? null : (initialError ?? this.initialError),
      pageError: clearPageError ? null : (pageError ?? this.pageError),
      refreshError: clearRefreshError ? null : (refreshError ?? this.refreshError),
    );
  }
}
