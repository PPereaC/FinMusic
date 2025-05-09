import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/playlist.dart';
import '../entities/song.dart';
import '../entities/youtube_playlist.dart';
import '../entities/youtube_song.dart';

abstract class PlaylistDatasource {

  Future<List<Playlist>> getPlaylists();
  Future<List<Song>> getSongsFromPlaylist(int playlistID);
  Future<void> addNewPlaylist(Playlist playlist);
  Future<void> removePlaylist(Playlist playlist);
  Future<void> updatePlaylist(Playlist playlist);
  Future<void> addSongToPlaylist(BuildContext context, int playlistID, Song song, {bool showNotifications = true, bool reloadPlaylists = true});
  Future<Playlist> getPlaylistByID(int playlistID);
  Future<void> updatePlaylistThumbnail(int playlistID, String thumbnailURL);
  Future<void> createLocalPlaylist(BuildContext context, final TextEditingController playlistNameController, WidgetRef ref);
  Future<void> addYoutubePlaylist(YoutubePlaylist playlist);
  Future<void> addSongsToYoutubePlaylist(String playlistID, List<YoutubeSong> songs);
  Future<List<YoutubePlaylist>> getYoutubePlaylists();
  Future<List<YoutubeSong>> getYoutubeSongsFromPlaylist(String playlistId);
  Future<void> updateYoutubePlaylistThumbnail(String playlistID, String thumbnailURL);
  Future<void> removeYoutubePlaylist(String youtubePlaylistID);
  Future<bool> isThisYoutubePlaylistSaved(String playlistID);

  Future<Song> getSongFromDB(String songID);
  Future<void> updateStreamUrl(Song song);
  Future<bool> checkIfSongIsInDB(String songID);
  Future<List<Song>> getSongsFromLocalPlaylist(String playlistID);
  Future<List<YoutubeSong>> getSongsFromYoutubePlaylist(String playlistID);

}