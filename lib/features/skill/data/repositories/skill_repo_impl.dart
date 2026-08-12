import '../../domain/entities/skill_entity.dart';
import '../../domain/repositories/skill_repo.dart';
import '../models/skill_model.dart';

abstract class SkillSource {
  Future<List<SkillModel>> getSkills();
}

class SkillSourceImpl implements SkillSource {
  @override
  Future<List<SkillModel>> getSkills() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return [
      SkillModel(
        id: '1',
        title: 'Advanced Portrait Photography',
        subtitle: 'Master natural light and skin tones.',
        badge: 'Pro',
        image: 'assets/images/pool.png',
        time: '12h 45m',
        level: 'Advanced',
        price: 'Rs. 2,499',
        oldPrice: 'Rs. 4,999',
        category: 'Content Creation',
        rating: 4.8,
      ),
      SkillModel(
        id: '2',
        title: 'Mobile Video Editing',
        subtitle: 'Create viral reels on your phone.',
        badge: 'Trending',
        image: 'assets/images/gaming.png',
        time: '6h 20m',
        level: 'Beginner',
        price: 'Free',
        oldPrice: 'Rs. 1,299',
        category: 'Content Creation',
        rating: 4.9,
      ),
      SkillModel(
        id: '3',
        title: 'Social Media Strategy',
        subtitle: 'Grow your personal brand in 2025.',
        badge: 'Classic',
        image: 'assets/images/bowling.png',
        time: '15h 00m',
        level: 'Intermediate',
        price: 'Rs. 3,999',
        oldPrice: 'Rs. 7,499',
        category: 'Content Creation',
        rating: 4.7,
      ),
    ];
  }
}

class SkillRepoImpl implements SkillRepo {
  final SkillSource source;
  SkillRepoImpl(this.source);

  @override
  Future<List<SkillEntity>> getSkills() async {
    return await source.getSkills();
  }
}
