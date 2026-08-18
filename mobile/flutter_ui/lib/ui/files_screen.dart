import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/file_transfer_service.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({Key? key}) : super(key: key);

  Future<void> _pickAndSend(BuildContext context) async {
    final service = context.read<FileTransferService>();

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null || path.isEmpty) {
        _showError(context, 'The selected file could not be accessed.');
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        _showError(context, 'The selected file no longer exists.');
        return;
      }

      await service.sendFile(path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sending ${result.files.single.name}...'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Could not select file: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
      ),
      body: Consumer<FileTransferService>(
        builder: (context, service, _) {
          final transfers = service.transfers.values.toList()
            ..sort((a, b) => b.transferId.compareTo(a.transferId));

          if (transfers.isEmpty) {
            return _EmptyFiles(
              onSend: () => _pickAndSend(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: transfers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _TransferTile(transfer: transfers[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndSend(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Send file'),
      ),
    );
  }
}

class _EmptyFiles extends StatelessWidget {
  final VoidCallback onSend;

  const _EmptyFiles({required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No file transfers yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a file and send it to the connected desktop.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose a file'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  final FileTransfer transfer;

  const _TransferTile({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final isActive = transfer.state == TransferState.offering ||
        transfer.state == TransferState.sending ||
        transfer.state == TransferState.receiving;

    final progress = transfer.progress.clamp(0.0, 1.0);

    IconData icon;
    String status;

    switch (transfer.state) {
      case TransferState.offering:
        icon = Icons.schedule;
        status = 'Waiting for desktop...';
        break;
      case TransferState.sending:
        icon = Icons.upload;
        status = 'Sending ${(progress * 100).round()}%';
        break;
      case TransferState.receiving:
        icon = Icons.download;
        status = 'Receiving ${(progress * 100).round()}%';
        break;
      case TransferState.done:
        icon = Icons.check_circle_outline;
        status = 'Completed';
        break;
      case TransferState.error:
        icon = Icons.error_outline;
        status = transfer.errorMessage ?? 'Transfer failed';
        break;
      case TransferState.idle:
        icon = Icons.insert_drive_file_outlined;
        status = 'Idle';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _iconColor(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    transfer.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatBytes(transfer.bytesTransferred)} / '
              '${_formatBytes(transfer.totalBytes)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
            ],
            const SizedBox(height: 6),
            Text(
              status,
              style: TextStyle(
                color: transfer.state == TransferState.error
                    ? Colors.red.shade700
                    : Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _iconColor(BuildContext context) {
    switch (transfer.state) {
      case TransferState.done:
        return Colors.green.shade700;
      case TransferState.error:
        return Colors.red.shade700;
      case TransferState.sending:
      case TransferState.receiving:
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
