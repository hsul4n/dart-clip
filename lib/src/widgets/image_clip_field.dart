import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clip/clip.dart';
import 'package:photo_view/photo_view.dart';

part '../localizations.dart';

enum ClipOption {
  zoom,
  delete,
}

class ImageClipField extends ClipField<Uint8List> {
  ImageClipField({
    @required Key key,
    @required Widget Function(BuildContext, Uint8List) builder,
    dynamic initialValue,
    ValueChanged<Uint8List> onChanged,
    ClipFieldSetter<Uint8List> onSaved,
    int quality,
    List<ImageSource> sources = const [ImageSource.camera, ImageSource.gallery],
    List<ClipOption> options = const [ClipOption.zoom, ClipOption.delete],
  }) : super(
          key: key,
          initialValue: () => Future.value(initialValue),
          onSaved: onSaved,
          builder: (ClipFieldState<Uint8List> field) {
            final _imagePicker = ImagePicker();

            void onChangedHandler(Uint8List value) {
              if (onChanged != null) {
                onChanged(value);
              }

              field.didChange(value);
            }

            return GestureDetector(
              child: builder(field.context, field.value),
              onTap: () {
                showModalBottomSheet(
                  context: field.context,
                  builder: (BuildContext context) {
                    final t = _ClipLocalizations.of(field.context);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...sources
                            .map(
                              (source) => ListTile(
                                leading: Icon(
                                  source == ImageSource.camera
                                      ? Icons.photo_camera_outlined
                                      : Icons.photo_library_outlined,
                                ),
                                title: Text(
                                  t[source == ImageSource.camera
                                      ? 'camera'
                                      : 'gallery'],
                                ),
                                onTap: () async {
                                  Navigator.of(field.context).pop();

                                  field.onPause?.call();

                                  final image = await _imagePicker
                                      .getImage(
                                        source: source,
                                        imageQuality: quality,
                                        maxHeight: 1024,
                                        maxWidth: 1024,
                                      )
                                      .whenComplete(field.onResume?.call);

                                  if (image != null) {
                                    image.readAsBytes().then(onChangedHandler);
                                  }
                                },
                              ),
                            )
                            .toList(),
                        if (field.value != null) ...[
                          if (options.contains(ClipOption.zoom))
                            ListTile(
                              leading: Icon(Icons.zoom_out_map_outlined),
                              title: Text(t['zoom']),
                              onTap: () {
                                Navigator.of(context)
                                  ..pop()
                                  ..push(
                                    MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                        appBar: AppBar(),
                                        body: PhotoView(
                                          imageProvider:
                                              MemoryImage(field.value),
                                        ),
                                      ),
                                    ),
                                  );
                              },
                            ),
                          if (options.contains(ClipOption.delete))
                            ListTile(
                              leading: Icon(
                                Icons.delete_outlined,
                                color: Colors.red[600],
                              ),
                              title: Text(
                                t['remove'],
                                style: TextStyle(color: Colors.red[600]),
                              ),
                              onTap: () {
                                onChangedHandler(null);
                                Navigator.of(context).pop();
                              },
                            ),
                        ]
                      ],
                    );
                  },
                );
              },
            );
          },
        );

  @override
  _ImageClipFieldState createState() => _ImageClipFieldState();
}

class _ImageClipFieldState extends ClipFieldState<Uint8List> {
  @override
  ImageClipField get widget => super.widget as ImageClipField;
}
