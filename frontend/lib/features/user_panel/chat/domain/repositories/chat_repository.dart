import '../entities/mensaje_chat.dart';

abstract class ChatRepository {
  Future<List<MensajeChat>> getMensajes();
  Future<MensajeChat> enviarMensaje(MensajeChat mensaje);
  Future<String> obtenerResumenIA();
}