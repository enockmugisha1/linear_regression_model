import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SalaryPredictorApp());
}

const String kApiBase = 'https://linear-regression-model-747t.onrender.com';

class SalaryPredictorApp extends StatelessWidget {
  const SalaryPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Graduate Salary Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: true,
          fillColor: Color(0xFFF5F5F5),
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

// ── Field of Study labels (LabelEncoder alphabetical order) ──────────────────
const List<MapEntry<int, String>> kFieldsOfStudy = [
  MapEntry(0, 'Arts'),
  MapEntry(1, 'Business'),
  MapEntry(2, 'Computer Science'),
  MapEntry(3, 'Education'),
  MapEntry(4, 'Engineering'),
  MapEntry(5, 'Finance'),
  MapEntry(6, 'Law'),
  MapEntry(7, 'Mathematics'),
  MapEntry(8, 'Medicine'),
  MapEntry(9, 'Psychology'),
  MapEntry(10, 'Technology'),
];

const List<MapEntry<int, String>> kJobLevels = [
  MapEntry(0, 'Entry Level'),
  MapEntry(1, 'Junior'),
  MapEntry(2, 'Mid Level'),
  MapEntry(3, 'Senior'),
  MapEntry(4, 'Executive'),
];

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  double? _predictedSalary;
  String? _errorMsg;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ── Text controllers (numeric fields) ──────────────────────────────────────
  final _age = TextEditingController();
  final _hsGpa = TextEditingController();
  final _sat = TextEditingController();
  final _uniGpa = TextEditingController();
  final _internships = TextEditingController();
  final _projects = TextEditingController();
  final _certs = TextEditingController();
  final _yearsPromo = TextEditingController();

  // ── Dropdown values ─────────────────────────────────────────────────────────
  int _gender = 0;
  int _fieldStudy = 2;
  int _jobLevel = 1;
  int _entrepreneurship = 0;

  // ── Slider values ────────────────────────────────────────────────────────────
  double _softSkills = 7;
  double _networking = 6;
  double _jobOffers = 2;
  double _careerSat = 7;
  double _wlb = 7;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _age, _hsGpa, _sat, _uniGpa, _internships,
      _projects, _certs, _yearsPromo,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Fill example values ─────────────────────────────────────────────────────
  void _fillExample() {
    setState(() {
      _age.text = '25';
      _gender = 0;
      _hsGpa.text = '3.5';
      _sat.text = '1280';
      _uniGpa.text = '3.2';
      _fieldStudy = 6;
      _internships.text = '2';
      _projects.text = '6';
      _certs.text = '2';
      _softSkills = 7;
      _networking = 6;
      _jobOffers = 2;
      _careerSat = 7;
      _yearsPromo.text = '4';
      _jobLevel = 1;
      _wlb = 7;
      _entrepreneurship = 0;
      _predictedSalary = null;
      _errorMsg = null;
    });
  }

  // ── Clear all ───────────────────────────────────────────────────────────────
  void _clearAll() {
    _formKey.currentState?.reset();
    setState(() {
      for (final c in [
        _age, _hsGpa, _sat, _uniGpa, _internships,
        _projects, _certs, _yearsPromo,
      ]) {
        c.clear();
      }
      _gender = 0;
      _fieldStudy = 2;
      _jobLevel = 1;
      _entrepreneurship = 0;
      _softSkills = 5;
      _networking = 5;
      _jobOffers = 2;
      _careerSat = 5;
      _wlb = 5;
      _predictedSalary = null;
      _errorMsg = null;
    });
    _animCtrl.reset();
  }

