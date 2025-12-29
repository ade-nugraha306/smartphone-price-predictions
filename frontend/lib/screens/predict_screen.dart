import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';

class PredictScreen extends StatefulWidget {
  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final pcCtrl = TextEditingController();
  final fcCtrl = TextEditingController();
  final pxWCtrl = TextEditingController();
  final pxHCtrl = TextEditingController();

  // State
  double ram = 4096;
  double battery = 4000;
  bool loading = false;

  String? segmentLabel;
  String? segmentCategory;
  List<dynamic> recommendations = [];

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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
      pcCtrl.clear();
      fcCtrl.clear();
      pxWCtrl.clear();
      pxHCtrl.clear();
      segmentLabel = null;
      segmentCategory = null;
      recommendations = [];
    });
  }

  String? _requiredNumber(String? v, {int? min, int? max}) {
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
      segmentLabel = null;
      segmentCategory = null;
      recommendations = [];
    });

    final pxWidth = int.parse(pxWCtrl.text);
    final pxHeight = int.parse(pxHCtrl.text);
    final pixelCount = pxWidth * pxHeight;

    final spec = {
      "battery_power": battery.toInt(),
      "blue": 1,
      "dual_sim": 1,
      "fc": int.parse(fcCtrl.text),
      "four_g": 1,
      "int_memory": 128,
      "m_dep": 0.5,
      "mobile_wt": 180,
      "pc": int.parse(pcCtrl.text),
      "ram": ram.toInt(),
      "sc_h": 6,
      "sc_w": 3,
      "talk_time": 20,
      "three_g": 1,
      "touch_screen": 1,
      "wifi": 1,
      "pixel_count": pixelCount
    };

    try {
      final res = await ApiService.predictAndRecommend(spec);

      setState(() {
        segmentLabel = res["label"];
        segmentCategory = res["category"];
        recommendations = res["recommendations"] ?? [];
      });
    } catch (e) {
      setState(() {
        segmentLabel = "Gagal memproses (${e.toString()})";
        segmentCategory = null;
        recommendations = [];
      });
    }

    setState(() => loading = false);
  }

  Widget field(String label, TextEditingController c,
      {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
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
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Klasifikasi Segment Harga Smartphone"),
      ),
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

              if (segmentLabel != null)
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Segment Harga",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(segmentLabel!,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text("Kategori Estimasi"),
                        Text(segmentCategory ?? "-"),
                        const SizedBox(height: 12),
                        const Text(
                          "Catatan: Estimasi bersifat indikatif berdasarkan segment, bukan harga pasar.",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
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
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...recommendations.map((hp) {
                      return Card(
                        child: ListTile(
                          title: Text("${hp['brand']} ${hp['model']}"),
                          subtitle: Text(
                            "Referensi harga: ${currencyFormatter.format(hp['price_idr'])}",
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
