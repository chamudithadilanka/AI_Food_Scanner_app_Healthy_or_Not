import 'package:flutter/material.dart';

class DesclairmerContainer extends StatelessWidget {
  const DesclairmerContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return  // Disclaimer
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "AI can be wrong. For allergies/medical diet, ask a qualified professional.",
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
  }
}