  // ── API call ─────────────────────────────────────────────────────────────────
  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _predictedSalary = null;
      _errorMsg = null;
    });
    _animCtrl.reset();

    final body = jsonEncode({
      'age': int.parse(_age.text),
      'gender': _gender,
      'high_school_gpa': double.parse(_hsGpa.text),
      'sat_score': int.parse(_sat.text),
      'university_gpa': double.parse(_uniGpa.text),
      'field_of_study': _fieldStudy,
      'internships_completed': int.parse(_internships.text),
      'projects_completed': int.parse(_projects.text),
      'certifications': int.parse(_certs.text),
      'soft_skills_score': _softSkills.round(),
      'networking_score': _networking.round(),
      'job_offers': _jobOffers.round(),
      'career_satisfaction': _careerSat.round(),
      'years_to_promotion': int.parse(_yearsPromo.text),
      'current_job_level': _jobLevel,
      'work_life_balance': _wlb.round(),
      'entrepreneurship': _entrepreneurship,
    });

    try {
      final response = await http
          .post(
            Uri.parse('$kApiBase/predict'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _predictedSalary = (data['predicted_starting_salary'] as num).toDouble();
          _errorMsg = null;
        });
        _animCtrl.forward();
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _errorMsg = 'Error ${response.statusCode}: ${data['detail'] ?? 'Unknown error'}';
        });
        _animCtrl.forward();
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Connection error. Check your internet or wait for the server to wake up.';
      });
      _animCtrl.forward();
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Salary tier label ────────────────────────────────────────────────────────
  String _salaryTier(double salary) {
    if (salary >= 100000) return 'High Earner';
    if (salary >= 70000) return 'Above Average';
    if (salary >= 50000) return 'Average';
    return 'Entry Level';
  }

  Color _tierColor(double salary) {
    if (salary >= 100000) return const Color(0xFF1B5E20);
    if (salary >= 70000) return const Color(0xFF2E7D32);
    if (salary >= 50000) return const Color(0xFF388E3C);
    return const Color(0xFF558B2F);
  }

  // ── Reusable widgets ─────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.number,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
            : null,
        validator: validator,
      ),
    );
  }

  Widget _dropdown<T>(
    String label,
    T value,
    List<MapEntry<T, String>> items,
    void Function(T?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        items: items
            .map((e) => DropdownMenuItem<T>(
                  value: e.key,
                  child: Text(e.value, style: const TextStyle(fontSize: 14)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    void Function(double) onChanged, {
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${value.round()}${suffix ?? ''}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF1565C0),
              thumbColor: const Color(0xFF1565C0),
              overlayColor: const Color(0x291565C0),
              inactiveTrackColor: const Color(0xFFBBDEFB),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: (v) => setState(() => onChanged(v)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Graduate Salary Predictor',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Education & Career Success Model',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high, size: 20),
            tooltip: 'Fill Example',
            onPressed: _fillExample,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, size: 20),
            tooltip: 'Clear All',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Info banner ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF90CAF9)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF1565C0), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fill all fields and tap Predict. Tap ✦ (top right) to load an example.',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Personal Info ──────────────────────────────────────────
                _sectionHeader('Personal Info', Icons.person_outline),
                _textField(
                  _age, 'Age', 'e.g. 22',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n < 18 || n > 65) return '18–65';
                    return null;
                  },
                ),
                _dropdown<int>(
                  'Gender',
                  _gender,
                  const [MapEntry(0, 'Female'), MapEntry(1, 'Male')],
                  (v) => setState(() => _gender = v!),
                ),

                // ── Academic Background ────────────────────────────────────
                _sectionHeader('Academic Background', Icons.school_outlined),
                _textField(
                  _hsGpa, 'High School GPA', 'e.g. 3.5',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = double.tryParse(v);
                    if (n == null || n < 0 || n > 4.0) return '0.0–4.0';
                    return null;
                  },
                ),
                _textField(
                  _sat, 'SAT Score', 'e.g. 1280',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n < 400 || n > 1600) return '400–1600';
                    return null;
                  },
                ),
                _textField(
                  _uniGpa, 'University GPA', 'e.g. 3.2',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = double.tryParse(v);
                    if (n == null || n < 0 || n > 4.0) return '0.0–4.0';
                    return null;
                  },
                ),
                _dropdown<int>(
                  'Field of Study',
                  _fieldStudy,
                  kFieldsOfStudy,
                  (v) => setState(() => _fieldStudy = v!),
                ),

                // ── Career & Skills ────────────────────────────────────────
                _sectionHeader('Career & Skills', Icons.work_outline),
                _textField(
                  _internships, 'Internships Completed', 'e.g. 2',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n < 0 || n > 10) return '0–10';
                    return null;
                  },
                ),
                _textField(
                  _projects, 'Projects Completed', 'e.g. 6',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n < 0 || n > 20) return '0–20';
                    return null;
                  },
                ),
                _textField(
                  _certs, 'Certifications', 'e.g. 2',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n < 0 || n > 10) return '0–10';
                    return null;
                  },
                ),
                _slider('Soft Skills Score', _softSkills, 1, 10,
                    (v) => _softSkills = v),
                _slider(
                    'Networking Score', _networking, 1, 10, (v) => _networking = v),
                _slider('Job Offers Received', _jobOffers, 0, 10,
                    (v) => _jobOffers = v),

                // ── Job Context ────────────────────────────────────────────
                _sectionHeader('Job Context', Icons.business_center_outlined),
                _slider('Career Satisfaction', _careerSat, 1, 10,
                    (v) => _careerSat = v),
                _textField(
                  _yearsPromo, 'Years to First Promotion', 'e.g. 3',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n < 0 || n > 10) return '0–10';
                    return null;
                  },
                ),
                _dropdown<int>(
                  'Current Job Level',
                  _jobLevel,
                  kJobLevels,
                  (v) => setState(() => _jobLevel = v!),
                ),
                _slider('Work-Life Balance', _wlb, 1, 10, (v) => _wlb = v),
                _dropdown<int>(
                  'Entrepreneurship',
                  _entrepreneurship,
                  const [MapEntry(0, 'No'), MapEntry(1, 'Yes')],
                  (v) => setState(() => _entrepreneurship = v!),
                ),

                const SizedBox(height: 24),

                // ── Predict Button ─────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _predict,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      disabledBackgroundColor: const Color(0xFF90CAF9),
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_graph, size: 20),
                    label: Text(
                      _loading ? 'Predicting…' : 'Predict',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Result Card ────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _predictedSalary != null
                      ? _buildResultCard()
                      : _errorMsg != null
                          ? _buildErrorCard()
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final salary = _predictedSalary!;
    final tier = _salaryTier(salary);
    final color = _tierColor(salary);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.monetization_on, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          const Text('Predicted Starting Salary',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '\$${salary.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tier,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'USD per year',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        border: Border.all(color: const Color(0xFFEF9A9A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMsg!,
              style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
