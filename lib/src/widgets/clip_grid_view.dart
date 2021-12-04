import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:clip/l10n/clip_localizations.dart';
import 'package:clip/src/widgets/gallery_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:clip/clip.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

typedef ItemWidgetBuilder<ItemType> = Widget Function(
  BuildContext context,
  ItemType item,
  int index,
);

class ClipGridView extends ClipField<List<XFile>> {
  static final _imagePicker = ImagePicker();

  final Widget Function(BuildContext)? emptyBuilder;

  final ItemWidgetBuilder<XFile> itemBuilder;

  /// Corresponds to [GridView.gridDelegate].
  final SliverGridDelegate gridDelegate;

  /// Corresponds to [SliverChildBuilderDelegate.addAutomaticKeepAlives].
  final bool addAutomaticKeepAlives;

  /// Corresponds to [SliverChildBuilderDelegate.addRepaintBoundaries].
  final bool addRepaintBoundaries;

  /// Corresponds to [SliverChildBuilderDelegate.addSemanticIndexes].
  final bool addSemanticIndexes;

  ClipGridView({
    List<dynamic> initialValues = const [],
    ValueChanged<List<XFile>?>? onChanged,
    ClipFieldSetter<List<XFile>>? onSaved,
    int quality = 100,
    int? maxHeight,
    int? maxWidth,
    ClipFieldValidator<List<XFile>>? validator,
    List<ImageSource> sources = const [ImageSource.camera, ImageSource.gallery],
    List<ClipOption> options = const [ClipOption.zoom, ClipOption.delete],
    bool? enabled,
    InputDecoration? decoration = const InputDecoration(),
    AutovalidateMode? autovalidateMode,
    required this.itemBuilder,
    required this.gridDelegate,
    this.emptyBuilder,
    // Corresponds to [ScrollView.controller].
    ScrollController? scrollController,
    // Corresponds to [ScrollView.scrollDirection].
    Axis scrollDirection = Axis.vertical,
    // Corresponds to [ScrollView.reverse].
    bool reverse = false,
    // Corresponds to [ScrollView.primary].
    bool? primary,
    // Corresponds to [ScrollView.physics].
    ScrollPhysics? physics,
    // Corresponds to [ScrollView.shrinkWrap].
    bool shrinkWrap = false,
    // Corresponds to [BoxScrollView.padding].
    EdgeInsetsGeometry? padding,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    // Corresponds to [ScrollView.cacheExtent].
    double? cacheExtent,
    // Corresponds to [ScrollView.dragStartBehavior].
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    // Corresponds to [ScrollView.keyboardDismissBehavior].
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    // Corresponds to [ScrollView.restorationId].
    String? restorationId,
    // Corresponds to [ScrollView.clipBehavior].
    ui.Clip clipBehavior = ui.Clip.hardEdge,
    Key? key,
  })  : assert(sources.isNotEmpty),
        assert(options.isNotEmpty),
        super(
          key: key,
          autovalidateMode: autovalidateMode,
          initialValue: () async {
            final items = <XFile>[];

            if (initialValues is List<String>)
              await Future.forEach<String>(initialValues, (value) async {
                items.add(await DefaultCacheManager()
                    .getSingleFile(value)
                    .then((value) => XFile(value.path)));
              });
            else if (initialValues is List<Uint8List>)
              items.addAll(initialValues
                  .map((value) => XFile(File.fromRawPath(value).path))
                  .toList());
            else if (initialValues is List<File>)
              items.addAll(
                  initialValues.map((value) => XFile(value.path)).toList());

            return items;
          },
          onSaved: onSaved,
          validator: validator,
          enabled: enabled ?? decoration?.enabled ?? true,
          builder: (ClipFieldState<List<XFile>> field) {
            final InputDecoration effectiveDecoration = (decoration ??
                    const InputDecoration())
                .applyDefaults(Theme.of(field.context).inputDecorationTheme);

            final value = field.value ?? <XFile>[];

            return InputDecorator(
              decoration: effectiveDecoration.copyWith(
                errorText: field.hasError ? field.errorText : null,
                isCollapsed: true,
                border: InputBorder.none,
              ),
              child: GridView.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  final bool showEmptyBuilder =
                      (emptyBuilder != null && index >= value.length);

                  void onChangedHandler(List<XFile> value) {
                    field.didChange(value);
                    if (onChanged != null) {
                      onChanged(value);
                    }
                  }

                  return GestureDetector(
                    child: showEmptyBuilder
                        ? emptyBuilder(context)
                        : itemBuilder(context, value[index], index),
                    onTap: () {
                      showModalBottomSheet(
                        context: field.context,
                        builder: (BuildContext context) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!showEmptyBuilder &&
                                  field.value != null &&
                                  field.value?[index] != null) ...[
                                if (options.contains(ClipOption.zoom))
                                  ListTile(
                                    leading: Icon(Icons.zoom_out_map_outlined),
                                    title: Text(
                                        ClipLocalizations.of(context)!.zoom),
                                    onTap: () async {
                                      final items = <Uint8List>[];

                                      await Future.forEach<XFile>(value,
                                          (value) async {
                                        items.add(await value.readAsBytes());
                                      });

                                      Navigator.of(context)
                                        ..pop()
                                        ..push(
                                          MaterialPageRoute(
                                              builder: (_) => GalleryPage(
                                                    attachments: value
                                                        .map((xfile) =>
                                                            File(xfile.path))
                                                        .toList(),
                                                    initialIndex: index,
                                                  )),
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
                                      onChangedHandler(
                                        value..removeAt(index),
                                      );
                                      Navigator.of(context).pop();
                                    },
                                  ),
                              ] else
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

                                          (source == ImageSource.camera
                                                  ? _imagePicker.pickImage(
                                                      source: source,
                                                      imageQuality: quality,
                                                      maxHeight:
                                                          maxHeight?.toDouble(),
                                                      maxWidth:
                                                          maxWidth?.toDouble(),
                                                    )
                                                  : _imagePicker.pickMultiImage(
                                                      imageQuality: quality,
                                                      maxHeight:
                                                          maxHeight?.toDouble(),
                                                      maxWidth:
                                                          maxWidth?.toDouble(),
                                                    ))
                                              .then<List<XFile>?>((value) =>
                                                  value is List<XFile>
                                                      ? value
                                                      : [value as XFile])
                                              .then((pickedFiles) async {
                                                final items = pickedFiles;

                                                return <XFile>[
                                                  if (field.value != null)
                                                    ...value,
                                                  ...items!,
                                                ];
                                              })
                                              .then(onChangedHandler)
                                              .whenComplete(field.onResume);
                                        },
                                      ),
                                    )
                                    .toList(),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                itemCount: value.length + (emptyBuilder != null ? 1 : 0),
                scrollDirection: scrollDirection,
                reverse: reverse,
                controller: scrollController,
                primary: primary,
                physics: physics,
                shrinkWrap: shrinkWrap,
                padding: padding,
                cacheExtent: cacheExtent,
                dragStartBehavior: dragStartBehavior,
                keyboardDismissBehavior: keyboardDismissBehavior,
                restorationId: restorationId,
                clipBehavior: clipBehavior,
              ),
            );
          },
        );
}
