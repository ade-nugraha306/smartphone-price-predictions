class PredictionResult {
  final int priceSegment;
  final String label;
  final String category;

  PredictionResult({
    required this.priceSegment,
    required this.label,
    required this.category,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      priceSegment: json['price_segment'],
      label: json['label'],
      category: json['category'],
    );
  }
}
