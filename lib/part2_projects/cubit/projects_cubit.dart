import 'package:flutter_bloc/flutter_bloc.dart';
import '../projects_api.dart';
import 'projects_state.dart';

class ProjectsCubit extends Cubit<ProjectsState> {
  final ProjectsApi _api;
  int _requestEpoch = 0;

  ProjectsCubit({ProjectsApi? api})
      : _api = api ?? ProjectsApi(),
        super(const ProjectsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    final epoch = ++_requestEpoch;
    emit(state.copyWith(
      status: ProjectsStatus.firstLoading,
      projects: const [],
      nextPage: 0,
      hasReachedEnd: false,
      isLoadingMore: false,
      clearInitialError: true,
      clearPageError: true,
      clearRefreshError: true,
    ));

    try {
      final data = await _api.fetchProjects(0);
      if (isClosed || epoch != _requestEpoch) return;

      emit(state.copyWith(
        status: ProjectsStatus.success,
        projects: data,
        nextPage: 1,
        hasReachedEnd: data.isEmpty,
      ));
    } catch (e) {
      if (isClosed || epoch != _requestEpoch) return;
      emit(state.copyWith(
        status: ProjectsStatus.firstLoadError,
        initialError: e.toString().replaceAll('ApiException: ', ''),
      ));
    }
  }

  Future<void> refresh() async {
    final epoch = ++_requestEpoch;
    try {
      final data = await _api.fetchProjects(0);
      if (isClosed || epoch != _requestEpoch) return;

      emit(state.copyWith(
        status: ProjectsStatus.success,
        projects: data,
        nextPage: 1,
        hasReachedEnd: data.isEmpty,
        clearPageError: true,
        clearInitialError: true,
        clearRefreshError: true,
      ));
    } catch (e) {
      if (isClosed || epoch != _requestEpoch) return;
      emit(state.copyWith(
        refreshError: e.toString().replaceAll('ApiException: ', ''),
      ));
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore ||
        state.hasReachedEnd ||
        state.pageError != null ||
        state.status != ProjectsStatus.success) {
      return;
    }

    final epoch = _requestEpoch;
    emit(state.copyWith(
      isLoadingMore: true,
      clearPageError: true,
    ));

    try {
      final data = await _api.fetchProjects(state.nextPage);
      if (isClosed || epoch != _requestEpoch) return;

      if (data.isEmpty) {
        emit(state.copyWith(
          isLoadingMore: false,
          hasReachedEnd: true,
        ));
      } else {
        emit(state.copyWith(
          isLoadingMore: false,
          projects: [...state.projects, ...data],
          nextPage: state.nextPage + 1,
        ));
      }
    } catch (e) {
      if (isClosed || epoch != _requestEpoch) return;
      emit(state.copyWith(
        isLoadingMore: false,
        pageError: e.toString().replaceAll('ApiException: ', ''),
      ));
    }
  }

  void retryNextPage() {
    emit(state.copyWith(clearPageError: true));
    loadNextPage();
  }

  void clearRefreshError() {
    emit(state.copyWith(clearRefreshError: true));
  }
}
