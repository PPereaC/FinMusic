import '../entities/playlist.dart';
import '../entities/song.dart';

abstract class SongsRepository {

  Future<List<Song>> searchSongs(String query, String filter);
  Future<List<Song>> getTrendingSongs();
  Future<List<Song>> getQuickPicks();
  Future<Map<String, List<Playlist>>> getHomePlaylists();
  Future<Playlist> getPlaylistWSongs(String playlistID);

}