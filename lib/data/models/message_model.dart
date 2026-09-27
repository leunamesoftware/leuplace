import 'package:cloud_firestore/cloud_firestore.dart';

/// Mensagem individual de um chat, coleção `messages`. Uma mensagem tem texto
/// ou uma imagem (nunca as duas, para manter o modelo simples).
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime sentAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text = '',
    this.imageUrl,
    required this.sentAt,
  });

  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory MessageModel.fromApiJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      sentAt: _parseDate(json['sent_at'] as String?),
    );
  }

  static DateTime _parseDate(String? value) {
    if (value == null) return DateTime.now();
    return DateTime.parse(value.contains('T') ? value : value.replaceFirst(' ', 'T'));
  }

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    final sentAt = map['sentAt'];
    return MessageModel(
      id: id,
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      sentAt: sentAt is Timestamp ? sentAt.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }
}
