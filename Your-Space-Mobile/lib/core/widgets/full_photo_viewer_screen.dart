import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';

import '../router/args/full_photo_viewer_args.dart';

class FullPhotoViewerScreen extends StatelessWidget {
  final FullPhotoViewerArgs args;

  const FullPhotoViewerScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: args.heroTag,
              child: PhotoView(
                imageProvider: CachedNetworkImageProvider(args.photoUrl),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                loadingBuilder: (context, event) =>
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
          ),
          PositionedDirectional(
            top: 8.h,
            end: 8.w,
            child: SafeArea(
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
