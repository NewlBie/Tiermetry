import 'package:flutter/foundation.dart';
import '../../domain/entities/skill_entity.dart';
import '../../domain/repositories/skill_repo.dart';

class SkillCtrl extends ChangeNotifier {
  final SkillRepo repo;

  SkillCtrl(this.repo);

  List<SkillEntity> _skills = [];
  List<SkillEntity> get skills => _skills;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadSkills() async {
    _isLoading = true;
    notifyListeners();

    try {
      _skills = await repo.getSkills();
    } catch (e) {
      debugPrint('Error loading skills: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
