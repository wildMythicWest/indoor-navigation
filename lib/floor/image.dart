import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

import 'floor_ids.dart';

class ImageSelectorWidget extends StatefulWidget {

  final String selectedImage;
  final List<Marker> pins;
  final Function(String) onImageChanged;
  final Function(Offset) onPinPlaced;
  final List<CustomPaint> painters;

  const ImageSelectorWidget({super.key,
    required this.selectedImage,
    required this.pins,
    required this.onImageChanged,
    required this.onPinPlaced,
    this.painters = const [],
  });

  @override
  ImageSelectorWidgetState createState() => ImageSelectorWidgetState();
}

class ImageSelectorWidgetState extends State<ImageSelectorWidget> {

  final TransformationController _transformationController = TransformationController();

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: widget.selectedImage,
              onChanged: (String? newValue) {
                widget.onImageChanged(newValue!);
              },
              items: FloorId.allPlans.map<DropdownMenuItem<String>>((String image) {
                return DropdownMenuItem<String>(
                  value: image,
                  child: Text(image), // Show filename only
                );
              }).toList(),
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (TapDownDetails details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset localPosition = box.globalToLocal(details.globalPosition);

                  final Matrix4 matrix = _transformationController.value;
                  final Matrix4 inverseMatrix = Matrix4.inverted(matrix);
                  final vector_math.Vector3 transformedPosition = inverseMatrix.transform3(vector_math.Vector3(localPosition.dx, localPosition.dy, 0));

                  widget.onPinPlaced(Offset(transformedPosition.x, transformedPosition.y));

                  print("Pin placed at: ${transformedPosition.x}, ${transformedPosition.y}");
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
                          'assets/${widget.selectedImage}',
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                        ...widget.painters,
                      for (var savedPin in widget.pins)
                        Positioned(
                          left: savedPin.position.dx + savedPin.adjustment.dx,
                          top: savedPin.position.dy + savedPin.adjustment.dy,
                          child: savedPin.icon,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
    );
  }
}

class Pin extends Marker {
  final Offset pinPosition;
  final Color color;

  Pin({required this.pinPosition, required this.color})
    : super(position: pinPosition, icon: Icon(Icons.location_on, color: color, size: 24,), adjustment: const Offset(-12, -24));
}

class Marker {
  final Offset position;
  final Icon icon;
  final Offset adjustment;

  Marker({required this.position, required this.icon, required this.adjustment, });
}