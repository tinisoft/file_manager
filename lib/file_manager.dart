library file_manager;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_manager/helper/helper.dart';
export 'package:file_manager/helper/helper.dart';

import 'package:googleapis/drive/v3.dart' as drive;

const _methodChannel = MethodChannel('myapp/channel');

typedef _Builder = Widget Function(
  BuildContext context,
  List<drive.File> snapshot,
);

typedef _ErrorBuilder = Widget Function(
  BuildContext context,
  Object? error,
);

/// FileManager is a wonderful widget that allows you to manage files and folders, pick files and folders, and do a lot more.
/// Designed to feel like part of the Flutter framework.
///
/// Sample code
///```dart
///FileManager(
///    controller: controller,
///    builder: (context, snapshot) {
///    final List<FileSystemEntity> entitis = snapshot;
///      return ListView.builder(
///        itemCount: entitis.length,
///        itemBuilder: (context, index) {
///          return Card(
///            child: ListTile(
///              leading: FileManager.isFile(entitis[index])
///                  ? Icon(Icons.feed_outlined)
///                  : Icon(Icons.folder),
///              title: Text(FileManager.basename(entitis[index])),
///              onTap: () {
///                if (FileManager.isDirectory(entitis[index])) {
///                    controller
///                     .openDirectory(entitis[index]);
///                  } else {
///                      // Perform file-related tasks.
///                  }
///              },
///            ),
///          );
///        },
///      );
///  },
///),
///```
class FileManager extends StatefulWidget {
  /// For the loading screen, create a custom widget.
  /// Simple Centered CircularProgressIndicator is provided by default.
  final Widget? loadingScreen;

  /// For an empty screen, create a custom widget.
  final Widget? emptyFolder;

  /// For an error screen, create a custom widget.
  final _ErrorBuilder? errorBuilder;

  ///Controls the state of the FileManager.
  final FileManagerController controller;

  ///This function allows you to create custom widgets and retrieve a list of entities `List<FileSystemEntity>.`
  ///
  ///
  ///```
  /// builder: (context, snapshot) {
  ///               return ListView.builder(
  ///                 itemCount: snapshot.length,
  ///                 itemBuilder: (context, index) {
  ///                   return Card(
  ///                     child: ListTile(
  ///                       leading: FileManager.isFile(snapshot[index])
  ///                           ? Icon(Icons.feed_outlined)
  ///                           : Icon(Icons.folder),
  ///                       title: Text(FileManager.basename(snapshot[index])),
  ///                       onTap: () {
  ///                         if (FileManager.isDirectory(snapshot[index]))
  ///                           controller.openDirectory(snapshot[index]);
  ///                       },
  ///                     ),
  ///                   );
  ///                 },
  ///               );
  ///             },
  /// ```
  final _Builder builder;

  /// Hide the files and folders that are hidden.
  final bool hideHiddenEntity;

  FileManager({
    this.emptyFolder,
    this.loadingScreen,
    this.errorBuilder,
    required this.controller,
    required this.builder,
    this.hideHiddenEntity = true,
  });

  @override
  _FileManagerState createState() => _FileManagerState();

  static Future<void> requestFilesAccessPermission() async {
    if (Platform.isAndroid) {
      try {
        await _methodChannel.invokeMethod('requestFilesAccessPermission');
      } on PlatformException catch (e) {
        throw e;
      }
    } else {
      throw UnsupportedError('Only Android is supported');
    }
  }

  /// check weather FileSystemEntity is File
  /// return true if FileSystemEntity is File else returns false
  static bool isDirectory(drive.File driveFile) {
    return driveFile.mimeType! == 'application/vnd.google-apps.folder';
  }

// check weather FileSystemEntity is Directory
  /// return true if FileSystemEntity is a Directory else returns Directory
  static bool isFile(drive.File driveFile) {
    //driveFile.
    return driveFile.mimeType! != 'application/vnd.google-apps.folder';
  }

  static Status status = Status.done;

  static setBusy() {
    status = Status.busy;
  }

  static setDone() {
    status = Status.busy;
  }

  /// Return file extension as String.
  ///
  /// ie:- `File("/../image.png")` to `"png"`
  // static String getFileExtension(FileSystemEntity file) {
  //   // if (file is File) {
  //   //   return file.path.split("/").last.split('.').last;
  //   // } else {
  //   //   throw "FileSystemEntity is Directory, not a File";
  //   // }
  // }

  /// Get list of available storage in the device
  /// returns an empty list if there is no storage
}

class _FileManagerState extends State<FileManager> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    widget.controller.updateFiles(widget.controller.activeFolder.value);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.controller.getActiveFolder,
      builder: (context, activedir, _) {
        return ValueListenableBuilder<Future<List<drive.File>>?>(
          valueListenable: widget.controller.files,
          builder: (context, files, _) {
            return FutureBuilder<List<drive.File>?>(
              future: files,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return widget.builder(context, snapshot.data!);
                } else if (snapshot.hasError) {
                  print(snapshot.error);
                  return _errorPage(context, snapshot.error);
                } else {
                  return _loadingScreenWidget();
                }
              },
            );
          },
        );
      },
    );
  }

  // Widget _body(BuildContext context, List<drive.File> files) {
  //   return widget.builder(context, files);
  // }

  Widget _emptyFolderWidget() {
    if (widget.emptyFolder == null) {
      return Container(
        child: Center(child: Text("Empty Directory")),
      );
    } else
      return widget.emptyFolder!;
  }

  Widget _errorPage(BuildContext context, Object? error) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error);
    }
    return Container(
      color: Colors.red,
      child: Center(
        child: Text("Error: $error"),
      ),
    );
  }

  Widget _loadingScreenWidget() {
    if ((widget.loadingScreen == null)) {
      return Container(
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.greenAccent,
          ),
        ),
      );
    } else {
      return Container(
        child: Center(
          child: widget.loadingScreen,
        ),
      );
    }
  }
}

/// When the current directory is not root, this widget registers a callback to prevent the user from dismissing the window
/// , or controllers the system's back button
///
/// #### Wrap Scaffold containing FileManage with `ControlBackButton`
/// ```dart
/// ControlBackButton(
///   controller: controller
///   child: Scaffold(
///     appBar: AppBar(...)
///     body: FileManager(
///       ...
///     )
///   )
/// )
/// ```
class ControlBackButton extends StatelessWidget {
  const ControlBackButton(
      {required this.child, required this.controller, Key? key})
      : super(key: key);

  final Widget child;
  final FileManagerController controller;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: child,
      onWillPop: () async {
        if (await controller.isRootDirectory) {
          return true;
        } else {
          // controller.goToParentDirectory();
          return false;
        }
      },
    );
  }
}
