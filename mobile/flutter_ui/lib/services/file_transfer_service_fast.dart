import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../core/packet.dart';
import '../data/local_device.dart';
import 'connection_manager.dart';

const _chunkSize = 256 * 1024; // 256 KB per chunk

enum TransferState { idle, offering, receiving, sending, done, error }

class FileTransfer {
  final String transferId;
  final String fileName;
  final int totalBytes;
  int bytesTransferred;
  TransferState state;
  String? errorMessage;

  FileTransfer({
    required this.transferId,
    required this.fileName,
    required this.totalBytes,
    this.bytesTransferred = 0,
    this.state = TransferState.offering,
  });

  double get progress =>
      totalBytes > 0 ? bytesTransferred / totalBytes : 0.0;
}

class FileTransferService extends ChangeNotifier {
  final ConnectionManager _connection;
  final LocalDeviceConfigService _localConfig;

  final Map<String, FileTransfer> _transfers = {};
  // Store incoming file bytes while receiving.
  final Map<String, List<int>> _incomingBuffer = {};

  FileTransferService(this._connection, this._localConfig) {
    _connection.packets.listen(_onPacket);
  }

  Map<String, FileTransfer> get transfers => Map.unmodifiable(_transfers);

  /// Offer a file to the desktop. User picks it via a MethodChannel file picker.
  Future<void> sendFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    final name = file.uri.pathSegments.last;
    final totalBytes = await file.length();
    final transferId = DateTime.now().millisecondsSinceEpoch.toString();

    final transfer = FileTransfer(
      transferId: transferId,
      fileName: name,
      totalBytes: totalBytes,
      state: TransferState.offering,
    );
    _transfers[transferId] = transfer;
    notifyListeners();

    _connection.send(Packet(
      type: PacketType.fileOffer,
      from: _localConfig.config.deviceId,
      payload: {
        'transfer_id': transferId,
        'file_name': name,
        'total_bytes': totalBytes,
      },
    ));

    // Actual sending happens after we receive a file_accept
    _pendingSends[transferId] = filePath;
  }

  final Map<String, String> _pendingSends = {};

  void _onPacket(Packet packet) async {
    switch (packet.type) {
      case PacketType.fileOffer:
        _handleIncomingOffer(packet);

      case PacketType.fileAccept:
        _startSending(packet.payload['transfer_id'] as String? ?? '');

      case PacketType.fileReject:
        final id = packet.payload['transfer_id'] as String? ?? '';
        _transfers[id]?.state = TransferState.error;
        _transfers[id]?.errorMessage = 'Rejected by remote device';
        notifyListeners();

      case PacketType.fileChunk:
        _handleChunk(packet);

      case PacketType.fileDone:
        _handleFileDone(packet);
    }
  }

  void _handleIncomingOffer(Packet packet) {
    final id = packet.payload['transfer_id'] as String? ?? '';
    final name = packet.payload['file_name'] as String? ?? 'file';
    final totalBytes = packet.payload['total_bytes'] as int? ?? 0;

    _transfers[id] = FileTransfer(
      transferId: id,
      fileName: name,
      totalBytes: totalBytes,
      state: TransferState.receiving,
    );
    _incomingBuffer[id] = [];
    notifyListeners();

    // Auto-accept for now; could show a dialog instead
    _connection.send(Packet(
      type: PacketType.fileAccept,
      from: _localConfig.config.deviceId,
      payload: {'transfer_id': id},
    ));
  }

  Future<void> _startSending(String transferId) async {
    final filePath = _pendingSends[transferId];
    if (filePath == null) return;

    final transfer = _transfers[transferId];
    if (transfer == null) return;

    final file = File(filePath);
    if (!await file.exists()) {
      transfer.state = TransferState.error;
      transfer.errorMessage = 'File no longer exists';
      notifyListeners();
      _pendingSends.remove(transferId);
      return;
    }

    transfer.state = TransferState.sending;
    notifyListeners();

    final handle = await file.open(mode: FileMode.read);
    var offset = 0;
    var chunkIndex = 0;

    try {
      while (true) {
        final chunk = await handle.read(_chunkSize);
        if (chunk.isEmpty) break;

        // Base64 is much smaller than JSON's List<int> representation and
        // therefore dramatically reduces packet size and parsing overhead.
        final encoded = base64Encode(chunk);

        _connection.send(Packet(
          type: PacketType.fileChunk,
          from: _localConfig.config.deviceId,
          payload: {
            'transfer_id': transferId,
            'chunk_index': chunkIndex,
            'data': encoded,
          },
        ));

        offset += chunk.length;
        transfer.bytesTransferred = offset;
        notifyListeners();
        chunkIndex++;

        // No artificial delay: TCP provides buffering/backpressure.
        await Future<void>.delayed(Duration.zero);
      }

      _connection.send(Packet(
        type: PacketType.fileDone,
        from: _localConfig.config.deviceId,
        payload: {'transfer_id': transferId},
      ));
      transfer.state = TransferState.done;
    } catch (e) {
      transfer.state = TransferState.error;
      transfer.errorMessage = e.toString();
    } finally {
      await handle.close();
      _pendingSends.remove(transferId);
      notifyListeners();
    }
  }

  void _handleChunk(Packet packet) {
    final id = packet.payload['transfer_id'] as String? ?? '';
    final rawData = packet.payload['data'];
    final List<int> data;

    if (rawData is String) {
      data = base64Decode(rawData);
    } else if (rawData is List) {
      data = rawData.map((e) => (e as num).toInt()).toList();
    } else {
      data = const <int>[];
    }

    _incomingBuffer[id]?.addAll(data);
    _transfers[id]?.bytesTransferred =
        _incomingBuffer[id]?.length ?? 0;
    notifyListeners();
  }

  Future<void> _handleFileDone(Packet packet) async {
    final id = packet.payload['transfer_id'] as String? ?? '';
    final transfer = _transfers[id];
    if (transfer == null) return;

    final bytes = _incomingBuffer.remove(id);
    if (bytes != null) {
      try {
        final dir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/${transfer.fileName}');
        await file.writeAsBytes(bytes);
        debugPrint('File saved to ${file.path}');
      } catch (e) {
        transfer.errorMessage = e.toString();
        transfer.state = TransferState.error;
        notifyListeners();
        return;
      }
    }

    transfer.state = TransferState.done;
    notifyListeners();
  }
}
