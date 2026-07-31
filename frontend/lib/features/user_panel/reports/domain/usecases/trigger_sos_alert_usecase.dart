import '../repositories/reports_repository.dart';

class TriggerSosAlertUseCase {
  final ReportsRepository repository;
  TriggerSosAlertUseCase(this.repository);

  Future<void> call({required bool active}) async => await repository.sendSosAlert(active: active);
}