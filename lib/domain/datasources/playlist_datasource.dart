import 'package:flutter/material.dart';

import '../entities/playlist.dart';
import '../entities/song.dart';

abstract class PlaylistDatasource {

  Future<List<Playlist>> getPlaylists();
  Future<List<Song>> getSongsFromPlaylist(int playlistID);
  Future<void> addNewPlaylist(Playlist playlist);
  Future<void> removePlaylist(Playlist playlist);
  Future<void> updatePlaylist(Playlist playlist);
  Future<void> addSongToPlaylist(BuildContext context, int playlistID, Song song, {bool showNotifications = true, bool reloadPlaylists = true});
  Future<Playlist> getPlaylistByID(int playlistID);
  Future<void> updatePlaylistThumbnail(int playlistID, String thumbnailURL);

}