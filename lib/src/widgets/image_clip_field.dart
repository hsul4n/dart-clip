import 'dart:io';
import 'dart:typed_data';

import 'package:clip/l10n/clip_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clip/clip.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

enum ClipOption {
  zoom,
  delete,
}

class ImageClipField extends ClipField<PickedFile> {
  static final _imagePicker = ImagePicker();

  ImageClipField({
    Key? key,
    required Widget Function(BuildContext, PickedFile?) builder,
    dynamic initialValue,
    ValueChanged<PickedFile?>? onChanged,
    ClipFieldSetter<PickedFile>? onSaved,
    int quality = 50,
    int? maxHeight,
    int? maxWidth,
    int? minHeight,
    int? minWidth,
    ClipFieldValidator<PickedFile>? validator,
    List<ImageSource> sources = const [ImageSource.camera, ImageSource.gallery],
    List<ClipOption> options = const [ClipOption.zoom, ClipOption.delete],
    bool? enabled,
    InputDecoration? decoration = const InputDecoration(),
  })  : assert(sources.isNotEmpty),
        assert(options.isNotEmpty),
        super(
          key: key,
          initialValue: () async {
            if (initialValue != null) {
              if (initialValue is String) {
                return DefaultCacheManager()
                    .getSingleFile(initialValue)
                    .then((value) => PickedFile(value.path));
              } else if (initialValue is Uint8List)
                return Future.value(
                    PickedFile(File.fromRawPath(initialValue).path));
              else
                throw UnsupportedError('cant get base64');
            }

            return null;
          },
          onSaved: onSaved,
          validator: validator,
          enabled: enabled ?? decoration?.enabled ?? true,
          builder: (ClipFieldState<PickedFile> field) {
            final InputDecoration effectiveDecoration = (decoration ??
                    const InputDecoration())
                .applyDefaults(Theme.of(field.context).inputDecorationTheme);

            void onChangedHandler(PickedFile? value) {
              field.didChange(value);
              if (onChanged != null) {
                onChanged(value);
              }
            }

            return InputDecorator(
              decoration: effectiveDecoration.copyWith(
                errorText: field.hasError ? field.errorText : null,
                isCollapsed: true,
                border: InputBorder.none,
              ),
              child: GestureDetector(
                child: builder(field.context, field.value),
                onTap: () {
                  showModalBottomSheet(
                    context: field.context,
                    builder: (BuildContext context) {
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
                                    source == ImageSource.camera
                                        ? ClipLocalizations.of(context)!.camera
                                        : ClipLocalizations.of(context)!
                                            .gallery,
                                  ),
                                  onTap: () async {
                                    Navigator.of(field.context).pop();

                                    field.onPause.call();

                                    _imagePicker
                                        .getImage(
                                      source: source,
                                      imageQuality: quality,
                                      maxHeight: maxHeight?.toDouble(),
                                      maxWidth: maxWidth?.toDouble(),
                                    )
                                        .then((pickedFile) async {
                                      if (pickedFile != null) {
                                        return await FlutterNativeImage
                                            .compressImage(
                                          pickedFile.path,
                                          targetWidth: minWidth ?? 0,
                                          targetHeight: minHeight ?? 0,
                                          quality: quality,
                                        );
                                      }
                                    }).then((file) {
                                      if (file != null) {
                                        onChangedHandler(PickedFile(file.path));
                                      }
                                    }).whenComplete(field.onResume);
                                  },
                                ),
                              )
                              .toList(),
                          if (field.value != null) ...[
                            if (options.contains(ClipOption.zoom))
                              ListTile(
                                leading: Icon(Icons.zoom_out_map_outlined),
                                title:
                                    Text(ClipLocalizations.of(context)!.zoom),
                                onTap: () {
                                  field.value!.readAsBytes().then((value) {
                                    Navigator.of(context)
                                      ..pop()
                                      ..push(
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(),
                                            body: PhotoView(
                                              imageProvider: MemoryImage(value),
                                            ),
                                          ),
                                        ),
                                      );
                                  });
                                },
                              ),
                            if (options.contains(ClipOption.delete))
                              ListTile(
                                leading: Icon(
                                  Icons.delete_outlined,
                                  color: Colors.red[600],
                                ),
                                title: Text(
                                  ClipLocalizations.of(context)!.remove,
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
              ),
            );
          },
        );

  @override
  _ImageClipFieldState createState() => _ImageClipFieldState();
}

class _ImageClipFieldState extends ClipFieldState<PickedFile> {
  @override
  ImageClipField get widget => super.widget as ImageClipField;
}
