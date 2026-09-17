import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Barangay Map View')),
      body: Stack(
        children: [
          // Mock Map Background
          Container(
            color: Colors.grey.shade200,
            child: CustomPaint(
              painter: MapPainter(),
              child: Container(),
            ),
          ),
          // Heatmap Legend
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Reports Heatmap', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Row(children: [Icon(Icons.circle, color: Colors.red, size: 12), SizedBox(width: 5), Text('High Density')]),
                  Row(children: [Icon(Icons.circle, color: Colors.orange, size: 12), SizedBox(width: 5), Text('Medium Density')]),
                ],
              ),
            ),
          ),
          // Pins
          ..._buildMockPins(appState),
        ],
      ),
    );
  }

  List<Widget> _buildMockPins(AppState state) {
    // Randomish positions for mock pins based on reports
    return state.reports.map((r) {
      final index = state.reports.indexOf(r);
      return Positioned(
        top: 100 + (index * 50) % 300.0,
        left: 50 + (index * 80) % 250.0,
        child: const Icon(Icons.location_on, color: Colors.red, size: 30),
      );
    }).toList();
  }
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade100
      ..style = PaintingStyle.fill;

    // Draw some "Zones"
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.4, size.height * 0.3), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.6, size.height * 0.2, size.width * 0.3, size.height * 0.4), paint);
    
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10;
    
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), roadPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
