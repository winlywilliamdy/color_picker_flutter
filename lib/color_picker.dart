//////////////////////////////
//
// 2019, roipeker.com
// screencast - demo simple image:
// https://youtu.be/EJyRH4_pY8I
//
// screencast - demo snapshot:
// https://youtu.be/-LxPcL7T61E
//
//////////////////////////////
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;

class ColorPickerWidget extends StatefulWidget {
  @override
  _ColorPickerWidgetState createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  String imagePath = 'assets/images/santorini.jpg';
  GlobalKey imageKey = GlobalKey();
  GlobalKey paintKey = GlobalKey();

  // CHANGE THIS FLAG TO TEST BASIC IMAGE, AND SNAPSHOT.
  bool useSnapshot = false;

  // based on useSnapshot=true ? paintKey : imageKey ;
  // this key is used in this example to keep the code shorter.
  late GlobalKey currentKey;

  final StreamController<Color> _stateController = StreamController<Color>();
  late img.Image photo;

  @override
  void initState() {
    currentKey = useSnapshot ? paintKey : imageKey;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final String title = useSnapshot ? "snapshot" : "basic";
    return Scaffold(
        appBar: AppBar(title: Text("Color picker $title")),
        body: Column(
          children: [
            StreamBuilder(
                initialData: Colors.green[500],
                stream: _stateController.stream,
                builder: (buildContext, snapshot) {
                  Color selectedColor = snapshot.data ?? Colors.green;
                  return Stack(children: <Widget>[
                    RepaintBoundary(
                        key: paintKey,
                        child: GestureDetector(
                            onPanDown: (details) {
                              searchPixel(details.globalPosition);
                            },
                            onPanUpdate: (details) {
                              searchPixel(details.globalPosition);
                            },
                            child: Center(child: Image.asset(imagePath, key: imageKey, fit: BoxFit.none)))),
                    Container(
                      margin: const EdgeInsets.all(70),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedColor,
                          border: Border.all(width: 2.0, color: Colors.white),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
                    ),
                    Positioned(
                        left: 114,
                        top: 95,
                        child: Text('${selectedColor}', style: const TextStyle(color: Colors.white, backgroundColor: Colors.black54))),
                  ]);
                }),
            ElevatedButton(
                onPressed: () async {
                  await loadImageBundleBytes();
                },
                child: Text("Load Image"))
          ],
        ));
  }

  void searchPixel(Offset globalPosition) async {
    if (photo == null) {
      await (loadImageBundleBytes());
    }
    _calculatePixel(globalPosition);
  }

  void _calculatePixel(Offset globalPosition) {
    RenderBox box = currentKey.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(globalPosition);

    double px;
    double py;
    try {
      px = localPosition.dx;
      py = localPosition.dy;
    } catch (e) {
      px = 0;
      py = 0;
    }

    if (!useSnapshot) {
      double? widgetScale = box.size.width / photo.width;
      px = (px / widgetScale);
      py = (py / widgetScale);
    }

    img.Pixel pixel32 = photo.getPixel(px.toInt(), py.toInt());
    print(pixel32);
    Color hex = abgrToArgb(pixel32);

    _stateController.add(hex);
  }

  Future<void> loadImageBundleBytes() async {
    ByteData imageBytes = await rootBundle.load(imagePath);
    setImageBytes(imageBytes);
  }

  // Future<void> loadSnapshotBytes() async {
  //   RenderRepaintBoundary? boxPaint = paintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  //   ui.Image? capture = await boxPaint?.toImage();
  //   ByteData? imageBytes = await capture!.toByteData(format: ui.ImageByteFormat.png);
  //   setImageBytes(imageBytes!);
  //   capture.dispose();
  // }

  void setImageBytes(ByteData imageBytes) {
    var values = imageBytes.buffer.asUint8List();
    photo = img.decodeImage(values)!;
    print(photo);
  }
}

// image lib uses uses KML color format, convert #AABBGGRR to regular #AARRGGBB
Color abgrToArgb(img.Pixel pixel32) {
  var pixelList = (pixel32.toList());
  int r = pixelList[0] as int;
  int g = pixelList[1] as int;
  int b = pixelList[2] as int;
  return ui.Color.fromARGB(255, r, g, b);
}
