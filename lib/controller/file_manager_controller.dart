import 'dart:io';

import 'package:flutter/material.dart';

class FileManagerController extends ChangeNotifier {
  String _path = "";
  int _currentStorage = 0;

  /// Get current directory path.
  Directory get getCurrentDirectory => Directory(_path);
  String get getCurrentPath {
    return _path;
  }

  /// Set current directory path by providing string of path.
  set setCurrentPath(String path) {
    _path = path;
    notifyListeners();
  }

  /// Open directory by providing Directory.
  void openDirectory(FileSystemEntity entity) {
    if (entity is Directory) {
      _path = entity.path;
      notifyListeners();
    } else {
      print(
          "FileSystemEntity entity is File. Please provide a Directory(folder) to be opened not File");
    }
  }

  /// Get current storege. ie: 0 is for internal storage. 1, 2 and so on, if any external storage is available.
  int get getCurrentStorage => _currentStorage;

  /// Set current storege. ie: 0 is for internal storage. 1, 2 and so on, if any external storage is available.
  set setCurrentStorage(int index) {
    _currentStorage = index;
    notifyListeners();
  }

  bool handleWillPopScope() {
    return false;
  }
}