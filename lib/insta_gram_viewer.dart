
import 'dart:convert';
import 'dart:ui';

import 'package:easy_zoom_widget/easy_zoom_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';



class InstagramViewer extends StatefulWidget {
  final List<AssetEntity> assets;
  final int initialIndex;
  final Map<String, dynamic> db;
  final VoidCallback onUpdate;
  VoidCallback onRefresh;

  InstagramViewer({
    required this.assets,
    required this.initialIndex,
    required this.db,
    required this.onUpdate,
    required this.onRefresh,
  });

  @override
  _InstagramViewerState createState() => _InstagramViewerState();
}

class _InstagramViewerState extends State<InstagramViewer> {
  late PageController _controller;
  late List<AssetEntity> _viewList;

  @override
  void initState() {
    super.initState();
    _viewList = List.from(widget.assets);
    _controller = PageController(initialPage: widget.initialIndex);
  }

  void _deleteMedia(AssetEntity asset) async {
    final List<String> result = await PhotoManager.editor.deleteWithIds([
      asset.id,
    ]);

    if (result.isNotEmpty) {
      setState(() => _viewList.remove(asset));
      widget.db.remove(asset.id);
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Media removed from gallery"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        widget.onUpdate();
      }

      widget.onUpdate(); // Triggers refetch in main gallery

      if (_viewList.isEmpty) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result){
        if (didPop) {
          widget.onRefresh();
        }
      },
      child: Scaffold(
        // appBar:AppBar(
        //   backgroundColor: Colors.black,
        //   leading:
        //   IconButton(
        //     icon: const Icon(
        //       Icons.arrow_back_ios_new_rounded,
        //       color: Colors.white,
        //       size: 22,
        //     ),
        //     onPressed: () => Navigator.pop(context),
        //   ),
        // ) ,
        backgroundColor: Colors.black,
        body: SafeArea(
          child: PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _controller,
            itemCount: _viewList.length,
            itemBuilder: (context, index) {
              final asset = _viewList[index];
              widget.db[asset.id] ??= {'comment': '', 'isFavorite': false};
              final meta = widget.db[asset.id];

              return Stack(
                fit: StackFit.expand,
                children: [


                  // Container(
                  //   height: double.infinity,
                  //   width: double.infinity,
                  //   // minScale: 1.0,
                  //   // maxScale: 5.0,
                  //   child: EasyZoomWidget(
                  //     minScale: 1.0,
                  //     maxScale: 5.0,
                  //     child:Center(
                  //       child: asset.type == AssetType.video
                  //           ? InstagramVideoPlayer(asset: asset)
                  //           :
                  //       Image(
                  //         // Use AssetEntityImageProvider for full-quality rendering
                  //         image: AssetEntityImageProvider(
                  //           asset,
                  //           isOriginal: true,
                  //         ),
                  //         fit: BoxFit.contain,
                  //       ),),
                  //   ),
                  // ),

                  // PINCH TO ZOOM + MEDIA
                  EasyZoomWidget(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Center(
                      child: asset.type == AssetType.video
                          ? InstagramVideoPlayer(asset: asset)
                          :
                      Image(
                        // Use AssetEntityImageProvider for full-quality rendering
                        image: AssetEntityImageProvider(
                          asset,
                          isOriginal: true,
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // REELS STYLE SIDEBAR
                  Positioned(
                    right: 16,
                    bottom: MediaQuery.of(context).size.height * 0.12,
                    child: Column(
                      children: [
                        _reelsAction(
                          icon: meta['isFavorite']
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: meta['isFavorite'] ? Colors.red : Colors.white,
                          boxColor: meta['isFavorite']
                              ? Colors.red.shade100
                              : Colors.white10,
                          onTap: () {
                            setState(
                                  () => meta['isFavorite'] = !meta['isFavorite'],
                            );
                            HapticFeedback.heavyImpact();
                            widget.onUpdate();
                            print(jsonEncode(widget.db));
                          },
                        ),
                        _reelsAction(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            _showCommentSheet(meta);
                            print(jsonEncode(widget.db));
                          },
                        ),
                        _reelsAction(
                          icon: Icons.share_rounded,
                          onTap: () async {
                            HapticFeedback.heavyImpact();
                            final file = await asset.file;
                            if (file != null)
                              Share.shareXFiles([XFile(file.path)]);
                          },
                        ),
                        _reelsAction(
                          icon: Icons.shuffle_rounded,
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            setState(() {
                              _viewList.shuffle();
                              _controller.jumpToPage(0);
                            });
                          },
                        ),
                        _reelsAction(
                          icon: Icons.info_outline_rounded,
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            _showProperties(asset);
                          },
                        ),
                        _reelsAction(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.black87,
                          boxColor: Colors.redAccent.shade200,
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            _deleteMedia(asset);
                          },
                        ),
                      ],
                    ),
                  ),

                  // ANIMATED STORY NOTE
                  if ((meta['comment'] ?? "").toString().isNotEmpty)
                    Positioned(
                      bottom: 30,
                      left: 16,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: Colors.white10,
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: Text(
                                meta['comment'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // BACK BUTTON
                  Positioned(
                    top: 20,
                    left: 12,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        // Call onUpdate before popping
                        widget.onRefresh();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _reelsAction({
    required IconData icon,
    Color color = Colors.white,
    Color boxColor = Colors.white10,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              icon,
              color: color,
              size: 28,
              shadows: const [Shadow(blurRadius: 8, color: Colors.black45)],
            ),
          ),
        ),
      ),
    );
  }

  void _showCommentSheet(Map<String, dynamic> meta) {
    TextEditingController c = TextEditingController(text: meta['comment']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Memory Note",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: c,
              autofocus: true,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "What was happening here?",
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  setState(() => meta['comment'] = c.text);
                  widget.onUpdate();
                  Navigator.pop(ctx);
                },
                child: const Text("Save Note"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showProperties(AssetEntity asset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _propRow("Type", asset.type == AssetType.video ? "Video" : "Photo"),
            _propRow("Dimensions", "${asset.width} x ${asset.height}"),
            _propRow("Date", DateFormat('yMMMMd').format(asset.createDateTime)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _propRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: Colors.white54)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}




class InstagramVideoPlayer extends StatefulWidget {
  final AssetEntity asset;

  const InstagramVideoPlayer({Key? key, required this.asset}) : super(key: key);

  @override
  _InstagramVideoPlayerState createState() => _InstagramVideoPlayerState();
}

class _InstagramVideoPlayerState extends State<InstagramVideoPlayer> {
  late VideoPlayerController _vc;
  bool _init = false;
  bool _isPlaying = true;
  bool _isMuted = false;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _setupVideo();
  }

  Future<void> _setupVideo() async {
    final file = await widget.asset.file;
    if (file == null) return;

    _vc = VideoPlayerController.file(file);
    await _vc.initialize();
    _vc.setLooping(true);
    _vc.play();
    _vc.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() => _init = true);
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      // _showControls = !_showControls;
      _isPlaying ? _vc.play() : _vc.pause();
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _vc.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_init) return const Center(child: CircularProgressIndicator());

    return GestureDetector(
      // Tap to show/hide controls
      //onTap: () => setState(() => _showControls = !_showControls),

      // Hold to Pause, Release to Play
      onTapDown: (_) {
        _vc.pause();
        // setState(() => _showControls = true);
      },
      onTapUp: (_) {
        _vc.play();
        // setState(() => _showControls = false);
      },
      onTapCancel: () => _vc.play(),

      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _vc.value.aspectRatio,
            child: VideoPlayer(_vc),
          ),

          // Controls Overlay
          if (_showControls)
            Container(
              height: 100,
              width: 50,
              color: Colors.black26,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  const SizedBox(height: 10),
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: _toggleMute,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _vc.dispose();
    super.dispose();
  }
}


