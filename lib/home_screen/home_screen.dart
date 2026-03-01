import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:food_scannner/widget/desclairmer_container.dart';
import 'package:image_picker/image_picker.dart';
import '../food_analyzer/food-analyzer.dart';
import '../widget/action_button.dart';
import '../widget/bullet_point.dart';
import '../widget/loading_animation.dart';
import '../widget/section_title.dart';

class FoodScanPage extends StatefulWidget {
  const FoodScanPage({super.key});

  @override
  State<FoodScanPage> createState() => _FoodScanPageState();
}

class _FoodScanPageState extends State<FoodScanPage>
    with TickerProviderStateMixin {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  String _mimeType = "image/jpeg";

  bool _loading = false;
  String? _error;
  FoodAnalysis? _result;

  late final FoodAnalyzer _analyzer;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _analyzer = FoodAnalyzer();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _error = null;
      _result = null;
    });

    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final path = file.path.toLowerCase();
    final mime = path.endsWith(".png") ? "image/png" : "image/jpeg";

    setState(() {
      _imageBytes = bytes;
      _mimeType = mime;
    });
  }

  Future<void> _analyze() async {
    if (_imageBytes == null) {
      setState(() => _error = "Please select an image first.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final res = await _analyzer.analyzeFoodImage(
        bytes: _imageBytes!,
        mimeType: _mimeType,
      );
      setState(() => _result = res);
      _slideController.forward(from: 0);
    } catch (e) {
      setState(() => _error = "Analyze failed: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _badgeColor(String label) {
    switch (label) {
      case "healthy":
        return const Color(0xFF4CAF50);
      case "not_healthy":
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFFF9800);
    }
  }

  IconData _badgeIcon(String label) {
    switch (label) {
      case "healthy":
        return Icons.check_circle;
      case "not_healthy":
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // App Bar
          Container(
            height: 130,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 40),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AI Food Analyzer",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          "Analyze your meals",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF95A5A6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Image Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white),
                    gradient:
                        _imageBytes == null
                            ? const LinearGradient(
                              colors: [
                                Color(0xFFBBDEFB),
                                Color(0xFFE3F2FD),
                                Color(0xFFBBDEFB),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child:
                      _imageBytes == null
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale:
                                          1.0 + (_pulseController.value * 0.1),
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 48,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No image selected",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Tap camera or gallery below",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF95A5A6),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(_imageBytes!, fit: BoxFit.cover),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap:
                                        () =>
                                            setState(() => _imageBytes = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: "Camera",
                        color: const Color(0xFF4CAF50),
                        onPressed:
                            _loading ? null : () => _pick(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionButton(
                        icon: Icons.photo_library_rounded,
                        label: "Gallery",
                        color: const Color(0xFF2196F3),
                        onPressed:
                            _loading ? null : () => _pick(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Analyze Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        _loading
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Analyzing...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 20),
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.analytics_rounded,
                                  size: 22,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Analyze Food or Drink",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),

                // Error Message
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFE53935),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFFE53935)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Results Card
                if (r != null) ...[
                  const SizedBox(height: 24),
                  (r.foodsAndDrinkOrNot == "food_or_drink")
                      ? SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Header with gradient
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _badgeColor(r.label).withOpacity(0.1),
                                        _badgeColor(r.label).withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      topRight: Radius.circular(24),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _badgeColor(
                                            r.label,
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          _badgeIcon(r.label),
                                          color: _badgeColor(r.label),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.label
                                                  .replaceAll("_", " ")
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: _badgeColor(r.label),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 18,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Health Score",
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _badgeColor(r.label),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          "${r.score}/10",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [


                                      //Text("${r.drink_or_food}"),
                                      Container(
                                        width: 80,
                                        height: 5,
                                        decoration: BoxDecoration(),
                                      ),
                                      // Recommendation
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F7FA),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.lightbulb_outline,
                                              color: Color(0xFF4CAF50),
                                            ),
                                            const SizedBox(width: 12),
                                            if ("eat" == r.action) ...[
                                              if (r.drinkOrFood == "food")
                                                Expanded(
                                                  child: Text(
                                                    "${r.action.toUpperCase()} and Stay Healthy",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF2C3E50),
                                                    ),
                                                  ),
                                                )
                                              else
                                                Expanded(
                                                  child: Text(
                                                    "${r.drinkOrFood.toUpperCase()} and Stay Healthy",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF2C3E50),
                                                    ),
                                                  ),
                                                ),
                                            ] else if ("limit" == r.action) ...[
                                              if (r.drinkOrFood == "food")
                                                Expanded(
                                                  child: Text(
                                                    "${r.action.toUpperCase()} eat and ${r.action}",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight.w700,
                                                      color: Color(0xFF2C3E50),
                                                    ),
                                                  ),
                                                )
                                              else
                                                Expanded(
                                                  child: Text(
                                                    "${r.drinkOrFood.toUpperCase()} limit",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight.w700,
                                                      color: Color(0xFF2C3E50),
                                                    ),
                                                  ),
                                                ),
                                            ] else ...[
                                              Expanded(
                                                child: Text(
                                                  "Please ${r.action.toUpperCase()} eating.",
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF2C3E50),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 20),
                                      Center(
                                        child: LoadingAnimation(
                                          percentage: r.freshness,
                                        ),
                                      ),
                                      // Reasons
                                      SectionTitle(
                                        icon: Icons.info_outline,
                                        title: "Why",
                                        color: const Color(0xFF2196F3),
                                      ),
                                      const SizedBox(height: 12),
                                      ...r.reasons.map(
                                        (x) => BulletPoint(
                                          text: x,
                                          color: const Color(0xFF2196F3),
                                        ),
                                      ),
                                      const SizedBox(height: 20),



                                      // Tips
                                      SectionTitle(
                                        icon: Icons.tips_and_updates_outlined,
                                        title: "Tips",
                                        color: const Color(0xFFFF9800),
                                      ),
                                      const SizedBox(height: 12),
                                      ...r.tips.map(
                                        (x) => BulletPoint(
                                          text: x,
                                          color: const Color(0xFFFF9800),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Calories
                                      SectionTitle(
                                        icon: Icons.food_bank_outlined,
                                        title: "Calories",
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 12),
                                      BulletPoint(
                                        text: "${r.calories}",
                                        color: const Color(0xFF2196F3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      : SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFFF9800).withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 40,
                              color: Color(0xFFFF9800),
                            ),

                            SizedBox(height: 10),

                            Text(
                              "Not a food item",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            SizedBox(height: 6),

                            Text(
                              "Please scan a food product",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                ],
                const SizedBox(height: 20),
                DesclairmerContainer(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
