import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../models/music_model.dart';
import '../repositories/music_repository.dart';

class MusicService extends GetxService {
  final MusicRepository _musicRepository = Get.find<MusicRepository>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Reactive state
  final isPlaying = false.obs;
  final currentMusic = Rxn<Music>();
  final volume = 0.5.obs;
  final isLooping = false.obs;
  
  // Playlist functionality with page/note specific tracking
  final RxList<Music> playlist = <Music>[].obs;
  final currentPlaylistIndex = 0.obs;
  final isPlaylistMode = false.obs;
  
  // Track which note/book the playlist belongs to
  final playlistOwnerId = ''.obs;
  
  MusicService() {
    // Set up audio player listeners
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });
    
    // Set up completion listener
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (isLooping.value) {
          play(); // Restart if looping
        } else if (isPlaylistMode.value) {
          playNextInPlaylist(); // Play next song in playlist
        } else {
          stop(); // Stop if not looping or in playlist mode
        }
      }
    });
    
    // Set initial volume
    _audioPlayer.setVolume(volume.value);
  }
  
  // Play the current music
  Future<void> play() async {
    if (currentMusic.value == null) return;
    
    if (_audioPlayer.playing) {
      await _audioPlayer.stop();
    }
    
    try {
      final url = currentMusic.value!.url;
      
      // Handle local file paths
      if (url.startsWith('file://')) {
        // Remove 'file://' prefix for local files
        final filePath = url.substring(7);
        await _audioPlayer.setFilePath(filePath);
      } else {
        // For network URLs
        await _audioPlayer.setUrl(url);
      }
      
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing music: $e');
    }
  }
  
  // Pause the current music
  Future<void> pause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    }
  }
  
  // Stop the current music
  Future<void> stop() async {
    await _audioPlayer.stop();
    isPlaying.value = false;
  }
  
  // Toggle playback - stop if playing, play if stopped
  Future<void> togglePlayback() async {
    if (isPlaying.value) {
      await stop();
    } else if (currentMusic.value != null) {
      await play();
    }
  }
  
  // Set looping for current track
  void setLooping(bool loop) {
    isLooping.value = loop;
    _audioPlayer.setLoopMode(loop ? LoopMode.one : LoopMode.off);
  }
  
  // Set volume (0.0 to 1.0)
  void setVolume(double newVolume) {
    if (newVolume < 0.0) newVolume = 0.0;
    if (newVolume > 1.0) newVolume = 1.0;
    
    volume.value = newVolume;
    _audioPlayer.setVolume(newVolume);
  }
  
  // Load all music as a playlist
  Future<void> loadAllMusicAsPlaylist() async {
    try {
      final allMusic = await _musicRepository.getMusic();
      if (allMusic.isNotEmpty) {
        playlist.value = allMusic;
        isPlaylistMode.value = true;
        currentPlaylistIndex.value = 0;
        
        // Set current music to first in playlist
        currentMusic.value = playlist[0];
        await play();
      }
    } catch (e) {
      print('Error loading music playlist: $e');
    }
  }
  
  // Play next song in playlist
  Future<void> playNextInPlaylist() async {
    if (!isPlaylistMode.value || playlist.isEmpty) return;
    
    // Increment index and wrap around if needed
    currentPlaylistIndex.value = (currentPlaylistIndex.value + 1) % playlist.length;
    
    // Set current music and play
    currentMusic.value = playlist[currentPlaylistIndex.value];
    await play();
  }
  
  // Play previous song in playlist
  Future<void> playPreviousInPlaylist() async {
    if (!isPlaylistMode.value || playlist.isEmpty) return;
    
    // Decrement index and wrap around if needed
    currentPlaylistIndex.value = (currentPlaylistIndex.value - 1 + playlist.length) % playlist.length;
    
    // Set current music and play
    currentMusic.value = playlist[currentPlaylistIndex.value];
    await play();
  }
  
  // Stop playlist playback and exit playlist mode
  Future<void> stopPlaylist() async {
    isPlaylistMode.value = false;
    await stop();
    currentMusic.value = null;
  }
  
  // Load a music from the repository
  Future<void> loadMusic(String musicId) async {
    try {
      // Disable playlist mode when loading individual tracks
      isPlaylistMode.value = false;
      
      final music = await _musicRepository.getMusicById(musicId);
      if (music != null) {
        currentMusic.value = music;
        // Auto-play when loaded
        await play();
      }
    } catch (e) {
      print('Error loading music: $e');
    }
  }
  
  // Load music for a note
  Future<void> loadMusicForNote(String noteId) async {
    try {
      final music = await _musicRepository.getMusicForNote(noteId);
      if (music != null) {
        // Disable playlist mode when loading individual tracks
        isPlaylistMode.value = false;
        
        currentMusic.value = music;
        await play();
        
        // Also load all music into a playlist for this note
        await loadAllMusicAsPlaylistForItem(noteId);
      } else {
        // Clear and stop if no music
        currentMusic.value = null;
        await stop();
      }
    } catch (e) {
      print('Error loading music for note: $e');
    }
  }
  
  // Load music for a book
  Future<void> loadMusicForBook(String bookId) async {
    try {
      final music = await _musicRepository.getMusicForBook(bookId);
      if (music != null) {
        // Disable playlist mode when loading individual tracks
        isPlaylistMode.value = false;
        
        currentMusic.value = music;
        await play();
        
        // Also load all music into a playlist for this book
        await loadAllMusicAsPlaylistForItem(bookId);
      } else {
        // Clear and stop if no music
        currentMusic.value = null;
        await stop();
      }
    } catch (e) {
      print('Error loading music for book: $e');
    }
  }
  
  // Used when leaving a note or book to stop music playback
  Future<void> handleLeavingItem() async {
    if (!isPlaylistMode.value) {
      // Only stop if not in playlist mode
      currentMusic.value = null;
      await stop();
    } else {
      // Clear playlist owner ID when leaving
      playlistOwnerId.value = '';
      isPlaylistMode.value = false;
      currentMusic.value = null;
      await stop();
    }
  }
  
  // Load all music as a playlist for a specific note/book
  Future<void> loadAllMusicAsPlaylistForItem(String itemId) async {
    try {
      // Only create a new playlist if we're not already in playlist mode for this item
      if (playlistOwnerId.value != itemId) {
        final allMusic = await _musicRepository.getMusic();
        if (allMusic.isNotEmpty) {
          playlist.value = allMusic;
          playlistOwnerId.value = itemId;
          
          // Don't auto-enable playlist mode, just prepare the playlist
          currentPlaylistIndex.value = 0;
          
          // Find the currently playing music in the playlist
          if (currentMusic.value != null) {
            final index = playlist.indexWhere((music) => music.id == currentMusic.value!.id);
            if (index >= 0) {
              currentPlaylistIndex.value = index;
            }
          }
        }
      }
    } catch (e) {
      print('Error loading music playlist: $e');
    }
  }
  
  // Load all music as a playlist and start playback
  Future<void> startPlaylistForCurrentItem() async {
    if (playlist.isEmpty || playlistOwnerId.value.isEmpty) {
      print('Cannot start playlist: No playlist available or no current item');
      return;
    }
    
    try {
      isPlaylistMode.value = true;
      
      // Set current music to first in playlist if none is playing
      if (currentMusic.value == null) {
        currentMusic.value = playlist[currentPlaylistIndex.value];
      }
      
      await play();
    } catch (e) {
      print('Error starting playlist: $e');
    }
  }
  
  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
} 