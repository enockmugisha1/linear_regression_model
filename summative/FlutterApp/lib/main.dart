import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SalaryPredictorApp());
}

class SalaryPredictorApp extends StatelessWidget {
  const SalaryPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salary Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

// ─── Change this to your Render URL after deployment ─────────────────────────
const String kApiBase = 'https://linear-regression-model-747t.onrender.com';
// For local testing with Android emulator use: 'http://10.0.2.2:8000'

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _result;
  bool _isError = false;

  // ── 17 controllers (one per feature) ───────────────────────────────────────
  final _age = TextEditingController();
  final _gender = TextEditingController();
  final _hsGpa = TextEditingController();
  final _sat = TextEditingController();
  final _uniGpa = TextEditingController();
  final _fieldStudy = TextEditingController();
  final _internships = TextEditingController();
  final _projects = TextEditingController();
  final _certs = TextEditingController();
  final _softSkills = TextEditingController();
  final _networking = TextEditingController();
  final _jobOffers = TextEditingController();
  final _careerSat = TextEditingController();
  final _yearsPromo = TextEditingController();
  final _jobLevel = TextEditingController();
  final _wlb = TextEditingController();
  final _entrepreneur = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _age, _gender, _hsGpa, _sat, _uniGpa, _fieldStudy, _internships,
      _projects, _certs, _softSkills, _networking, _jobOffers, _careerSat,
      _yearsPromo, _jobLevel, _wlb, _entrepreneur,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── API call ────────────────────────────────────────────────────────────────
  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _result = null;
      _isError = false;
    });

    final body = jsonEncode({
      'age': int.parse(_age.text),
      'gender': int.parse(_gender.text),
      'high_school_gpa': double.parse(_hsGpa.text),
      'sat_score': int.parse(_sat.text),
      'university_gpa': double.parse(_uniGpa.text),
      'field_of_study': int.parse(_fieldStudy.text),
      'internships_completed': int.parse(_internships.text),
      'projects_completed': int.parse(_projects.text),
      'certifications': int.parse(_certs.text),
      'soft_skills_score': int.parse(_softSkills.text),
      'networking_score': int.parse(_networking.text),
      'job_offers': int.parse(_jobOffers.text),
      'career_satisfaction': int.parse(_careerSat.text),
      'years_to_promotion': int.parse(_yearsPromo.text),
      'current_job_level': int.parse(_jobLevel.text),
      'work_life_balance': int.parse(_wlb.text),
      'entrepreneurship': int.parse(_entrepreneur.text),
    });

    try {
      final response = await http
          .post(
            Uri.parse('$kApiBase/predict'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final salary = data['predicted_starting_salary'];
        setState(() {
          _result = 'Predicted Starting Salary: \$${salary.toStringAsFixed(2)} USD';
          _isError = false;
        });
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _result = 'Error ${response.statusCode}: ${data['detail'] ?? 'Unknown error'}';
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Connection error: $e';
        _isError = true;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Field builders ──────────────────────────────────────────────────────────
  Widget _intField(
    TextEditingController ctrl,
    String label,
    String hint, {
    int? min,
    int? max,
  }) {
    return _fieldRow(
      label,
      TextFormField(
        controller: ctrl,
        decoration: InputDecoration(hintText: hint),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          final n = int.tryParse(v);
          if (n == null) return 'Enter a whole number';
          if (min != null && n < min) return 'Min value is $min';
          if (max != null && n > max) return 'Max value is $max';
          return null;
        },
      ),
    );
  }

  Widget _floatField(
    TextEditingController ctrl,
    String label,
    String hint, {
    double? min,
    double? max,
  }) {
    return _fieldRow(
      label,
      TextFormField(
        controller: ctrl,
        decoration: InputDecoration(hintText: hint),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          final n = double.tryParse(v);
          if (n == null) return 'Enter a valid number';
          if (min != null && n < min) return 'Min value is $min';
          if (max != null && n > max) return 'Max value is $max';
          return null;
        },
      ),
    );
  }

  Widget _fieldRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, right: 8),
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graduate Salary Predictor'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Card(
                  color: const Color(0xFFE3F2FD),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Predict Your Starting Salary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Fill in all 17 fields and tap Predict.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Personal ──────────────────────────────────────────────
                _sectionTitle('Personal Info'),
                _intField(_age, 'Age', '18–65', min: 18, max: 65),
                _intField(_gender, 'Gender', '0=Female  1=Male', min: 0, max: 1),

                // ── Academics ─────────────────────────────────────────────
                _sectionTitle('Academic Background'),
                _floatField(_hsGpa, 'High School GPA', '0.0–4.0', min: 0.0, max: 4.0),
                _intField(_sat, 'SAT Score', '400–1600', min: 400, max: 1600),
                _floatField(_uniGpa, 'University GPA', '0.0–4.0', min: 0.0, max: 4.0),
                _intField(_fieldStudy, 'Field of Study', '0–10 (encoded)', min: 0, max: 10),

                // ── Career & Skills ───────────────────────────────────────
                _sectionTitle('Career & Skills'),
                _intField(_internships, 'Internships Done', '0–10', min: 0, max: 10),
                _intField(_projects, 'Projects Done', '0–20', min: 0, max: 20),
                _intField(_certs, 'Certifications', '0–10', min: 0, max: 10),
                _intField(_softSkills, 'Soft Skills Score', '1–10', min: 1, max: 10),
                _intField(_networking, 'Networking Score', '1–10', min: 1, max: 10),
                _intField(_jobOffers, 'Job Offers', '0–10', min: 0, max: 10),

                // ── Job Context ───────────────────────────────────────────
                _sectionTitle('Job Context'),
                _intField(_careerSat, 'Career Satisfaction', '1–10', min: 1, max: 10),
                _intField(_yearsPromo, 'Years to Promotion', '0–10', min: 0, max: 10),
                _intField(_jobLevel, 'Job Level (encoded)', '0–4', min: 0, max: 4),
                _intField(_wlb, 'Work-Life Balance', '1–10', min: 1, max: 10),
                _intField(_entrepreneur, 'Entrepreneurship', '0=No  1=Yes', min: 0, max: 1),

                const SizedBox(height: 20),

                // ── Predict button ────────────────────────────────────────
                ElevatedButton(
                  onPressed: _loading ? null : _predict,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Predict',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 16),

                // ── Output display area ───────────────────────────────────
                if (_result != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isError
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFE8F5E9),
                      border: Border.all(
                        color: _isError
                            ? const Color(0xFFEF9A9A)
                            : const Color(0xFFA5D6A7),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _result!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isError
                            ? const Color(0xFFC62828)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
