import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 1. Import Riverpod
import 'screens/main_nav.dart';

void main() {
  // 👇 2. Wrap your root widget in a ProviderScope
  runApp(
    const ProviderScope(
      child: CampusConnectApp(),
    ),
  );
}

class CampusConnectApp extends StatelessWidget {
  const CampusConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // Apply the wrapper to the entire routing system
      builder: (context, child) {
        return DesktopMobileWrapper(
          child: child!,
        );
      },
      home: const MainNav(),
    );
  }
}

// NEW: Desktop/Mobile Wrapper Widget with 75% Zoom Scale
class DesktopMobileWrapper extends StatelessWidget {
  final Widget child;

  const DesktopMobileWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Detect if the app is running on a Desktop OS
    final isDesktopOS = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktopOS) {
      return Container(
        color: const Color(0xFF121212),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 1. The actual logical size of the phone (iPhone 14 Pro Max)
              const double logicalWidth = 430.0; // Change to 393.0 if you want standard iPhone size
              const double logicalHeight = 940.0;

              // 2. The shrink factor (75% = 0.75)
              const double scale = 0.80;

              // 3. The physical size the box will actually take on your desktop monitor
              final double scaledWidth = logicalWidth * scale;
              final double scaledHeight = logicalHeight * scale;

              return Container(
                width: scaledWidth,
                height: scaledHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  // We scale the border radius so the corners look correct at 75%
                  borderRadius: BorderRadius.circular(24.0 * scale),
                ),
                // 4. FittedBox acts exactly like Chrome DevTools zoom.
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: logicalWidth,
                    height: logicalHeight,
                    // 5. MediaQuery override ensures the internal app still thinks it has full space
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: const Size(logicalWidth, logicalHeight),
                      ),
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // If it is a Mobile OS, return the app completely full-screen
    return child;
  }
}