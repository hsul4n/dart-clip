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
    int? quality = 50,
    int? maxHeight,
    int? maxWidth,
    int? minHeight,
    int? minWidth,
    ClipFieldValidator<PickedFile>? validator,
    List<ImageSource> sources = const [ImageSource.camera, ImageSource.gallery],
    List<ClipOption> options = const [ClipOption.zoom, ClipOption.delete],
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
          builder: (ClipFieldState<PickedFile> state) {
            void onChangedHandler(PickedFile? value) {
              if (onChanged != null) {
                onChanged(value);
              }

              state.didChange(value);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  child: builder(state.context, state.value),
                  onTap: () {
                    showModalBottomSheet(
                      context: state.context,
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
                                      Navigator.of(state.context).pop();

                                      state.onPause.call();

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
                                            // targetWidth: minWidth,
                                            // targetHeight: minHeight,
                                            // quality: quality,
                                          );
                                        }
                                      }).then((file) {
                                        if (file != null) {
                                          onChangedHandler(
                                              PickedFile(file.path));
                                        }
                                      }).whenComplete(state.onResume);
                                    },
                                  ),
                                )
                                .toList(),
                            if (state.value != null) ...[
                              if (options.contains(ClipOption.zoom))
                                ListTile(
                                  leading: Icon(Icons.zoom_out_map_outlined),
                                  title:
                                      Text(ClipLocalizations.of(context)!.zoom),
                                  onTap: () {
                                    state.value!.readAsBytes().then((value) {
                                      Navigator.of(context)
                                        ..pop()
                                        ..push(
                                          MaterialPageRoute(
                                            builder: (context) => Scaffold(
                                              appBar: AppBar(),
                                              body: PhotoView(
                                                imageProvider:
                                                    MemoryImage(value),
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
                if (state.hasError)
                  Text(
                    state.errorText,
                    style: Theme.of(state.context)
                        .textTheme
                        .caption!
                        .copyWith(color: Theme.of(state.context).errorColor),
                  ),
              ],
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
