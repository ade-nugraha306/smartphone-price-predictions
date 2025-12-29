class PredictionResult {
  final int priceRange;
  final String label;
  final String priceEstimate;

  PredictionResult({
    required this.priceRange,
    required this.label,
    required this.priceEstimate,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      priceRange: json['price_range'],
      label: json['label'],
      priceEstimate: json['price_estimate'],
    );
  }
}
