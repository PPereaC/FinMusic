import 'package:finmusic/domain/datasources/playlist_datasource.dart';
import 'package:finmusic/domain/entities/playlist.dart';
import 'package:finmusic/domain/entities/song.dart';
import 'package:flutter/material.dart';

import '../../domain/repositories/playlist_repository.dart';

class PlaylistRepositoryImpl extends PlaylistRepository {

  final PlaylistDatasource datasource;

  PlaylistRepositoryImpl({required this.datasource});

  @override
  Future<void> addNewPlaylist(Playlist playlist) {
    return datasource.addNewPlaylist(playlist);
  }

  @override
  Future<void> addSongToPlaylist(BuildContext context, int playlistID, Song song, {bool showNotifications = true, bool reloadPlaylists = true}) {
    return datasource.addSongToPlaylist(context, playlistID, song, showNotifications: showNotifications);
  }

  @override
  Future<List<Playlist>> getPlaylists() {
    return datasource.getPlaylists();
  }

  @override
  Future<void> removePlaylist(Playlist playlist) {
    return datasource.removePlaylist(playlist);
  }

  @override
  Future<void> updatePlaylist(Playlist playlist) {
    return datasource.updatePlaylist(playlist);
  }
  
  @override
  Future<Playlist> getPlaylistByID(int playlistID) {
    return datasource.getPlaylistByID(playlistID);
  }
  
  @override
  Future<void> updatePlaylistThumbnail(int playlistID, String thumbnailURL) {
    return datasource.updatePlaylistThumbnail(playlistID, thumbnailURL);
  }
  
  @override
  Future<List<Song>> getSongsFromPlaylist(int playlistID) {
    return datasource.getSongsFromPlaylist(playlistID);
  }

}