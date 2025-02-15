import 'package:finmusic/presentation/widgets/home/song_horizontal_listview_widget.dart';
import 'package:finmusic/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:marquee/marquee.dart';

import '../../config/utils/responsive.dart';
import '../../domain/entities/song.dart';
import '../delegates/search_songs_delegate.dart';
import '../providers/providers.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();
    
    // Cargar datos iniciales
    ref.read(trendingSongsProvider.notifier).loadSongs();
    ref.read(quickPicksProvider.notifier).loadSongs();
    ref.read(homePlaylistsProvider.notifier).loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Estados de las diferentes listas
    final trendingSongs = ref.watch(trendingSongsProvider);
    final quickPicks = ref.watch(quickPicksProvider);
    final homePlaylists = ref.watch(homePlaylistsProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: colors.surface,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            const GradientWidget(),
            
            CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0) ...[
                            if (Responsive.isMobile(context))
                              Padding(
                                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                                        
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        width: 50,
                                        height: 50,
                                      ),
                                    ),
                                                        
                                    const Spacer(),
                                                        
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      child: IconButton.filled(
                                        onPressed: () async {
                                          final searchQuery = ref.read(searchQueryProvider);
                                          // ignore: unused_local_variable
                                          final song = await showSearch<Song?>(
                                            query: searchQuery,
                                            context: context,
                                            delegate: SearchSongsDelegate(
                                              searchSongs: ref.read(searchSongsProvider.notifier).searchSongsByQuery,
                                              colors: colors,
                                            )
                                          );
                                        },
                                        icon: const Icon(Iconsax.search_normal_1_outline),
                                        color: Colors.white,
                                        style: IconButton.styleFrom(
                                          backgroundColor: colors.secondary.withOpacity(0.5),
                                          padding: const EdgeInsets.all(10),
                                        ),
                                      ),
                                    ),
                                                        
                                    const SizedBox(width: 3),
                                                        
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      child: IconButton.filled(
                                        onPressed: () {},
                                        icon: const Icon(Iconsax.notification_outline),
                                        color: Colors.white,
                                        style: IconButton.styleFrom(
                                          backgroundColor: colors.secondary.withOpacity(0.5),
                                          padding: const EdgeInsets.all(10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            if (Responsive.isDesktop(context))
                              const SizedBox(height: 10),
                            
                          ],
                            
                          if (index == 1) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Column(
                                children: [
                                  const _SectionTitle('Selecciones rápidas', showViewAll: false),
                                  const SizedBox(height: 15),
                                  SongGridHorizontalListview(songs: quickPicks),
                                
                                  const _SectionTitle('En tendencia'),
                                  const SizedBox(height: 15),
                                  SongHorizontalListview(songs: trendingSongs),
                                
                                  // Iteramos sobre cada categoría de playlists
                                  ...homePlaylists.entries.map((entry) => [
                                    _SectionTitle(entry.key, showViewAll: false),
                                    const SizedBox(height: 15),
                                    PlaylistHorizontalListview(
                                      onTap: (playlist) {
                                        context.go(
                                          '/library/playlist/1/${playlist.playlistId}',
                                          extra: playlist
                                        );
                                      },
                                      playlists: entry.value
                                    ),
                                    const SizedBox(height: 20), // Espaciado entre secciones
                                  ]).expand((widgets) => widgets),
                                ],
                              ),
                            )
                            
                          ],
                        ],
                      );
                    },
                    childCount: 2,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool showViewAll;
  
  const _SectionTitle(
    this.title, {
    this.showViewAll = true
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: screenWidth * 0.9,
            child: title.length > 30
                ? SizedBox(
                    height: textStyle.titleLarge?.fontSize != null
                        ? textStyle.titleLarge!.fontSize! * 1.5
                        : 24.0, // Define una altura adecuada
                    child: Marquee(
                      text: title,
                      style: textStyle.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      scrollAxis: Axis.horizontal,
                      blankSpace: 10.0,
                      velocity: 30.0,
                      pauseAfterRound: const Duration(seconds: 3),
                      accelerationDuration: const Duration(seconds: 1),
                      accelerationCurve: Curves.linear,
                      decelerationDuration: const Duration(milliseconds: 500),
                      decelerationCurve: Curves.easeOut,
                    ),
                  )
                : Text(
                    title,
                    style: textStyle.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                  ),
          ),

          // if (showViewAll)
          //   InkWell(
          //     onTap: () {
          //       // TODO: Implementar navegación
          //     },
          //     child: Row(
          //       children: [
          //         Text(
          //           'Ver todo',
          //           style: textStyle.bodyLarge?.copyWith(
          //             color: Colors.white
          //           ),
          //         ),
          //         const SizedBox(width: 5),
          //         const Icon(
          //           Icons.arrow_forward_ios_rounded,
          //           size: 16,
          //           color: Colors.white
          //         ),
          //       ],
          //     ),
          //   ),
        ],
      ),
    );
  }
}