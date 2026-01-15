import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reflection_repository.dart';

class ReflectionState {
  final bool isLoading;
  final bool isSaved;
  final String? errorMessage;

  ReflectionState({
    this.isLoading = false,
    this.isSaved = false,
    this.errorMessage,
  });
}

final reflectionControllerProvider =
    StateNotifierProvider<ReflectionController, ReflectionState>((ref) {
      return ReflectionController(ref.watch(reflectionRepositoryProvider));
    });

class ReflectionController extends StateNotifier<ReflectionState> {
  final ReflectionRepository _repository;

  ReflectionController(this._repository) : super(ReflectionState());

  Future<void> saveReflection({
    required String moodKey,
    required String moodEmoji,
    required String text,
    required double energyLevel,
  }) async {
    state = ReflectionState(isLoading: true);
    try {
      await _repository.saveReflection(
        moodKey: moodKey,
        moodEmoji: moodEmoji,
        text: text,
        energyLevel: energyLevel.round(),
      );
      state = ReflectionState(isLoading: false, isSaved: true);
    } catch (e) {
      state = ReflectionState(isLoading: false, errorMessage: e.toString());
    }
  }

  void reset() {
    state = ReflectionState();
  }
}
