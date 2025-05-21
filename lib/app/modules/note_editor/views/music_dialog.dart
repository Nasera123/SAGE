import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_controller.dart';
import '../../../data/models/music_model.dart';
import '../../../data/services/music_service.dart';

class MusicDialog extends StatelessWidget {
  final String? noteId;
  final String? bookId;
  
  const MusicDialog({
    Key? key,
    this.noteId,
    this.bookId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MusicController controller = Get.find<MusicController>();

    // Initialize the controller with the current note or book
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (noteId != null) {
        controller.loadMusicForNote(noteId!);
      } else if (bookId != null) {
        controller.loadMusicForBook(bookId!);
      }
      
      // Load all available music
      controller.loadMusic();
    });

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  noteId != null ? 'Note Background Music' : 
                  bookId != null ? 'Book Background Music' : 'Background Music',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Play/Stop button
                    Obx(() {
                      final musicService = Get.find<MusicService>();
                      return IconButton(
                        icon: Icon(
                          musicService.isPlaying.value 
                              ? Icons.stop_circle : Icons.play_circle,
                          color: musicService.isPlaying.value 
                              ? Colors.red : Colors.green,
                          size: 32,
                        ),
                        tooltip: musicService.isPlaying.value 
                            ? 'Stop Music' : 'Play Music',
                        onPressed: () => controller.toggleMusicPlayback(),
                      );
                    }),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            
            // Current selection
            Obx(() {
              if (controller.selectedMusic.value != null) {
                final music = controller.selectedMusic.value!;
                return Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Selection',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    music.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    music.artist,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Obx(() => Icon(
                                controller.isPreviewPlaying.value 
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              )),
                              onPressed: () => controller.previewMusic(music.url),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => controller.removeMusicFromCurrentItem(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No music selected',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
            }),
            
            const SizedBox(height: 8),
            
            // Music list
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Music',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Add playlist controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Play all as playlist (only for this page)',
                            child: IconButton(
                              icon: const Icon(Icons.playlist_play),
                              onPressed: () => controller.startPlaylist(),
                            ),
                          ),
                          Obx(() {
                            // Only show these when in playlist mode
                            if (Get.find<MusicService>().isPlaylistMode.value) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Previous song',
                                    icon: const Icon(Icons.skip_previous),
                                    onPressed: () => controller.previousSong(),
                                  ),
                                  IconButton(
                                    tooltip: 'Next song',
                                    icon: const Icon(Icons.skip_next),
                                    onPressed: () => controller.nextSong(),
                                  ),
                                  IconButton(
                                    tooltip: 'Stop playlist',
                                    icon: const Icon(Icons.stop),
                                    onPressed: () => controller.stopPlaylist(),
                                  ),
                                ],
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (controller.musicList.isEmpty) {
                        return const Center(
                          child: Text('No music available. Add some below.'),
                        );
                      }
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: controller.musicList.length,
                        itemBuilder: (context, index) {
                          final music = controller.musicList[index];
                          final isSelected = controller.selectedMusic.value?.id == music.id;
                          
                          return ListTile(
                            title: Text(music.title),
                            subtitle: Text(music.artist),
                            selected: isSelected,
                            tileColor: isSelected 
                              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                              : null,
                            leading: IconButton(
                              icon: Obx(() => Icon(
                                controller.isPreviewPlaying.value && 
                                controller.previewProgress.value > 0 
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              )),
                              onPressed: () => controller.previewMusic(music.url),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => controller.deleteMusic(music),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check_circle),
                                  onPressed: isSelected
                                    ? null
                                    : () => controller.setMusicForCurrentItem(music.id),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Add new music form
            ExpansionTile(
              title: const Text('Add New Music'),
              children: [
                SizedBox(
                  height: 250,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: controller.titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.artistController,
                            decoration: const InputDecoration(
                              labelText: 'Artist',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.urlController,
                            decoration: const InputDecoration(
                              labelText: 'URL (MP3 or YouTube link)',
                              border: OutlineInputBorder(),
                              helperText: 'Enter MP3 URL or YouTube link',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.youtube_searched_for),
                                  label: const Text('Process YouTube'),
                                  onPressed: () => controller.processYoutubeUrl(controller.urlController.text),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text('Browse Files'),
                                  onPressed: () => controller.pickAudioFile(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: controller.addNewMusic,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Add Music'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 