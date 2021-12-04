import 'dart:io';
import 'dart:typed_data';

import 'package:clip/l10n/clip_localizations.dart';
import 'package:clip/src/widgets/gallery_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:clip/clip.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

enum ClipOption {
  zoom,
  delete,
}

class ImageClipField extends ClipField<XFile> {
  static final _imagePicker = ImagePicker();

  ImageClipField({
    Key? key,
    required Widget Function(BuildContext, XFile?) builder,
    dynamic initialValue,
    ValueChanged<XFile?>? onChanged,
    ClipFieldSetter<XFile>? onSaved,
    int quality = 100,
    int? maxHeight,
    int? maxWidth,
    ClipFieldValidator<XFile>? validator,
    List<ImageSource> sources = const [ImageSource.camera, ImageSource.gallery],
    List<ClipOption> options = const [ClipOption.zoom, ClipOption.delete],
    bool? enabled,
    InputDecoration? decoration = const InputDecoration(),
    AutovalidateMode? autovalidateMode,
  })  : assert(sources.isNotEmpty),
        assert(options.isNotEmpty),
        super(
          key: key,
          autovalidateMode: autovalidateMode,
          initialValue: () async {
            if (initialValue != null) {
              if (initialValue is String) {
                return DefaultCacheManager()
                    .getSingleFile(initialValue)
                    .then((value) => XFile(value.path));
              } else if (initialValue is Uint8List)
                return Future.value(XFile(File.fromRawPath(initialValue).path));
              else
                throw UnsupportedError('cant get base64');
            }

            return null;
          },
          onSaved: onSaved,
          validator: validator,
          enabled: enabled ?? decoration?.enabled ?? true,
          builder: (ClipFieldState<XFile> field) {
            final InputDecoration effectiveDecoration = (decoration ??
                    const InputDecoration())
                .applyDefaults(Theme.of(field.context).inputDecorationTheme);

            void onChangedHandler(XFile? value) {
              field.didChange(value);
              if (onChanged != null) {
                onChanged(value);
              }
            }

            return IntrinsicWidth(
              child: InputDecorator(
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
                                          ? ClipLocalizations.of(context)!
                                              .camera
                                          : ClipLocalizations.of(context)!
                                              .gallery,
                                    ),
                                    onTap: () async {
                                      Navigator.of(field.context).pop();

                                      field.onPause.call();

                                      _imagePicker
                                          .pickImage(
                                        source: source,
                                        imageQuality: quality,
                                        maxHeight: maxHeight?.toDouble(),
                                        maxWidth: maxWidth?.toDouble(),
                                      )
                                          .then((file) {
                                        if (file != null) {
                                          onChangedHandler(XFile(file.path));
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
                                    Navigator.of(context)
                                      ..pop()
                                      ..push(
                                        MaterialPageRoute(
                                            builder: (context) => GalleryPage(
                                                    attachments: [
                                                      File(field.value!.path)
                                                    ])),
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
              ),
            );
          },
        );

  @override
  _ImageClipFieldState createState() => _ImageClipFieldState();
}

class _ImageClipFieldState extends ClipFieldState<XFile> {
  @override
  ImageClipField get widget => super.widget as ImageClipField;
}
