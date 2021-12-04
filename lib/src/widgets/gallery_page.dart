import 'dart:io';

import 'package:clip/l10n/clip_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class GalleryPage extends StatefulWidget {
  final int initialIndex;
  final List attachments;

  const GalleryPage({
    Key? key,
    required this.attachments,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late int _currentIndex = widget.initialIndex;
  late final PageController _pageController =
      PageController(initialPage: _currentIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const CloseButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: widget.attachments.length > 1
            ? Text(
                '${_currentIndex + 1} ${ClipLocalizations.of(context)!.ofMany.toLowerCase()} ${widget.attachments.length}')
            : null,
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ],
          )),
        ),
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final attachment = widget.attachments[index];

              return PhotoViewGalleryPageOptions(
                imageProvider: (attachment is File
                    ? FileImage(attachment)
                    : NetworkImage(attachment)) as ImageProvider,
                initialScale: PhotoViewComputedScale.contained,
                heroAttributes: PhotoViewHeroAttributes(tag: index),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.attachments.length,
            loadingBuilder: (context, event) => Center(
              child: Container(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
