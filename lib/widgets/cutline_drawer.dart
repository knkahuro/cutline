import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../utils/object_library.dart';

class CutlineDrawer extends StatelessWidget {
  const CutlineDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Cutline',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find the perfect ratio',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: AppColors.text),
                  title: const Text(
                    'New Shape',
                    style: TextStyle(color: AppColors.text),
                  ),
                  onTap: () {
                    provider.newGame();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppColors.text),
                  title: const Text(
                    'How to Play',
                    style: TextStyle(color: AppColors.text),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showHowToPlay(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category, color: AppColors.text),
                  title: const Text(
                    'Library',
                    style: TextStyle(color: AppColors.text),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLibrary(context, provider);
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _showLibrary(BuildContext context, GameProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'OBJECT LIBRARY',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: ObjectLibrary.silhouettes.length,
                itemBuilder: (context, index) {
                  final sil = ObjectLibrary.silhouettes[index];
                  return InkWell(
                    onTap: () {
                      provider.loadSilhouette(sil);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shape_line, color: AppColors.accent, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            sil.name,
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'How to Play',
          style: TextStyle(color: AppColors.text),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Look at the target ratio displayed at the top.',
              style: TextStyle(color: AppColors.text),
            ),
            SizedBox(height: 8),
            Text(
              '2. Drag across the shape to cut it.',
              style: TextStyle(color: AppColors.text),
            ),
            SizedBox(height: 8),
            Text(
              '3. Try to split the area as close to the target ratio as possible!',
              style: TextStyle(color: AppColors.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it!',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
