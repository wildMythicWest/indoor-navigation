import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImagePinScreen(),
    );
  }
}

class ImagePinScreen extends StatefulWidget {
  const ImagePinScreen({super.key});

  @override
  ImagePinScreenState createState() => ImagePinScreenState();
}

class ImagePinScreenState extends State<ImagePinScreen> {
  Offset? pinPosition; // Pin position in image coordinates
  Offset? normalizedPinPosition; // Normalized (scale-independent) position
  final TransformationController _transformationController = TransformationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Zoomable Image with Correct Pin")),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: (TapDownDetails details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset localPosition = box.globalToLocal(details.globalPosition);

                // Convert to image coordinate space
                final Matrix4 matrix = _transformationController.value;
                final Matrix4 inverseMatrix = Matrix4.inverted(matrix);
                final vector_math.Vector3 transformedPosition = inverseMatrix.transform3(vector_math.Vector3(localPosition.dx, localPosition.dy, 0));

                setState(() {
                  pinPosition = Offset(transformedPosition.x, transformedPosition.y);
                  normalizedPinPosition = pinPosition; // Save for correct placement after zooming
                });

                print("Pin placed at: ${pinPosition!.dx}, ${pinPosition!.dy}");
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: EdgeInsets.all(20),
                minScale: 1.0,
                maxScale: 4.0,
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/apartment_floor_plan.jpeg', // Replace with your image path
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (pinPosition != null)
                      Positioned(
                        left: pinPosition!.dx - 12, // Adjust for center alignment
                        top: pinPosition!.dy - 12,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}