import '../entities/mensaje_chat.dart';
import '../repositories/chat_repository.dart';

class EnviarMensajeUseCase {
  final ChatRepository repository;
  EnviarMensajeUseCase(this.repository);

  Future<MensajeChat> call(MensajeChat mensaje) async => await repository.enviarMensaje(mensaje);
}