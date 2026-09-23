import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final postsAsync =
        ref.watch(postsProvider);

    final offline =
        ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache First Posts'),

        actions: [
          IconButton(
            onPressed: () async {
              if (offline) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Force Offline aktif.',
                    ),
                  ),
                );

                return;
              }

              final repository =
                  ref.read(
                postRepositoryProvider,
              );

              await repository
                  .refreshPostsInBackground(
                forceOffline: false,
                onRefreshComplete: () {
                  ref.invalidate(postsProvider);
                },
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Column(
        children: [
          // STATUS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: offline
                ? Colors.orange.shade100
                : Colors.green.shade100,
            child: Row(
              children: [
                Icon(
                  offline
                      ? Icons.cloud_off
                      : Icons.cloud_done,
                ),

                const SizedBox(width: 8),

                Text(
                  offline
                      ? 'Force Offline - menggunakan cache'
                      : 'Cache-first aktif',
                ),
              ],
            ),
          ),

          // POSTS
          Expanded(
            child: postsAsync.when(
              loading: () {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              },

              error: (error, stack) {
                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Text(
                      'Error: $error',
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                );
              },

              data: (posts) {
                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada data posts.\n'
                      'Tekan refresh saat online.',
                      textAlign:
                          TextAlign.center,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.all(16),
                      child: Text(
                        '${posts.length} posts',
                        style:
                            Theme.of(context)
                                .textTheme
                                .titleLarge,
                      ),
                    ),

                    Expanded(
                      child:
                          ListView.builder(
                        itemCount:
                            posts.length,
                        itemBuilder:
                            (context, index) {
                          final post =
                              posts[index];

                          return Card(
                            margin:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading:
                                  CircleAvatar(
                                child: Text(
                                  '${post.id}',
                                ),
                              ),

                              title: Text(
                                post.title,
                              ),

                              subtitle: Text(
                                post.body,
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}