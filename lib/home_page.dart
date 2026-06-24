import 'package:easy_zoom_widget/easy_zoom_widget.dart';
import 'package:flutter/material.dart';
import 'package:gallery_by_osolution/splash_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'folder_detail_view.dart';
import 'insta_gram_viewer.dart';

class MainGalleryApp extends StatefulWidget {
  @override
  _MainGalleryAppState createState() => _MainGalleryAppState();
}

class _MainGalleryAppState extends State<MainGalleryApp> {
  int _currentIndex = 0;
  List<AssetEntity> _allMedia = [];
  List<AssetPathEntity> _folders = [];
  Map<DateTime, List<AssetEntity>> _groupedMedia = {};
  Map<String, dynamic> _localDb = {};
  bool _isDescending = true;
  bool _sortBySize = false;
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// Refetches gallery and loads local metadata
  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('gallery_meta');
    if (saved != null) {
      _localDb = jsonDecode(saved) as Map<String, dynamic>;
    }

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      _folders = await PhotoManager.getAssetPathList(type: RequestType.common);
      final recentAlbum = await PhotoManager.getAssetPathList(onlyAll: true);
      _allMedia = await recentAlbum[0].getAssetListRange(start: 0, end: 5000);
      _processPhotos();
    }
  }

  void _processPhotos() {
    List<AssetEntity> workingList = List.from(_allMedia);

    if (_activeFilter == 'liked') {
      workingList = workingList
          .where((a) => _localDb[a.id]?['isFavorite'] == true)
          .toList();
    } else if (_activeFilter == 'commented') {
      workingList = workingList
          .where(
            (a) =>
                (_localDb[a.id]?['comment'] ?? "").toString().trim().isNotEmpty,
          )
          .toList();
    }

    if (_sortBySize) {
      workingList.sort((a, b) => b.width.compareTo(a.width));
    } else {
      workingList.sort(
        (a, b) => _isDescending
            ? b.createDateTime.compareTo(a.createDateTime)
            : a.createDateTime.compareTo(b.createDateTime),
      );
    }

    _groupedMedia.clear();
    for (var asset in workingList) {
      final date = DateTime(
        asset.createDateTime.year,
        asset.createDateTime.month,
        asset.createDateTime.day,
      );
      _groupedMedia.putIfAbsent(date, () => []).add(asset);
    }
    setState(() {});
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gallery_meta', jsonEncode(_localDb));
  }

  Future<void> _refreshGallery() async {
    HapticFeedback.lightImpact();
    await _initApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshGallery,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.black.withOpacity(0.5),
                  title: Text(
                    _currentIndex == 0 ? "Photos" : "Albums",
                    style: const TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 24,
                    ),
                  ),
                  actions: [
                    if (_currentIndex == 0)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.sort_rounded),
                        onSelected: (val) {
                          HapticFeedback.heavyImpact();
                          setState(() {
                            if (val == 'date') {
                              _sortBySize = false;
                              _isDescending = false;
                            } else if (val == 'latest') {
                              _sortBySize = false;
                              _isDescending = true;
                            } else {
                              _sortBySize = true;
                            }
                            _processPhotos();
                          });
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'date',
                            child: Text("By Date"),
                          ),
                          const PopupMenuItem(
                            value: 'latest',
                            child: Text("By Latest"),
                          ),
                          const PopupMenuItem(
                            value: 'size',
                            child: Text("By Size"),
                          ),
                        ],
                      ),
                  ],
                ),
                _currentIndex == 0
                    ? _buildPhotosSliver()
                    : _buildFoldersSliver(),
              ],
            ),
          ),
          if (_currentIndex == 0) _buildTopFilterPill(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.black,
          onDestinationSelected: (index) => setState(() {
            HapticFeedback.heavyImpact();
            _currentIndex = index;
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.photo_library_outlined),
              selectedIcon: Icon(Icons.photo_library),
              label: "Photos",
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_copy_outlined),
              selectedIcon: Icon(Icons.folder_copy),
              label: "Folders",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopFilterPill() {
    return Positioned(
      top: 110,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              color: Colors.white10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pillTab("All", 'all'),
                  _pillTab("Love", 'liked'),
                  _pillTab("Memory", 'commented'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillTab(String label, String key) {
    bool active = _activeFilter == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        setState(() {
          _activeFilter = key;
          _processPhotos();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.black : Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosSliver() {
    final dates = _groupedMedia.keys.toList();
    return
    // RefreshIndicator(
    //     onRefresh: _refreshGallery,
    //     child:
    SliverPadding(
      padding: const EdgeInsets.only(top: 60),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final date = dates[index];
          final photos = _groupedMedia[date]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text(
                  DateFormat('MMMM d, y').format(date).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: photos.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () async {
                    final filteredList = workingFilteredList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => InstagramViewer(
                          assets: filteredList,
                          initialIndex: filteredList.indexOf(photos[i]),
                          db: _localDb,
                          onUpdate: () async {
                            await _saveData(); // Save first
                          },
                          onRefresh: () async {
                            await _refreshGallery(); // Save first
                          },
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AssetEntityImage(
                        photos[i],
                        isOriginal: false,
                        fit: BoxFit.cover,
                      ),
                      if (photos[i].type == AssetType.video)
                        const Positioned(
                          right: 4,
                          top: 4,
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }, childCount: dates.length),
      ),
      //),
    );
  }

  List<AssetEntity> workingFilteredList() {
    List<AssetEntity> workingList = List.from(_allMedia);

    if (_activeFilter == 'liked' ||
        _activeFilter == 'commented' && _activeFilter == 'liked') {
      workingList = workingList
          .where((a) => _localDb[a.id]?['isFavorite'] == true)
          .toList();
    }

    if (_activeFilter == 'commented' ||
        _activeFilter == 'commented' && _activeFilter == 'liked') {
      workingList = workingList
          .where(
            (a) =>
                (_localDb[a.id]?['comment'] ?? "").toString().trim().isNotEmpty,
          )
          .toList();
    }

    if (_sortBySize) {
      workingList.sort((a, b) => b.width.compareTo(a.width));
    } else {
      workingList.sort(
        (a, b) => _isDescending
            ? b.createDateTime.compareTo(a.createDateTime)
            : a.createDateTime.compareTo(b.createDateTime),
      );
    }

    return workingList;
  }

  // List<AssetEntity> workingFilteredList() {
  //   if (_activeFilter == 'liked') return _allMedia.where((a) => _localDb[a.id]?['isFavorite'] == true).toList();
  //   if (_activeFilter == 'commented') return _allMedia.where((a) => (_localDb[a.id]?['comment'] ?? "").toString().isNotEmpty).toList();
  //   return _allMedia;
  // }

  Widget _buildFoldersSliver() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => GestureDetector(
            onTap: () async {
              final folderAssets = await _folders[index].getAssetListRange(
                start: 0,
                end: 1000,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => FolderDetailView(
                    assets: folderAssets,
                    title: _folders[index].name,
                    db: _localDb,
                    onUpdate: () async {
                      await _saveData();
                      await _initApp();
                    },

                  ),
                ),
              );

              final refreshedFolderAssets = await PhotoManager.getAssetPathList(
                type: RequestType.common,
              );

              // reload current folder here
              setState(() {});
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FutureBuilder<List<AssetEntity>>(
                      future: _folders[index].getAssetListRange(
                        start: 0,
                        end: 1,
                      ),
                      builder: (context, snap) =>
                          snap.hasData && snap.data!.isNotEmpty
                          ? AssetEntityImage(
                              snap.data![0],
                              isOriginal: false,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.folder_rounded),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _folders[index].name,
                  maxLines: 1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          childCount: _folders.length,
        ),
      ),
    );
  }
}
