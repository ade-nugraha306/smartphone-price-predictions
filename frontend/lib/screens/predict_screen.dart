import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';

class PredictScreen extends StatefulWidget {
  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  List<dynamic> recommendations = [];

  @override
  void dispose() {
    pcCtrl.dispose();
    fcCtrl.dispose();
    pxWCtrl.dispose();
    pxHCtrl.dispose();
    super.dispose();
  }

  void resetForm() {
    setState(() {
      ram = 4096;
      battery = 4000;
      performanceLevel = 'sedang'; // reset ke default

      pcCtrl.clear();
      fcCtrl.clear();
      pxWCtrl.clear();
      pxHCtrl.clear();

      result = null;
      recommendations = [];
    });
  }

  double ram = 4096;
  double battery = 4000;
  String performanceLevel = 'sedang'; // ganti cores & clock dengan ini

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _formKey = GlobalKey<FormState>();

  final pcCtrl = TextEditingController();
  final fcCtrl = TextEditingController();
  final pxWCtrl = TextEditingController();
  final pxHCtrl = TextEditingController();

  String? result;
  bool loading = false;

  // Fungsi helper untuk convert performance level ke cores & clock speed
  Map<String, dynamic> getPerformanceSpecs(String level) {
    switch (level) {
      case 'hemat':
        return {'cores': 4, 'clock_speed': 1.5};
      case 'sedang':
        return {'cores': 8, 'clock_speed': 2.0};
      case 'tinggi':
        return {'cores': 8, 'clock_speed': 2.5};
      case 'maksimal':
        return {'cores': 12, 'clock_speed': 3.0};
      default:
        return {'cores': 8, 'clock_speed': 2.0};
    }
  }

  String? _requiredNumber(
    String? v, {
    int? min,
    int? max,
  }) {
    if (v == null || v.isEmpty) return "Wajib diisi";
    final n = int.tryParse(v);
    if (n == null) return "Harus berupa angka";
    if (min != null && n < min) return "Minimal $min";
    if (max != null && n > max) return "Maksimal $max";
    return null;
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      result = null;
      recommendations = [];
    });

    final perfSpecs = getPerformanceSpecs(performanceLevel);

    final spec = {
      "battery_power": battery.toInt(),
      "clock_speed": perfSpecs['clock_speed'],
      "fc": int.parse(fcCtrl.text),
      "int_memory": 128,
      "m_dep": 0.5,
      "mobile_wt": 180,
      "n_cores": perfSpecs['cores'],
      "pc": int.parse(pcCtrl.text),
      "px_height": int.parse(pxHCtrl.text),
      "px_width": int.parse(pxWCtrl.text),
      "ram": ram.toInt(),
      "sc_h": 6,
      "sc_w": 3,
      "talk_time": 20,
      "touch_screen": 1,
      "wifi": 1
    };

    try {
      final res = await ApiService.predictAndRecommend(spec);

      setState(() {
        result =
            "${res['price_label']}\nEstimasi Harga: ${res['price_category']}";
        recommendations = res['recommendations'] ?? [];
      });
    } catch (e) {
      setState(() {
        result = "Gagal memprediksi";
        recommendations = [];
      });
    }

    setState(() => loading = false);
  }

  Widget field(
    String label,
    TextEditingController c, {
    String? Function(String?)? validator,
    TextInputType type = TextInputType.number,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget sliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ${value.toInt()} $unit",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toInt().toString(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget performanceSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Performa HP",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            "Pilih tingkat performa yang diinginkan",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _performanceChip(
                'hemat',
                'Hemat Daya',
                'Untuk penggunaan ringan',
                Icons.eco,
                Colors.green,
              ),
              _performanceChip(
                'sedang',
                'Standar',
                'Cocok untuk harian',
                Icons.phone_android,
                Colors.blue,
              ),
              _performanceChip(
                'tinggi',
                'Kencang',
                'Gaming & multitasking',
                Icons.speed,
                Colors.orange,
              ),
              _performanceChip(
                'maksimal',
                'Maksimal',
                'Performa tertinggi',
                Icons.rocket_launch,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceChip(
    String value,
    String label,
    String desc,
    IconData icon,
    Color color,
  ) {
    final isSelected = performanceLevel == value;
    return FilterChip(
      selected: isSelected,
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: isSelected ? Colors.white : color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.white70 : Colors.grey,
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => performanceLevel = value);
        }
      },
      selectedColor: color,
      padding: const EdgeInsets.all(12),
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prediksi Harga Smartphone")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              sliderField(
                label: "RAM",
                value: ram,
                min: 512,
                max: 16384,
                divisions: 31,
                unit: "MB",
                onChanged: (v) => setState(() => ram = v),
              ),
              sliderField(
                label: "Kapasitas Baterai",
                value: battery,
                min: 2000,
                max: 7000,
                divisions: 50,
                unit: "mAh",
                onChanged: (v) => setState(() => battery = v),
              ),
              field("Kamera Utama (MP)", pcCtrl,
                  validator: (v) => _requiredNumber(v, min: 2, max: 200)),
              field("Kamera Depan (MP)", fcCtrl,
                  validator: (v) => _requiredNumber(v, min: 0, max: 64)),
              performanceSelector(),
              field("Resolusi Lebar (px)", pxWCtrl,
                  validator: (v) => _requiredNumber(v, min: 480, max: 4000)),
              field("Resolusi Tinggi (px)", pxHCtrl,
                  validator: (v) => _requiredNumber(v, min: 800, max: 5000)),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text("Prediksi"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: resetForm,
                      child: const Text("Reset"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (result != null)
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      result!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              if (recommendations.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      "Rekomendasi Smartphone",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...recommendations.map((hp) {
                      return Card(
                        child: ListTile(
                          title: Text("${hp['brand']} ${hp['model']}"),
                          subtitle: Text(
                            "Harga: ${currencyFormatter.format(hp['price_idr'])}\n"
                            "Kategori: ${hp['price_category']}",
                          ),
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}