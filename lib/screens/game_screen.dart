import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/shape_painter.dart';
import '../widgets/cutline_drawer.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CutlineDrawer(),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Cutline'),
            Consumer<GameProvider>(
              builder: (context, provider, child) {
                if (!provider.isMultiplayer) return const SizedBox.shrink();
                return Text(
                  'FRIEND ${provider.currentPlayerIndex + 1} OF ${provider.playerCount}',
                  style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 1),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {

          return Stack(
            children: [
              Column(
                children: [
                   const SizedBox(height: 20),
                   _buildTargetIndicator(provider),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                        return GestureDetector(
                          onPanStart: (details) => provider.updateCutStart(details.localPosition - center),
                          onPanUpdate: (details) => provider.updateCutEnd(details.localPosition - center),
                          onPanEnd: (details) => provider.submitCut(),
                          child: Center(
                            child: CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: ShapePainter(
                                points: provider.currentPolygon,
                                holes: provider.holes,
                                cutPath: provider.cutPath.map((p) => p + center).toList(),
                                gameEnded: provider.gameEnded,
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  ),
                  if (provider.gameEnded)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: ElevatedButton(
                        onPressed: () {
                          provider.newGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('NEXT SHAPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Text(
                        'SLICE ACROSS THE OBJECT',
                        style: TextStyle(
                          color: Colors.white24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                ],
              ),
              if (provider.isWaitingForNextPlayer)
                _buildPassPhoneOverlay(provider),
              if (provider.gameEnded && provider.isMultiplayer)
                _buildLeaderboardOverlay(provider),
              if (provider.gameEnded && !provider.isMultiplayer)
                _buildScoreOverlay(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTargetIndicator(GameProvider provider) {
    final int percentage = (provider.targetRatio * 100).round();
    return Column(
      children: [
        const Text(
          'TARGET RATIO',
          style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2),
        ),
        Text(
          '$percentage / ${100 - percentage}',
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPassPhoneOverlay(GameProvider provider) {
    return GestureDetector(
      onTap: () => provider.startNextPlayer(),
      child: Container(
        color: Colors.black.withAlpha(230),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phonelink_ring, color: AppColors.accent, size: 64),
            const SizedBox(height: 24),
            Text(
              'FRIEND ${provider.currentPlayerIndex + 1} DONE!',
              style: const TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'PASS TO FRIEND ${provider.currentPlayerIndex + 2}',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'TAP WHEN READY',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardOverlay(GameProvider provider) {
    final scores = provider.multiplayerScores;
    final sortedIndices = List.generate(scores.length, (i) => i)
      ..sort((a, b) => scores[b].compareTo(scores[a]));

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LEADERBOARD',
              style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 4),
            ),
            const SizedBox(height: 20),
            ...sortedIndices.map((index) {
              final isWinner = index == sortedIndices.first;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FRIEND ${index + 1}',
                      style: TextStyle(
                        color: isWinner ? AppColors.accent : Colors.white,
                        fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '${scores[index].round()}%',
                      style: TextStyle(
                        color: isWinner ? AppColors.accent : Colors.white,
                        fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.newGame(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('NEW ROUND', style: TextStyle( 
                color: AppColors.text) ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreOverlay(GameProvider provider) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SCORE',
              style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 4),
            ),
            Text(
              '${provider.lastScore?.round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<GameProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Settings',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Target Ratio',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                   Slider(
                    value: provider.targetRatio,
                    min: 0.1,
                    max: 0.9,
                    divisions: 8,
                    activeColor: AppColors.accent,
                    inactiveColor: AppColors.border,
                    label: '${(provider.targetRatio * 100).round()}%',
                    onChanged: (val) => provider.setTargetRatio(val),
                  ),
                  Center(
                    child: Text(
                      '${(provider.targetRatio * 100).round()} / ${(100 - (provider.targetRatio * 100)).round()}',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Pass the Phone', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Compete with friends on the same shape', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: provider.isMultiplayer,
                    onChanged: (val) => provider.setMultiplayer(val),
                    activeThumbColor: AppColors.accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (provider.isMultiplayer)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Number of Friends', style: TextStyle(color: Colors.white70)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.white),
                              onPressed: provider.playerCount > 2 ? () => provider.setPlayerCount(provider.playerCount - 1) : null,
                            ),
                            Text('${provider.playerCount}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: provider.playerCount < 5 ? () => provider.setPlayerCount(provider.playerCount + 1) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    title: const Text('Symmetric Shapes', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Mirror the object on both sides', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: provider.isSymmetric,
                    onChanged: (val) => provider.setSymmetric(val),
                    activeThumbColor: AppColors.accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    title: const Text('Pointy Shapes', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Gives objects sharp vertices', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: provider.isPointy,
                    onChanged: (val) => provider.setPointy(val),
                    activeThumbColor: AppColors.accent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
