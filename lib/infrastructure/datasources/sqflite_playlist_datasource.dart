import 'dart:io';

import 'package:ritmora/config/utils/pretty_print.dart';
import 'package:ritmora/domain/datasources/playlist_datasource.dart';
import 'package:ritmora/domain/entities/playlist.dart';
import 'package:ritmora/domain/entities/song.dart';
import 'package:ritmora/domain/entities/youtube_playlist.dart';
import 'package:ritmora/domain/entities/youtube_song.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../../config/utils/constants.dart';
import '../../presentation/providers/playlist/playlist_provider.dart';
import '../../presentation/widgets/widgets.dart';

class SqflitePlaylistDatasource extends PlaylistDatasource {
  static SqflitePlaylistDatasource? _instance;
  Database? _database;
  final _lock = Lock();
  static const _timeout = Duration(seconds: 10);

  // Constructor privado
  SqflitePlaylistDatasource._();

  // Factory constructor
  factory SqflitePlaylistDatasource() {
    _instance ??= SqflitePlaylistDatasource._();
    return _instance!;
  }

  // Getter para singleton
  static SqflitePlaylistDatasource get instance {
    _instance ??= SqflitePlaylistDatasource._();
    return _instance!;
  }

  // Inicializar DB
  Future<void> init() async {
    if (_database != null) return;

    await _lock.synchronized(() async {

      // Inicializar sqflite_ffi solo en desktop
      if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      var databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'playlists.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            '''
            CREATE TABLE playlist (
              id INTEGER PRIMARY KEY,
              title TEXT NOT NULL,
              author TEXT NOT NULL,
              thumbnailUrl TEXT,
              playlistId TEXT,
              isLocal INTEGER NOT NULL
            )
            '''
          );

          await db.execute(
            '''
            CREATE TABLE playlist_song (
              id INTEGER PRIMARY KEY,
              playlistId INTEGER,
              title TEXT NOT NULL,
              author TEXT NOT NULL,
              thumbnailUrl TEXT NOT NULL,
              streamUrl TEXT NOT NULL,
              endUrl TEXT NOT NULL,
              songId TEXT NOT NULL,
              isLiked INTEGER NOT NULL DEFAULT 0,
              duration TEXT NOT NULL,
              videoId TEXT NOT NULL DEFAULT '',
              isVideo INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (playlistId) REFERENCES playlist(id) ON DELETE CASCADE
            )
            '''
          );

          await db.execute(
            '''
            CREATE TABLE youtube_playlists (
              playlistId TEXT PRIMARY KEY,
              title TEXT,
              author TEXT,
              thumbnailUrl TEXT
            )
            '''
          );

          await db.execute(
            '''
            CREATE TABLE youtube_songs (
              songId TEXT PRIMARY KEY,
              playlistId TEXT,
              title TEXT,
              author TEXT,
              thumbnailUrl TEXT,
              streamUrl TEXT,
              endUrl TEXT,
              isLiked INTEGER,
              duration TEXT,
              videoId TEXT,
              isVideo INTEGER,
              FOREIGN KEY (playlistId) REFERENCES youtube_playlists(playlistId)
            )
            '''
          );

        },
      );
    }, timeout: _timeout);
  }

  Future<Database> _getDB() async {
    if (_database == null) {
      await init();
    }
    return _database!;
  }

  @override
  Future<void> addNewPlaylist(Playlist playlist) async {
    final db = await _getDB();
    await db.transaction((txn) async {
      await txn.rawInsert(
        '''
        INSERT INTO playlist (
          id,
          title,
          author,
          thumbnailUrl,
          playlistId,
          isLocal
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          playlist.id,
          playlist.title,
          playlist.author,
          playlist.thumbnailUrl,
          playlist.playlistId,
          playlist.isLocal
        ]
      );
    });
  }

  @override
  Future<void> addSongToPlaylist(BuildContext context, int playlistID, Song song, {bool showNotifications = true, bool reloadPlaylists = true}) async {
    final db = await _getDB();
    await db.transaction((txn) async {
      await txn.rawInsert(
        '''
        INSERT INTO playlist_song (
          playlistId,
          title,
          author,
          thumbnailUrl,
          streamUrl,
          endUrl,
          songId,
          isLiked,
          duration,
          videoId,
          isVideo
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          playlistID,
          song.title,
          song.author,
          song.thumbnailUrl,
          song.streamUrl,
          song.endUrl,
          song.songId,
          song.isLiked,
          song.duration,
          song.videoId,
          song.isVideo
        ]
      );
      printINFO('Song added: ${song.title} - ${song.author} - ${song.songId}');
    });
  }

  @override
  Future<Playlist> getPlaylistByID(int playlistID) async {
    final db = await _getDB();
    final List<Map<String, dynamic>> playlists = await db.query(
      'playlist',
      where: 'id = ?',
      whereArgs: [playlistID]
    );

    if (playlists.isEmpty) throw Exception('Playlist not found');

    return Playlist(
      id: playlists.first['id'],
      title: playlists.first['title'],
      author: playlists.first['author'],
      thumbnailUrl: playlists.first['thumbnailUrl'],
      playlistId: playlists.first['playlistId'],
      isLocal: playlists.first['isLocal']
    );
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    final db = await _getDB();
    final List<Map<String, dynamic>> playlists = await db.query('playlist');

    return playlists.map((map) => Playlist(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      thumbnailUrl: map['thumbnailUrl'],
      playlistId: map['playlistId'],
      isLocal: map['isLocal']
    )).toList();
  }

  @override
  Future<List<Song>> getSongsFromPlaylist(int playlistID) async {
    final db = await _getDB();
    try {
      final List<Map<String, dynamic>> songs = await db.query(
        'playlist_song',
        where: 'playlistId = ?',
        whereArgs: [playlistID]
      );

      return songs.map((map) => Song(
        title: map['title'],
        author: map['author'],
        thumbnailUrl: map['thumbnailUrl'],
        streamUrl: map['streamUrl'],
        endUrl: map['endUrl'],
        songId: map['songId'],
        duration: map['duration'],
        videoId: map['videoId'] ?? '',
        isVideo: (map['isVideo'] == 1) ? 1 : 0,
        isLiked: (map['isLiked'] == 1) ? 1 : 0,
      )).toList();
    } catch (e) {
      printINFO('Error getting songs from playlist: $e');
      return [];
    }
  }

  @override
  Future<void> removePlaylist(Playlist playlist) async {
    final db = await _getDB();
    await db.delete(
      'playlist',
      where: 'id = ?',
      whereArgs: [playlist.id]
    );
  }

  @override
  Future<void> updatePlaylist(Playlist playlist) async {
    final db = await _getDB();
    await db.update(
      'playlist',
      {
        'title': playlist.title,
        'author': playlist.author,
        'thumbnailUrl': playlist.thumbnailUrl,
        'playlistId': playlist.playlistId,
        'isLocal': playlist.isLocal
      },
      where: 'id = ?',
      whereArgs: [playlist.id]
    );
  }

  @override
  Future<void> updatePlaylistThumbnail(int playlistID, String thumbnailURL) async {
    final db = await _getDB();
    await db.update(
      'playlist',
      {'thumbnailUrl': thumbnailURL},
      where: 'id = ?',
      whereArgs: [playlistID]
    );
  }

  // Método para cerrar la DB al finalizar la app
  Future<void> dispose() async {
    await _lock.synchronized(() async {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
    });
  }
  
  @override
  Future<void> createLocalPlaylist(BuildContext context, final TextEditingController playlistNameController, WidgetRef ref) {
    return showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Nueva Playlist',
        hintText: 'Nombre de la playlist',
        cancelButtonText: 'Cancelar',
        confirmButtonText: 'Crear',
        controller: playlistNameController,
        onCancel: () {
          playlistNameController.clear();
          Navigator.pop(context);
        },
        onConfirm: (value) async {
          final playlist = Playlist(
            title: value,
            author: 'anonymous',
            thumbnailUrl: defaultPoster,
            playlistId: 'XXXXX'
          );
          
          await ref.read(playlistProvider.notifier).addPlaylist(playlist);
          
          if (context.mounted) {
            Navigator.pop(context);
          }
          playlistNameController.clear();
        },
      ),
    );
  }

  @override
  Future<void> addYoutubePlaylist(YoutubePlaylist playlist) async {
    final db = await _getDB();
    await db.transaction((txn) async {
      await txn.rawInsert(
        '''
        INSERT INTO youtube_playlists (
          playlistId,
          title,
          author,
          thumbnailUrl
        ) VALUES (?, ?, ?, ?)
        ''',
        [
          playlist.playlistId,
          playlist.title,
          playlist.author,
          playlist.thumbnailUrl
        ]
      );
    });
  }

  @override
  Future<void> addSongsToYoutubePlaylist(String playlistID, List<YoutubeSong> songs) async {
    final db = await _getDB();
    
    try {
      await db.transaction((txn) async {
        // Primero verificamos que la playlist exista
        final playlistExists = await txn.rawQuery(
          'SELECT 1 FROM youtube_playlists WHERE playlistId = ? LIMIT 1',
          [playlistID]
        );
        
        if (playlistExists.isEmpty) {
          throw Exception('La playlist con id $playlistID no existe');
        }
        
        // Insertamos cada canción
        for (final song in songs) {
          await txn.rawInsert(
            '''
            INSERT OR REPLACE INTO youtube_songs (
              playlistId,
              title,
              author,
              thumbnailUrl,
              streamUrl,
              endUrl,
              songId,
              isLiked,
              duration,
              videoId,
              isVideo
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              playlistID,
              song.title,
              song.author,
              song.thumbnailUrl,
              song.streamUrl,
              song.endUrl,
              song.songId,
              song.isLiked,
              song.duration,
              song.videoId,
              song.isVideo
            ]
          );
          printINFO('Canción añadida: ${song.title} - ${song.author} - ${song.songId}');
        }
      });
      
      printINFO('Se han añadido ${songs.length} canciones a la playlist $playlistID');
    } catch (e) {
      printERROR('Error al añadir canciones a la playlist: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<YoutubePlaylist>> getYoutubePlaylists() async {
    
    final db = await _getDB();
    final List<Map<String, dynamic>> playlists = await db.query('youtube_playlists');

    return playlists.map((map) => YoutubePlaylist(
      playlistId: map['playlistId'],
      title: map['title'],
      author: map['author'],
      thumbnailUrl: map['thumbnailUrl'],
    )).toList();

  }
  
  @override
  Future<List<YoutubeSong>> getYoutubeSongsFromPlaylist(String playlistId) async {
    final db = await _getDB();
    try {
      // Verificar si existen canciones para esta playlist
      final List<Map<String, dynamic>> songs = await db.query(
        'youtube_songs',
        where: 'playlistId = ?',
        whereArgs: [playlistId]
      );

      if (songs.isEmpty) {
        return [];
      }

      return songs.map((map) => YoutubeSong(
        songId: map['songId'],
        playlistId: map['playlistId'],
        title: map['title'],
        author: map['author'],
        thumbnailUrl: map['thumbnailUrl'],
        streamUrl: map['streamUrl'],
        endUrl: map['endUrl'],
        isLiked: map['isLiked'],
        duration: map['duration'],
        videoId: map['videoId'],
        isVideo: map['isVideo'],
      )).toList();
    } catch (e) {
      printERROR('Error obteniendo canciones de YouTube: $e');
      return [];
    }
  }
  
  @override
  Future<void> updateYoutubePlaylistThumbnail(String playlistID, String thumbnailURL) async {
    final db = await _getDB();
    await db.update(
      'youtube_playlists',
      {'thumbnailUrl': thumbnailURL},
      where: 'playlistId = ?',
      whereArgs: [playlistID]
    );
  }
  
  @override
  Future<void> removeYoutubePlaylist(String youtubePlaylistID) async {
    final db = await _getDB();

    final log = await db.delete(
      'youtube_songs',
      where: 'playlistId = ?',
      whereArgs: [youtubePlaylistID]
    );

    printINFO('Eliminadas sus $log canciones');

    await db.delete(
      'youtube_playlists',
      where: 'playlistId = ?',
      whereArgs: [youtubePlaylistID]
    );
  }
  
  @override
  Future<bool> isThisYoutubePlaylistSaved(String playlistID) async {
    final db = await _getDB();

    final List<Map<String, dynamic>> result = await db.query(
      'youtube_playlists',
      where: 'playlistId = ?',
      whereArgs: [playlistID]
    );

    if (result.isEmpty) {
      return false;
    } else {
      return true;
    }

  }
  
  @override
  Future<bool> checkIfSongIsInDB(String songID) async {
    final db = await _getDB();
    
    // Para playlist creadas en la aplicación
    final List<Map<String, dynamic>> result = await db.query(
      'playlist_song',
      where: 'songId = ?',
      whereArgs: [songID]
    );

    // Para canciones de las playlists de YouTube
    final List<Map<String, dynamic>> result2 = await db.query(
      'youtube_songs',
      where: 'songId = ?',
      whereArgs: [songID]
    );

    if (result.isEmpty && result2.isEmpty) {
      return false;
    } else {
      return true;
    }
  }
  
  @override
  Future<Song> getSongFromDB(String songID) async {
    final db = await _getDB();

    // Para playlist creadas en la aplicación
    final List<Map<String, dynamic>> result = await db.query(
      'playlist_song',
      where: 'songId = ?',
      whereArgs: [songID]
    );

    if (result.isNotEmpty) {
      return Song(
        title: result[0]['title'],
        author: result[0]['author'],
        thumbnailUrl: result[0]['thumbnailUrl'],
        streamUrl: result[0]['streamUrl'],
        endUrl: result[0]['endUrl'],
        songId: result[0]['songId'],
        duration: result[0]['duration'],
      );
    }

    // Para canciones de las playlists de YouTube
    final List<Map<String, dynamic>> result2 = await db.query(
      'youtube_songs',
      where: 'songId = ?',
      whereArgs: [songID]
    );

    if (result2.isNotEmpty) {
      final youtubeSong = YoutubeSong(
        songId: result2[0]['songId'],
        playlistId: result2[0]['playlistId'],
        title: result2[0]['title'],
        author: result2[0]['author'],
        thumbnailUrl: result2[0]['thumbnailUrl'],
        streamUrl: result2[0]['streamUrl'],
        endUrl: result2[0]['endUrl'],
        duration: result2[0]['duration'],
        videoId: result2[0]['videoId'],
        isVideo: result2[0]['isVideo'],
        isLiked: result2[0]['isLiked'],
      );

      // Convertir YoutubeSong a Song
      final song = Song(
        title: youtubeSong.title,
        author: youtubeSong.author,
        thumbnailUrl: youtubeSong.thumbnailUrl,
        streamUrl: youtubeSong.streamUrl,
        endUrl: youtubeSong.endUrl,
        songId: youtubeSong.songId,
        duration: youtubeSong.duration,
        videoId: youtubeSong.videoId,
        isVideo: youtubeSong.isVideo,
        isLiked: youtubeSong.isLiked,
      );

      return song;
    }

    return Song(
      title: 'NOBD',
      author: 'NOBD',
      thumbnailUrl: 'NOBD',
      streamUrl: 'NOBD',
      endUrl: 'NOBD',
      songId: songID,
      duration: ''
    );

  }
  
  @override
  Future<void> updateStreamUrl(Song song) async {
    final db = await _getDB();

    await db.update(
      'playlist_song',
      {'streamUrl': song.streamUrl},
      where: 'songId = ?',
      whereArgs: [song.songId]
    );

    await db.update(
      'youtube_songs',
      {'streamUrl': song.streamUrl},
      where: 'songId = ?',
      whereArgs: [song.songId]
    );

  }
  
  @override
  Future<List<Song>> getSongsFromLocalPlaylist(String playlistID) async {
    final db = await _getDB();

    final List<Map<String, dynamic>> songs = await db.query(
      'playlist_song',
      where: 'playlistId = ?',
      whereArgs: [playlistID]
    );

    return songs.map((song) => Song(
      title: song['title'],
      author: song['author'],
      thumbnailUrl: song['thumbnailUrl'],
      streamUrl: song['streamUrl'],
      endUrl: song['endUrl'],
      songId: song['songId'],
      duration: song['duration'],
    )).toList();

  }
  
  @override
  Future<List<YoutubeSong>> getSongsFromYoutubePlaylist(String playlistID) async {
    final db = await _getDB();

    final List<Map<String, dynamic>> songs = await db.query(
      'youtube_songs',
      where: 'playlistId = ?',
      whereArgs: [playlistID]
    );

    return songs.map((song) => YoutubeSong(
      songId: song['songId'],
      playlistId: song['playlistId'],
      title: song['title'],
      author: song['author'],
      thumbnailUrl: song['thumbnailUrl'],
      streamUrl: song['streamUrl'],
      endUrl: song['endUrl'],
      duration: song['duration'],
      videoId: song['videoId'],
      isVideo: song['isVideo'],
      isLiked: song['isLiked'],
    )).toList();

  }
  
}