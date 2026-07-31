import '../entities/rule_item.dart';
import '../repositories/settings_repository.dart';

class GetRulesUseCase {
  final SettingsRepository repository;

  GetRulesUseCase(this.repository);

  Future<List<RuleItem>> call() async {
    return await repository.getCommunityRules();
  }
}