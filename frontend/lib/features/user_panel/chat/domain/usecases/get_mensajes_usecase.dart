import '../entities/mensaje_chat.dart';
import '../repositories/chat_repository.dart';

class GetMensajesUseCase {
  final ChatRepository repository;
  GetMensajesUseCase(this.repository);

  Future<List<MensajeChat>> call() async => await repository.getMensajes();
}