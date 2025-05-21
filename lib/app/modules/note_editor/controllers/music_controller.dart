import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/models/music_model.dart';
import '../../../data/repositories/music_repository.dart';
import '../../../data/services/music_service.dart';
import '../../../data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class MusicController extends GetxController {
  final MusicRepository _musicRepository = Get.find<MusicRepository>();
  final MusicService _musicService = Get.find<MusicService>();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  
  final isLoading = false.obs;
  final RxList<Music> musicList = <Music>[].obs;
  final selectedMusic = Rxn<Music>();
  
  // Fields for adding new music
  final titleController = TextEditingController();
  final artistController = TextEditingController();
  final urlController = TextEditingController();
  
  // Fields for the current note or book
  String? currentNoteId;
  String? currentBookId;
  
  // For audio preview
  final AudioPlayer previewPlayer = AudioPlayer();
  final isPreviewPlaying = false.obs;
  final previewProgress = 0.0.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initAudioSession();
    _setupPreviewListener();
  }
  
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }
  
  void _setupPreviewListener() {
    previewPlayer.playerStateStream.listen((state) {
      isPreviewPlaying.value = state.playing;
    });
    
    previewPlayer.positionStream.listen((position) {
      if (previewPlayer.duration != null) {
        previewProgress.value = position.inMilliseconds / 
            previewPlayer.duration!.inMilliseconds;
      }
    });
  }
  
  Future<void> loadMusic() async {
    isLoading.value = true;
    try {
      musicList.value = await _musicRepository.getMusic();
    } catch (e) {
      print('Error loading music: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadMusicForNote(String noteId) async {
    currentNoteId = noteId;
    currentBookId = null;
    
    try {
      final music = await _musicRepository.getMusicForNote(noteId);
      if (music != null) {
        selectedMusic.value = music;
      } else {
        selectedMusic.value = null;
      }
    } catch (e) {
      print('Error loading music for note: $e');
    }
  }
  
  Future<void> loadMusicForBook(String bookId) async {
    currentBookId = bookId;
    currentNoteId = null;
    
    try {
      final music = await _musicRepository.getMusicForBook(bookId);
      if (music != null) {
        selectedMusic.value = music;
      } else {
        selectedMusic.value = null;
      }
    } catch (e) {
      print('Error loading music for book: $e');
    }
  }
  
  Future<void> setMusicForCurrentItem(String musicId) async {
    try {
      if (currentNoteId != null) {
        await _musicRepository.setMusicForNote(currentNoteId!, musicId);
        await _musicService.loadMusicForNote(currentNoteId!);
      } else if (currentBookId != null) {
        await _musicRepository.setMusicForBook(currentBookId!, musicId);
        await _musicService.loadMusicForBook(currentBookId!);
      }
      
      // Update selected music
      final music = await _musicRepository.getMusicById(musicId);
      if (music != null) {
        selectedMusic.value = music;
      }
    } catch (e) {
      print('Error setting music: $e');
    }
  }
  
  Future<void> removeMusicFromCurrentItem() async {
    try {
      if (currentNoteId != null) {
        await _musicRepository.removeMusicFromNote(currentNoteId!);
        selectedMusic.value = null;
        await _musicService.stop();
      } else if (currentBookId != null) {
        await _musicRepository.removeMusicFromBook(currentBookId!);
        selectedMusic.value = null;
        await _musicService.stop();
      }
    } catch (e) {
      print('Error removing music: $e');
    }
  }
  
  Future<void> addNewMusic() async {
    if (titleController.text.trim().isEmpty ||
        artistController.text.trim().isEmpty ||
        urlController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      final music = await _musicRepository.createMusic(
        title: titleController.text.trim(),
        artist: artistController.text.trim(),
        url: urlController.text.trim(),
      );
      
      if (music != null) {
        musicList.add(music);
        clearForm();
        
        Get.snackbar(
          'Success',
          'Music added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add music: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void clearForm() {
    titleController.clear();
    artistController.clear();
    urlController.clear();
  }
  
  Future<void> previewMusic(String url) async {
    try {
      if (isPreviewPlaying.value) {
        await previewPlayer.stop();
        isPreviewPlaying.value = false;
        return;
      }
      
      await previewPlayer.setUrl(url);
      previewPlayer.play();
    } catch (e) {
      print('Error previewing music: $e');
      Get.snackbar(
        'Error',
        'Failed to play preview: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> deleteMusic(Music music) async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Music'),
          content: Text('Are you sure you want to delete "${music.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      
      if (result == true) {
        await _musicRepository.deleteMusic(music.id);
        musicList.removeWhere((m) => m.id == music.id);
        
        // If this was the selected music, remove it
        if (selectedMusic.value?.id == music.id) {
          await removeMusicFromCurrentItem();
        }
        
        Get.snackbar(
          'Success',
          'Music deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error deleting music: $e');
      Get.snackbar(
        'Error',
        'Failed to delete music: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> processYoutubeUrl(String url) async {
    if (url.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a YouTube URL',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      Get.snackbar(
        'Error',
        'Not a valid YouTube URL',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      isLoading.value = true;
      
      // Show processing notification
      Get.snackbar(
        'Processing',
        'Extracting audio from YouTube...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      
      // Create youtube explode instance
      final yt = YoutubeExplode();
      
      try {
        // Get video info
        final video = await yt.videos.get(url);
        
        // Set title and artist automatically from video
        titleController.text = video.title;
        artistController.text = video.author;
        
        try {
          // Get the audio-only stream url
          final manifest = await yt.videos.streamsClient.getManifest(video.id.value);
          
          // Add proper null checks
          if (manifest.audioOnly.isEmpty) {
            throw Exception('No audio streams available for this video');
          }
          
          // Get the highest bitrate audio stream
          final audioStream = manifest.audioOnly.withHighestBitrate();
          
          if (audioStream == null) {
            throw Exception('Could not find suitable audio stream');
          }
          
          // Set the URL to the audioStream URL
          urlController.text = audioStream.url.toString();
          
          Get.snackbar(
            'Success',
            'YouTube audio URL extracted successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (streamError) {
          print('Error getting audio stream: $streamError');
          // Fallback to direct video playback URL 
          urlController.text = 'https://www.youtube.com/watch?v=${video.id.value}';
          
          Get.snackbar(
            'Warning',
            'Could not extract audio URL, using video URL instead',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } finally {
        // Clean up
        yt.close();
        isLoading.value = false;
      }
    } catch (e) {
      isLoading.value = false;
      print('Error processing YouTube URL: $e');
      Get.snackbar(
        'Error',
        'Failed to process YouTube URL: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // New method to pick audio file from device
  Future<void> pickAudioFile() async {
    try {
      // Show file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path;
        
        if (filePath == null) {
          Get.snackbar(
            'Error',
            'Could not get file path',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
        
        // Get file name for title
        final fileName = path.basename(filePath);
        final nameWithoutExtension = path.basenameWithoutExtension(filePath);
        
        // Auto-fill form fields
        titleController.text = nameWithoutExtension;
        artistController.text = 'Local file'; // Default artist name
        
        // For local files, we need to store the file path
        // For compatibility with the music service, we prefix with 'file://'
        urlController.text = 'file://$filePath';
        
        Get.snackbar(
          'Success',
          'Audio file selected: $fileName',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error picking audio file: $e');
      Get.snackbar(
        'Error',
        'Failed to select audio file: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Start playlist of all available music
  Future<void> startPlaylist() async {
    if (musicList.isEmpty) {
      Get.snackbar(
        'Info',
        'No music available to play as playlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      await _musicService.loadAllMusicAsPlaylist();
      Get.snackbar(
        'Success',
        'Started playlist with ${musicList.length} songs',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error starting playlist: $e');
      Get.snackbar(
        'Error',
        'Failed to start playlist: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Go to next song in playlist
  Future<void> nextSong() async {
    await _musicService.playNextInPlaylist();
  }
  
  // Go to previous song in playlist
  Future<void> previousSong() async {
    await _musicService.playPreviousInPlaylist();
  }
  
  // Toggle playlist mode
  Future<void> togglePlaylistMode(bool enable) async {
    if (enable) {
      await _musicService.loadAllMusicAsPlaylist();
    } else {
      // If turning off playlist mode, just update the flag in service
      _musicService.isPlaylistMode.value = false;
    }
  }
  
  @override
  void onClose() {
    titleController.dispose();
    artistController.dispose();
    urlController.dispose();
    previewPlayer.dispose();
    super.onClose();
  }
} 