import 'dart:async';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reagentkit/core/utils/logger.dart';
import 'package:reagentkit/l10n/app_localizations.dart';
import '../../providers/reagent_testing_providers.dart';
import '../../states/test_execution_state.dart';

class ReactionTimerSection extends ConsumerStatefulWidget {
  const ReactionTimerSection({super.key});

  @override
  ConsumerState<ReactionTimerSection> createState() =>
      _ReactionTimerSectionState();
}

class _ReactionTimerSectionState extends ConsumerState<ReactionTimerSection>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalElapsedSeconds = 0;
  bool _isTimerActive = false;
  bool _isTimerComplete = false;
  int _testDurationSeconds = 60;

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final l10n = AppLocalizations.of(context)!;

    ref.listen<TestExecutionState>(testExecutionControllerProvider, (
      previous,
      next,
    ) {
      if (next is TestExecutionLoaded) {
        if (previous is! TestExecutionLoaded) {
          _initializeTimerFromState(next);
        }
      }
    });

    ref.watch(testExecutionControllerProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade50,
            Colors.blue.shade50,
            Colors.cyan.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 8,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.blue.shade500],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(HeroIcons.clock, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.reactionTimer,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Timer display with circular progress
            Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.9),
                        Colors.grey.shade100,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 15,
                        offset: const Offset(-8, -8),
                      ),
                    ],
                  ),
                ),

                // Progress circle
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: _testDurationSeconds > 0
                        ? (_testDurationSeconds - _remainingSeconds) /
                              _testDurationSeconds
                        : 0.0,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isTimerComplete
                          ? Colors.green.shade400
                          : _isTimerActive
                          ? Colors.indigo.shade400
                          : Colors.grey.shade400,
                    ),
                  ),
                ),

                // Timer text
                AnimatedBuilder(
                  animation: _isTimerActive
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(_remainingSeconds),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _isTimerComplete
                                  ? Colors.green.shade600
                                  : _isTimerActive
                                  ? Colors.indigo.shade700
                                  : Colors.grey.shade600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_getOfText(l10n)} ${_formatTime(_testDurationSeconds)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(l10n),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Control buttons with modern styling
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildActionButton(
                  context: context,
                  icon: HeroIcons.play,
                  label: l10n.startTimer,
                  color: Colors.green,
                  onPressed: (!_isTimerActive && !_isTimerComplete)
                      ? () {
                          Logger.debug(
                            'Manual start button pressed - _timer: $_timer, _isTimerComplete: $_isTimerComplete',
                          );
                          _startTimer();
                        }
                      : null,
                ),
                _buildActionButton(
                  context: context,
                  icon: HeroIcons.pause,
                  label: l10n.stopTimer,
                  color: Colors.orange,
                  onPressed: _isTimerActive
                      ? () {
                          _stopTimer();
                        }
                      : null,
                ),
                _buildActionButton(
                  context: context,
                  icon: HeroIcons.arrow_path,
                  label: l10n.resetTimer,
                  color: Colors.blue,
                  onPressed: () {
                    _resetTimer();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;

    return SizedBox(
      width: 90,
      height: 45,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.8),
                    color.withOpacity(1.0),
                  ],
                )
              : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isEnabled ? Colors.white : Colors.grey.shade600,
                    size: 12,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(
                      color: isEnabled ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_isTimerComplete) return Colors.green;
    if (_isTimerActive) return Colors.blue;
    return Colors.grey;
  }

  String _getStatusText(AppLocalizations l10n) {
    if (_isTimerComplete) return _getCompletedText(l10n);
    if (_isTimerActive) return _getRunningText(l10n);
    return _getReadyText(l10n);
  }

  String _getOfText(AppLocalizations l10n) {
    return l10n.localeName == 'ar' ? 'من' : 'of';
  }

  String _getCompletedText(AppLocalizations l10n) {
    return l10n.localeName == 'ar' ? 'مكتمل' : 'COMPLETED';
  }

  String _getRunningText(AppLocalizations l10n) {
    return l10n.localeName == 'ar' ? 'يعمل' : 'RUNNING';
  }

  String _getReadyText(AppLocalizations l10n) {
    return l10n.localeName == 'ar' ? 'جاهز' : 'READY';
  }

  void _initializeTimerFromState(TestExecutionLoaded state) {
    if (mounted) {
      setState(() {
        _testDurationSeconds = state.testExecution.timerDuration;
        _remainingSeconds = _testDurationSeconds;
        _totalElapsedSeconds = 0;
        _isTimerActive = false;
        _isTimerComplete = false;
      });
      Logger.debug(
        'Timer initialized from state - Duration: $_testDurationSeconds seconds',
      );
    }
  }

  void _startTimer() {
    if (!mounted) return;
    Logger.debug('Starting timer - Current remaining: $_remainingSeconds');
    if (_remainingSeconds <= 0) {
      _resetTimer();
      return;
    }
    setState(() {
      _isTimerActive = true;
      _isTimerComplete = false;
    });
    _progressController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _totalElapsedSeconds++;
          Logger.debug(
            'Timer tick - Remaining: $_remainingSeconds, Elapsed: $_totalElapsedSeconds',
          );
        } else {
          _isTimerActive = false;
          _isTimerComplete = true;
          timer.cancel();
          _pulseController.stop();
          Logger.debug('Timer completed');
        }
      });
    });
  }

  void _stopTimer() {
    if (!mounted) return;
    Logger.debug(
      'Stopping timer - Current remaining: $_remainingSeconds, Elapsed: $_totalElapsedSeconds',
    );
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() {
        _isTimerActive = false;
      });
    }
    _pulseController.stop();
  }

  void _resetTimer() {
    if (!mounted) return;
    Logger.debug('Resetting timer');
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() {
        _remainingSeconds = _testDurationSeconds;
        _totalElapsedSeconds = 0;
        _isTimerActive = false;
        _isTimerComplete = false;
      });
    }
    _progressController.reset();
    _pulseController.stop();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
