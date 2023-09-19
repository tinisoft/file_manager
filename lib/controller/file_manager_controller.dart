import 'dart:io';
import 'package:driven/driven.dart';
import 'package:driven/querybuilder/driveExtensions.dart';
import 'package:file_manager/file_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:global_configs/global_configs.dart';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:kirukkal/widgets/partials/notebooktools.dart';

enum Status {
  busy,
  done,
}

class FileManagerController {
  static final ValueNotifier<List<String>> currentPath =
      ValueNotifier<List<String>>(['kirukkal']);

  final ValueNotifier<String> activeFolder = ValueNotifier<String>('kirukkal');

  final ValueNotifier<Status> status = ValueNotifier<Status>(Status.done);

  final ValueNotifier<Future<List<drive.File>>?> files =
      ValueNotifier<Future<List<drive.File>>?>(null);

  Future<List<drive.File>>? currentDir;

  static var _driven = Driven(iAcceptTheRisksOfUsingDriven: true);
  static var clientId = GlobalConfigs().get('clientIdForDesktop');

  String titleMessage = "";

  _updatePath(String path) {
    activeFolder.value = path;

    if ((currentPath.value.any((element) => element == path))) {
      currentPath.value =
          currentPath.value.sublist(0, currentPath.value.indexOf(path) + 1);
      return;
    }
    currentPath.value.add(activeFolder.value);
  }

  void backFromPath() {
    currentPath.value.remove(currentPath.value.last);
  }

  /// ValueNotifier of the current directory's basename
  ///
  /// ie:
  /// ```dart
  // / ValueListenableBuilder<String>(
  // /    valueListenable: controller.titleNotifier,
  // /    builder: (context, title, _) {
  // /     return Text(title);
  // /   },
  /// ),
  /// ```

  /// Get ValueNotifier of path
  ValueNotifier<String> get getActiveFolder => activeFolder;

  ValueNotifier<List<String>> get getCurrentPath => currentPath;

  ValueNotifier<Status> get getStatus => status;

  // /// Get current Directory.
  // Directory get getCurrentDirectory => Directory(_path.value);

  // /// Get current path, similar to [getCurrentDirectory].
  // String get getCurrentPath => currentFolder.value;

  bool get isRootDirectory => activeFolder.value == 'kirukkal';

  /// Set current directory path by providing string of path, similar to [openDirectory].
  set setCurrentPath(String path) {
    _updatePath(path);
  }

  set setFolderIds(List<String> _folderids) => currentPath.value = _folderids;

  set setStatus(Status _status) => status.value = _status;

  /// Jumps to the parent directory of currently opened directory if the parent is accessible.
  Future<void> goToParentDirectory() async {
    currentPath.value.removeLast();
    _updatePath(currentPath.value.last);
    updateFiles(activeFolder.value);
  }

  /// Open directory by providing [Directory].
  void openDirectory(drive.File entity) {
    if (FileManager.isDirectory(entity)) {
      _updatePath(entity.name!);
      updateFiles(activeFolder.value);
    } else {
      throw ("FileSystemEntity entity is File. Please provide a Directory(folder) to be opened not File");
    }
  }

  void openDirectoryFromBreadcrum(String folderName) {
    _updatePath(folderName);
    updateFiles(activeFolder.value);
  }

  Future<List<drive.File>> updateFiles(String folder) async {
    setStatus = Status.busy;

    files.value = Future.value(await getAllFiles(folder));

    setStatus = Status.done;

    return [];
  }

  static Future<List<drive.File>> getAllFiles(String folderName) async {
    await _driven.authenticateWithGoogle(Platform.isLinux ? clientId : null);
    try {
      final remoteFolderIds = await drive.DriveApi(GoogleAuthClient())
          .getFolderPathAsIds(folderName);

      drive.FileList remoteFileList = await driveApi.files.list(
        q: "'${remoteFolderIds.last.id!}' in parents ",
        $fields:
            "files(id, name, modifiedTime, createdTime, parents, mimeType, webContentLink ,webViewLink)",
      );

      List<drive.File>? remoteFiles =
          remoteFileList.files!.cast<drive.File>().toList();

      // var content = await driveApi.files.get(remoteFiles.last.id!,
      //     downloadOptions: drive.DownloadOptions.fullMedia);

      // var examole = await driveApi.files.get(remoteFiles.last.id!,
      //     downloadOptions: drive.DownloadOptions.fullMedia);

      // drive.Media? export = await driveApi.files.export(
      //     remoteFiles.last.id!, "application/zip	",
      //     downloadOptions: drive.DownloadOptions.fullMedia);

      // debugPrint(
      //     "web link  ((((((((((())))))))))) ===================>   ${content.runtimeType}");

      debugPrint(
          "web link  ((((((((((())))))))))) ===================>   ${remoteFiles.last.webViewLink!}");

      // debugPrint(
      //     "web link  ((((((((((())))))))))) ===================>   ${remoteFiles.first.webContentLink!}");

      // final response =
      //     await http.get(Uri.parse(remoteFiles.first.webContentLink!));

      // final directory = await getApplicationDocumentsDirectory();

      // final filePath = '${directory!.path}/${remoteFiles.first.name}';

      // Save the file to external storage
      //File(filePath).writeAsBytesSync(response.bodyBytes);

      //remoteFiles.last.webContentLink!;

      return remoteFiles;

      // Process the remoteFileList here
    } catch (error, stackTrace) {
      print("Error: $error");
      print("Stack Trace: $stackTrace");
    }
    return [];
  }

  /// Dispose FileManagerController
  void dispose() {
    currentPath.dispose();
    activeFolder.dispose();
  }
}
