import '../repositories/chat_repository.dart';

class ObtenerResumenIAUseCase {
  final ChatRepository repository;
  ObtenerResumenIAUseCase(this.repository);

  Future<String> call() async => await repository.obtenerResumenIA();
}