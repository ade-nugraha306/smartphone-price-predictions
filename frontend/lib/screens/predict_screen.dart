import 'package:flutter/material.dart';
import '../services/api_services.dart';

class PredictScreen extends StatefulWidget {
  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  @override
  void dispose() {
    pcCtrl.dispose();
    fcCtrl.dispose();
    clockCtrl.dispose();
    pxWCtrl.dispose();
    pxHCtrl.dispose();
    super.dispose();
  }

  void resetForm() {
    setState(() {
      // reset state-driven widgets
      ram = 4096;
      battery = 4000;
      cores = 8;

      // reset text fields
      pcCtrl.clear();
      fcCtrl.clear();
      clockCtrl.clear();
      pxWCtrl.clear();
      pxHCtrl.clear();

      result = null;
    });
  }

  double ram = 4096;       // MB
  double battery = 4000;  // mAh
  int cores = 8;
  
  final _formKey = GlobalKey<FormState>();

  final pcCtrl = TextEditingController();
  final fcCtrl = TextEditingController();
  final clockCtrl = TextEditingController();
  final pxWCtrl = TextEditingController();
  final pxHCtrl = TextEditingController();

  String? result;
  bool loading = false;

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

  String? _requiredDouble(
    String? v, {
    double? min,
    double? max,
  }) {
    if (v == null || v.isEmpty) return "Wajib diisi";
    final n = double.tryParse(v);
    if (n == null) return "Harus berupa angka";
    if (min != null && n < min) return "Minimal $min";
    if (max != null && n > max) return "Maksimal $max";
    return null;
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final spec = {
      "battery_power": battery.toInt(),
      "clock_speed": double.parse(clockCtrl.text),
      "fc": int.parse(fcCtrl.text),
      "int_memory": 128,
      "m_dep": 0.5,
      "mobile_wt": 180,
      "n_cores": cores,
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
      final res = await ApiService.predict(spec);
      setState(() {
        result =
            "${res['label']}\nEstimasi Harga: ${res['price_estimate']}";
      });
    } catch (e) {
      setState(() => result = "Gagal memprediksi");
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

  Widget coreDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        value: cores,
        items: [2, 4, 6, 8, 12, 16]
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text("$c cores"),
                ))
            .toList(),
        onChanged: (v) => setState(() => cores = v!),
        decoration: const InputDecoration(
          labelText: "CPU Cores",
          helperText: "Jumlah core prosesor",
          border: OutlineInputBorder(),
        ),
      ),
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
                label: "Battery",
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
              coreDropdown(),
              field("Clock Speed (GHz)", clockCtrl,
                  type: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      _requiredDouble(v, min: 0.5, max: 5.0)),
              field("Resolusi Lebar (px)", pxWCtrl,
                  validator: (v) =>
                      _requiredNumber(v, min: 480, max: 4000)),
              field("Resolusi Tinggi (px)", pxHCtrl,
                  validator: (v) =>
                      _requiredNumber(v, min: 800, max: 5000)),

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
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
