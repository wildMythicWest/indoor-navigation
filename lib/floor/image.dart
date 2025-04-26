import 'package:flutter/material.dart';
import 'package:indoor_navigation/fingerprinting/rf_fingerprint_service.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

import 'floor_ids.dart';

class ImageSelectorWidget extends StatefulWidget {

  final String selectedImage;
  final Offset? pinPosition;
  final Function(String) onImageChanged;
  final Function(Offset) onPinPlaced;

  final LocationsRepository locationsRepository;

  const ImageSelectorWidget({super.key,
    required this.selectedImage,
    required this.pinPosition,
    required this.onImageChanged,
    required this.onPinPlaced,
    required this.locationsRepository,
  });

  @override
  ImageSelectorWidgetState createState() => ImageSelectorWidgetState();
}

class ImageSelectorWidgetState extends State<ImageSelectorWidget> {

  final TransformationController _transformationController = TransformationController();
  List<Offset> savedPinPositions = []; // Green pins (loaded positions)
  bool showSavedPins = false; // Toggle state

  // Fetch saved positions from repository
  void fetchSavedPositions() async {
    List<Offset> positions = (await widget.locationsRepository.getAllLocationsOnFloor(widget.selectedImage, false))
        .map((data) => Offset(data.locationX, data.locationY))
        .toList();
    setState(() {
      savedPinPositions = positions;
    });
  }

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
          // Toggle Button for Saved Pins
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  showSavedPins = !showSavedPins;
                  if (showSavedPins) fetchSavedPositions();
                });
              },
              child: Text(showSavedPins ? "Hide Saved Locations" : "Show Saved Locations"),
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (TapDownDetails details) {
                  // todo maybe  extract
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset localPosition = box.globalToLocal(details.globalPosition);

                  // Convert to image coordinate space TODO extract
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
                          'assets/${widget.selectedImage}', // Replace with your image path
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                      if (widget.pinPosition != null)
                        Positioned(
                          left: widget.pinPosition!.dx - 12, // Adjust for center alignment
                          top: widget.pinPosition!.dy - 24,
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),

                      // Show green pins (saved locations) when toggled on
                      if (showSavedPins)
                        for (var savedPin in savedPinPositions)
                          Positioned(
                            left: savedPin.dx - 12,
                            top: savedPin.dy - 24,
                            child: Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 24,
                            ),
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

class Pin {
  final Offset? pinPosition;
  final Color color;

  const Pin({required this.pinPosition, required this.color,});
}