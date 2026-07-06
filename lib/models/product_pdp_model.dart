import 'dart:convert';

class ProductPdpResponse {
  final bool success;
  final String message;
  final ProductPdpData data;

  ProductPdpResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ProductPdpResponse.fromJson(Map<String, dynamic> json) {
    return ProductPdpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ProductPdpData.fromJson(json['data'] ?? {}),
    );
  }
}

class ProductPdpData {
  final String id;
  final String name;
  final String slug;
  final PdpPricing pricing;
  final PdpStockManagement stockManagement;
  final PdpMarketingTriggers marketingTriggers;
  final PdpShippingLogistics shippingLogistics;
  final PdpSeo seo;
  final PdpMedia media;
  final PdpDetails details;
  final List<dynamic> relatedProducts;

  ProductPdpData({
    required this.id,
    required this.name,
    required this.slug,
    required this.pricing,
    required this.stockManagement,
    required this.marketingTriggers,
    required this.shippingLogistics,
    required this.seo,
    required this.media,
    required this.details,
    required this.relatedProducts,
  });

  factory ProductPdpData.fromJson(Map<String, dynamic> json) {
    return ProductPdpData(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      pricing: PdpPricing.fromJson(json['pricing'] ?? {}),
      stockManagement: PdpStockManagement.fromJson(json['stock_management'] ?? {}),
      marketingTriggers: PdpMarketingTriggers.fromJson(json['marketing_triggers'] ?? {}),
      shippingLogistics: PdpShippingLogistics.fromJson(json['shipping_logistics'] ?? {}),
      seo: PdpSeo.fromJson(json['seo'] ?? {}),
      media: PdpMedia.fromJson(json['media'] ?? {}),
      details: PdpDetails.fromJson(json['details'] ?? {}),
      relatedProducts: json['related_products'] ?? [],
    );
  }
}

class PdpPricing {
  final double currentPrice;
  final double originalPrice;
  final int discountPercentage;
  final String currency;

  PdpPricing({
    required this.currentPrice,
    required this.originalPrice,
    required this.discountPercentage,
    required this.currency,
  });

  factory PdpPricing.fromJson(Map<String, dynamic> json) {
    return PdpPricing(
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: json['discount_percentage'] ?? 0,
      currency: json['currency'] ?? 'COP',
    );
  }
}

class PdpStockManagement {
  final String status;
  final int availableQuantity;
  final bool showLowStockWarning;
  final bool allowBackorderSubscription;

  PdpStockManagement({
    required this.status,
    required this.availableQuantity,
    required this.showLowStockWarning,
    required this.allowBackorderSubscription,
  });

  factory PdpStockManagement.fromJson(Map<String, dynamic> json) {
    return PdpStockManagement(
      status: json['status'] ?? 'out_of_stock',
      availableQuantity: json['available_quantity'] ?? 0,
      showLowStockWarning: json['show_low_stock_warning'] ?? false,
      allowBackorderSubscription: json['allow_backorder_subscription'] ?? false,
    );
  }
}

class PdpMarketingTriggers {
  final int totalSalesCount;
  final int viewersRightNow;
  final String badge;

  PdpMarketingTriggers({
    required this.totalSalesCount,
    required this.viewersRightNow,
    required this.badge,
  });

  factory PdpMarketingTriggers.fromJson(Map<String, dynamic> json) {
    return PdpMarketingTriggers(
      totalSalesCount: json['total_sales_count'] ?? 0,
      viewersRightNow: json['viewers_right_now'] ?? 0,
      badge: json['badge'] ?? '',
    );
  }
}

class PdpShippingLogistics {
  final bool freeShippingEligible;
  final double freeShippingThreshold;
  final String estimatedDeliveryText;

  PdpShippingLogistics({
    required this.freeShippingEligible,
    required this.freeShippingThreshold,
    required this.estimatedDeliveryText,
  });

  factory PdpShippingLogistics.fromJson(Map<String, dynamic> json) {
    return PdpShippingLogistics(
      freeShippingEligible: json['free_shipping_eligible'] ?? false,
      freeShippingThreshold: (json['free_shipping_threshold'] as num?)?.toDouble() ?? 0.0,
      estimatedDeliveryText: json['estimated_delivery_text'] ?? '',
    );
  }
}

class PdpSeo {
  final String metaTitle;
  final String metaDescription;

  PdpSeo({required this.metaTitle, required this.metaDescription});

  factory PdpSeo.fromJson(Map<String, dynamic> json) {
    return PdpSeo(
      metaTitle: json['meta_title'] ?? '',
      metaDescription: json['meta_description'] ?? '',
    );
  }
}

class PdpMedia {
  final String primaryImage;
  final List<String> gallery;

  PdpMedia({required this.primaryImage, required this.gallery});

  factory PdpMedia.fromJson(Map<String, dynamic> json) {
    return PdpMedia(
      primaryImage: json['primary_image'] ?? '',
      gallery: List<String>.from(json['gallery'] ?? []),
    );
  }
}

class PdpDetails {
  final String description;
  final List<int> box;
  final List<dynamic> categories;
  final String categoryText;

  PdpDetails({
    required this.description,
    required this.box,
    required this.categories,
    required this.categoryText,
  });

  factory PdpDetails.fromJson(Map<String, dynamic> json) {
    return PdpDetails(
      description: json['description'] ?? '',
      box: List<int>.from(json['box'] ?? []),
      categories: json['categories'] ?? [],
      categoryText: json['category_text'] ?? '',
    );
  }
}