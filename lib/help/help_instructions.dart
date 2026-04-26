import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HelpInstructions extends StatelessWidget {
  const HelpInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      // Load the file from assets
      future: rootBundle.loadString("assets/help_instructions.md"),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          // Render the markdown when loaded
          return Markdown(
            data: snapshot.data!,
            selectable: true,
            onTapLink: (text, url, title) {
              if (url != null) {
                launchUrl(Uri.parse(url)); // Handled by url_launcher
              }
            },
            styleSheet: MarkdownStyleSheet(
              a: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
            imageBuilder: (uri, title, alt) {
              if (uri.path.endsWith('.svg')) {
                return SvgPicture.network(
                  uri.path,
                  placeholderBuilder: (context) => CircularProgressIndicator(),
                  // width: 100, // Customize size
                );
              } else {
                return Image.network(
                  uri.toString(),
                  errorBuilder: (context, error, stack) =>
                      Icon(Icons.broken_image, color: Colors.grey),
                  loadingBuilder:
                      (
                        BuildContext context,
                        Widget child,
                        ImageChunkEvent? loadingProgress,
                      ) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                );
              }
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text("Error loading markdown"));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
