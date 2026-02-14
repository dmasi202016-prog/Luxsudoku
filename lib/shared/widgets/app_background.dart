import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppBackground extends StatefulWidget {
  const AppBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  // Start with local space image
  ImageProvider _currentBackground = const AssetImage('assets/space_background.png');
  bool _isLocalImage = true;

  @override
  void initState() {
    super.initState();
    // Only load network images on non-web platforms (CORS issues on web)
    if (!kIsWeb) {
      _loadRandomBackground();
    }
  }

  Future<void> _loadRandomBackground() async {
    // Wait a bit to let the local image show first
    await Future.delayed(const Duration(milliseconds: 500));
    
    final randomUrl = 'https://source.unsplash.com/1920x1080/?nature,landscape&sig=${DateTime.now().millisecondsSinceEpoch}';
    
    // Preload the network image
    final networkImage = NetworkImage(randomUrl);
    try {
      await precacheImage(networkImage, context);
      // Only update if still mounted
      if (mounted) {
        setState(() {
          _currentBackground = networkImage;
          _isLocalImage = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load random background: $e');
      // If network fails, keep using local image (silently fail)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A0A08), // Dark gold-tinted black
            Color(0xFF1A1410), // Darker brown-gold
            Color(0xFF2A2419), // Medium brown-gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (local first, then network)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              child: Opacity(
                key: ValueKey(_isLocalImage),
                opacity: 0.6,
                child: Image(
                  image: _currentBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
          // Gold-tinted overlay for better text visibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0A0A08).withOpacity(0.6),
                    const Color(0xFF1A1410).withOpacity(0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
