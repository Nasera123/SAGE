import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/trash_controller.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/book_model.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:convert';

class TrashView extends GetView<TrashController> {
  const TrashView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTrashItems,
            tooltip: 'Refresh',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Empty trash'),
                onTap: () => _showConfirmEmptyTrashDialog(context),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.trashedNotes.isEmpty && controller.trashedBooks.isEmpty) {
          return _buildEmptyState(context);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Items will be permanently deleted after 30 days',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              
              if (controller.trashedNotes.isNotEmpty) ...[
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...controller.trashedNotes.map((note) => _buildNoteItem(context, note)),
                const SizedBox(height: 24),
              ],
              
              if (controller.trashedBooks.isNotEmpty) ...[
                const Text(
                  'Books',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...controller.trashedBooks.map((book) => _buildBookItem(context, book)),
              ],
            ],
          ),
        );
      }),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Trash is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Items you delete will appear here',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // Ekstrak plain text dari Delta JSON
  String _extractPlainTextFromDelta(String deltaJson) {
    try {
      final List<dynamic> ops = (deltaJson.trim().startsWith('['))
        ? List<dynamic>.from(jsonDecode(deltaJson))
        : List<dynamic>.from(jsonDecode('[' + deltaJson + ']'));
      return ops.map((op) => op['insert']?.toString() ?? '').join('').replaceAll('\n', ' ').trim();
    } catch (e) {
      // Jika gagal parsing, tampilkan sebagian string saja
      return deltaJson.length > 50 ? deltaJson.substring(0, 50) + '...' : deltaJson;
    }
  }

  Widget _buildNoteItem(BuildContext context, Note note) {
    String content = _extractPlainTextFromDelta(note.content);
    if (content.length > 50) {
      content = content.substring(0, 50) + '...';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _restoreNoteWithFeedback(note.id),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.restore,
              label: 'Restore',
            ),
            SlidableAction(
              onPressed: (_) => _showConfirmDeleteDialog(
                context, 
                'note', 
                () => controller.permanentlyDeleteNote(note.id)
              ),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete_forever,
              label: 'Delete',
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Deleted on: ${_formatDate(note.deletedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.restore),
                onPressed: () => _restoreNoteWithFeedback(note.id),
                tooltip: 'Restore note',
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () => _showConfirmDeleteDialog(
                  context, 
                  'note', 
                  () => controller.permanentlyDeleteNote(note.id)
                ),
                tooltip: 'Delete permanently',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookItem(BuildContext context, Book book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _restoreBookWithFeedback(book.id),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.restore,
              label: 'Restore',
            ),
            SlidableAction(
              onPressed: (_) => _showConfirmDeleteDialog(
                context, 
                'book', 
                () => controller.permanentlyDeleteBook(book.id)
              ),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete_forever,
              label: 'Delete',
            ),
          ],
        ),
        child: ListTile(
          leading: book.coverUrl != null
            ? CircleAvatar(backgroundImage: NetworkImage(book.coverUrl!))
            : const CircleAvatar(child: Icon(LineIcons.book)),
          title: Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Deleted on: ${_formatDate(book.deletedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.restore),
                onPressed: () => _restoreBookWithFeedback(book.id),
                tooltip: 'Restore book',
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () => _showConfirmDeleteDialog(
                  context, 
                  'book', 
                  () => controller.permanentlyDeleteBook(book.id)
                ),
                tooltip: 'Delete permanently',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM d, yyyy').format(date);
  }

  void _showConfirmDeleteDialog(BuildContext context, String itemType, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $itemType permanently?'),
        content: Text(
          'This $itemType will be permanently deleted and cannot be recovered. Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showConfirmEmptyTrashDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty trash?'),
        content: const Text(
          'All items in the trash will be permanently deleted and cannot be recovered. Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.emptyTrash();
            },
            child: const Text('Empty trash', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _restoreNoteWithFeedback(String noteId) {
    controller.restoreNote(noteId);
    Get.snackbar(
      'Restoring note', 
      'Note has been restored. If it was part of a book, it will be added back to that book.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
  
  void _restoreBookWithFeedback(String bookId) {
    controller.restoreBook(bookId);
    Get.snackbar(
      'Restoring book', 
      'Book has been restored and should appear in your books list',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
} 