import '../entities/skill_entity.dart';

abstract class SkillRepo {
  Future<List<SkillEntity>> getSkills();
}
