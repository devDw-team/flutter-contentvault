import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contentvault/core/database/app_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class ArticleReaderView extends ConsumerWidget {
  final Content content;
  final ArticleContent? articleContent;

  const ArticleReaderView({
    super.key,
    required this.content,
    this.articleContent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metadata = content.metadata != null 
        ? jsonDecode(content.metadata!) as Map<String, dynamic>
        : <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(content.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _openInBrowser(content.url),
          ),
          IconButton(
            icon: Icon(
              content.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: () {
              // TODO: Implement favorite toggle
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  // TODO: Implement share
                  break;
                case 'archive':
                  // TODO: Implement archive
                  break;
                case 'delete':
                  // TODO: Implement delete
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(
                    content.isArchived ? Icons.unarchive : Icons.archive,
                  ),
                  title: Text(content.isArchived ? 'Unarchive' : 'Archive'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article header
            if (content.thumbnailUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    content.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title
            Text(
              content.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Metadata row
            Row(
              children: [
                if (content.author != null) ...[
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    content.author!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (content.publishedAt != null) ...[
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(content.publishedAt!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (metadata['readingTimeMinutes'] != null) ...[
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${metadata['readingTimeMinutes']} min read',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Source
            InkWell(
              onTap: () => _openInBrowser(content.url),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Uri.parse(content.url).host,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 32),

            // Content
            if (articleContent != null) ...[
              _buildContent(context, articleContent!),
            ] else if (content.contentText != null) ...[
              Text(
                content.contentText!,
                style: theme.textTheme.bodyLarge,
              ),
            ] else if (content.description != null) ...[
              Text(
                content.description!,
                style: theme.textTheme.bodyLarge,
              ),
            ],

            // Images gallery
            if (articleContent != null && articleContent!.images.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Images',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildImageGallery(context, articleContent!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ArticleContent articleContent) {
    final theme = Theme.of(context);
    
    // For now, display plain text. In a real app, you might want to
    // render HTML using flutter_html or similar package
    return SelectableText(
      articleContent.contentText,
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.6,
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context, ArticleContent articleContent) {
    final images = jsonDecode(articleContent.images) as List<dynamic>;
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final imageUrl = images[index] as String;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                // TODO: Open image in full screen
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}