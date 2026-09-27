import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_status.dart';

/// Anúncio de produto, coleção `products`.
/// Estrutura de dados definida na Fase 1; telas de criação/edição e regras de
/// validade (40 dias), quantidade e negociação chegam na Fase 5 em diante.
class ProductModel {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final List<String> imageUrls;
  final String categoryId;
  final String? subcategoryId;
  final ProductCondition condition;
  final int quantity;
  final ProductStatus status;
  final DeliveryOption deliveryOption;

  // Localização (estrutura preparada para a Fase 3)
  final String state;
  final String city;
  final String region;

  final DateTime createdAt;
  final DateTime expiresAt;

  const ProductModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrls = const [],
    required this.categoryId,
    this.subcategoryId,
    this.condition = ProductCondition.usado,
    this.quantity = 1,
    this.status = ProductStatus.active,
    this.deliveryOption = DeliveryOption.pickupOnly,
    required this.state,
    required this.city,
    required this.region,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Constrói a partir da resposta JSON do backend próprio (Cloudflare
  /// Worker) — usado por todos os endpoints de `/products`.
  factory ProductModel.fromApiJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrls: List<String>.from(json['image_urls'] as List? ?? const []),
      categoryId: json['category_id'] as String? ?? '',
      subcategoryId: json['subcategory_id'] as String?,
      condition: ProductCondition.fromString(json['condition'] as String?),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      status: ProductStatus.fromString(json['status'] as String?),
      deliveryOption: DeliveryOption.fromString(
        json['delivery_option'] as String?,
      ),
      state: json['state'] as String? ?? '',
      city: json['city'] as String? ?? '',
      region: json['region'] as String? ?? '',
      createdAt: _parseApiDate(json['created_at'] as String?),
      expiresAt: _parseApiDate(json['expires_at'] as String?),
    );
  }

  static DateTime _parseApiDate(String? value) {
    if (value == null) return DateTime.now();
    return DateTime.parse(value.contains('T') ? value : value.replaceFirst(' ', 'T'));
  }

  /// Corpo enviado para `POST /products` — o backend calcula
  /// `titleLower`/`createdAt`/`expiresAt`/`status` sozinho.
  Map<String, dynamic> toApiJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'categoryId': categoryId,
      if (subcategoryId != null) 'subcategoryId': subcategoryId,
      'condition': condition.name,
      'quantity': quantity,
      'deliveryOption': deliveryOption.name,
      'state': state,
      'city': city,
      'region': region,
    };
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    final expiresAt = map['expiresAt'];
    return ProductModel(
      id: id,
      sellerId: map['sellerId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      imageUrls: List<String>.from(map['imageUrls'] as List? ?? const []),
      categoryId: map['categoryId'] as String? ?? '',
      subcategoryId: map['subcategoryId'] as String?,
      condition: ProductCondition.fromString(map['condition'] as String?),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      status: ProductStatus.fromString(map['status'] as String?),
      deliveryOption: DeliveryOption.fromString(
        map['deliveryOption'] as String?,
      ),
      state: map['state'] as String? ?? '',
      city: map['city'] as String? ?? '',
      region: map['region'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      expiresAt: expiresAt is Timestamp ? expiresAt.toDate() : DateTime.now(),
    );
  }

  /// Título em minúsculas, salvo junto do documento para permitir busca por
  /// prefixo no Firestore (`titleLower >= termo && titleLower <= termo+`),
  /// já que o Firestore não tem busca textual nativa.
  String get titleLower => title.toLowerCase();

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'title': title,
      'titleLower': titleLower,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'condition': condition.name,
      'quantity': quantity,
      'status': status.name,
      'deliveryOption': deliveryOption.name,
      'state': state,
      'city': city,
      'region': region,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }
}
