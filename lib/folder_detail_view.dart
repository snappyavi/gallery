

import 'package:flutter/material.dart';
import 'package:gallery_by_osolution/home_page.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import 'insta_gram_viewer.dart';

class FolderDetailView extends StatefulWidget {
  final List<AssetEntity> assets;
  final String title;
  final Map<String, dynamic> db;
  final VoidCallback onUpdate;


  FolderDetailView({
    required this.assets,
    required this.title,
    required this.db,
    required this.onUpdate,

  });

  @override
  State<FolderDetailView> createState() => _FolderDetailViewState();
}

class _FolderDetailViewState extends State<FolderDetailView> {
  late List<AssetEntity> _assets;

  @override
  void initState() {
    super.initState();
    _assets = List.from(widget.assets);
  }

  Future<void> _refresh() async {
    final refreshed = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    final folder = refreshed.firstWhere(
          (p) => p.name == widget.title,
    );

    final newAssets = await folder.getAssetListRange(
      start: 0,
      end: 1000,
    );

    setState(() {
      _assets = newAssets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: _assets.length,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => InstagramViewer(
                    assets: _assets,
                    initialIndex: i,
                    db: widget.db,
                    onUpdate: widget.onUpdate,
                    onRefresh: _refresh,
                    //  onRefresh: widget.onRefresh,
                  ),
                ),

              ),
              child: AssetEntityImage(
                _assets[i],
                isOriginal: false,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}