import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

// Match BookingPage colors
class ReceiveColors {
  static const primary = Color(0xFF0057FF); // Vibrant Blue
  static const background = Color(0xFFF3F6FB); // Light Grey-Blue
  static const textDark = Color(0xFF1A1F36); // Dark user text
  static const cardBorder = Color(0xFFE0E6F2);
}

class ReceiveGoodsStagePageEN extends StatefulWidget {
  const ReceiveGoodsStagePageEN({super.key});

  @override
  State<ReceiveGoodsStagePageEN> createState() =>
      _ReceiveGoodsStagePageENState();
}

class _ReceiveGoodsStagePageENState extends State<ReceiveGoodsStagePageEN> {
  // 1) Schedule (drop-off only)
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  // 2) Preparation
  String? _bay;
  bool _isPrepared = false;

  // 3) Inspection / extra services
  bool _damagePhotosByAdmin = false; // document damages with photos


  // 4) Instant update
  String? _storageNo;
  String? _stockStatus;
  bool _isUpdated = false;

  final _bays = const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  final TextEditingController _notesCtrl = TextEditingController();

  // ---------- helpers ----------
  void _toast(String msg, {String? undoLabel, VoidCallback? onUndo}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: (undoLabel != null && onUndo != null)
            ? SnackBarAction(label: undoLabel, onPressed: onUndo)
            : null,
      ),
    );
  }

  String _fmtDateTime(DateTime d, TimeOfDay? t) {
    if (t == null) return "${d.day}/${d.month}/${d.year}";
    final hh =
    (t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod).toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return "${d.day}/${d.month}/${d.year}  $hh:$mm $ampm";
  }

  double _progress() {
    int done = 0;
    if (_scheduledDate != null && _scheduledTime != null) done++; // Schedule
    if (_isPrepared) done++; // Preparation
    if (_isUpdated) done++; // Update
    return done / 3.0;
  }

  // =========================================================
  // LOGIC METHODS
  // =========================================================
  Future<void> _scheduleAppointmentPicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: ReceiveColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: 'Select drop-off time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: ReceiveColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime == null) return;

    _applySchedule(pickedDate, pickedTime);
  }

  void _quickSchedule(Duration offset, {int hour = 10, int minute = 0}) {
    final now = DateTime.now();
    final d = (offset == Duration.zero)
        ? now.add(const Duration(hours: 2))
        : now.add(offset);
    final date = DateTime(d.year, d.month, d.day);
    final time = (offset == Duration.zero)
        ? TimeOfDay(hour: d.hour, minute: d.minute)
        : TimeOfDay(hour: hour, minute: minute);
    _applySchedule(date, time);
  }

  void _applySchedule(DateTime date, TimeOfDay time) {
    final old = (_scheduledDate, _scheduledTime);
    setState(() {
      _scheduledDate = date;
      _scheduledTime = time;
      // reset following stages
      _isPrepared = false;
      _isUpdated = false;
      _bay = null;
      _damagePhotosByAdmin = false;
      _notesCtrl.clear();
      _storageNo = null;
      _stockStatus = 'Pending';
    });
    if (!mounted) return;
    _toast(
      AppLocalizations.of(context)!.scheduleDropoffSubtitleScheduled(_fmtDateTime(date, time)),
      undoLabel: 'Undo',
      onUndo: () {
        setState(() {
          _scheduledDate = old.$1;
          _scheduledTime = old.$2;
        });
      },
    );
  }

  void _prepareWarehouse() {
    if (_scheduledDate == null || _scheduledTime == null) {
      _toast("Please schedule the drop-off time first.");
      return;
    }
    if (_bay == null) {
      _toast('Select a bay first.');
      return;
    }

    setState(() => _isPrepared = true);

    _toast(
      AppLocalizations.of(context)!.prepareBaySubtitlePrepared(
        _bay!,
        AppLocalizations.of(context)!.storageModelValue,
      ),
      undoLabel: 'Undo',
      onUndo: () => setState(() => _isPrepared = false),
    );
  }

  Future<void> _updateSystemInstantly() async {
    if (!_isPrepared) {
      _toast("Prepare warehouse first.");
      return;
    }

    final prev = (_storageNo, _stockStatus, _isUpdated);
    final stamp = DateTime.now().millisecondsSinceEpoch % 1000000;

    setState(() {
      _storageNo = "STO-$stamp";
      _stockStatus = 'Received & Stored';
      _isUpdated = true;
    });

    _toast("Updated. Storage # $_storageNo", undoLabel: 'Undo', onUndo: () {
      setState(() {
        _storageNo = prev.$1;
        _stockStatus = prev.$2 ?? 'Pending';
        _isUpdated = prev.$3;
      });
    });

    // Navigate to completion
    if (_storageNo != null && _scheduledDate != null && _scheduledTime != null) {
      // scheduledAt removed


      // Delay slightly for effect
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Basic context data
    final pct = _progress();
    // final isAr = Localizations.localeOf(context).languageCode == 'ar'; // Unused in this snippet but good to have

    return Scaffold(
      backgroundColor: ReceiveColors.background,
      body: CustomScrollView(
        slivers: [
          // 1. Sliver App Bar (Scrollable Header)
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: ReceiveColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "NXN",
                            style: TextStyle(
                              color: ReceiveColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppLocalizations.of(context)!.receiveGoodsTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.processInfo,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: ReceiveColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0, -20, 0), // Overlap effect
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
              child: Column(
                children: [
                  // Progress Indicator
                  _buildProgressCard(pct),
                  const SizedBox(height: 24),

                  // Step 1: Schedule
                  _buildSectionHeader("01", AppLocalizations.of(context)!.scheduleDropoffTitle),
                  const SizedBox(height: 12),
                  _ActionCard(
                    isActive: true,
                    isDone: _scheduledDate != null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_scheduledDate == null)
                              ? AppLocalizations.of(context)!.scheduleDropoffSubtitle
                              : AppLocalizations.of(context)!.scheduleDropoffSubtitleScheduled(_fmtDateTime(_scheduledDate!, _scheduledTime)),
                          style: TextStyle(color: Colors.grey[600], height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _pillButton(
                              AppLocalizations.of(context)!.nowPlus2h,
                              onTap: () => _quickSchedule(Duration.zero),
                            ),
                            _pillButton(
                              AppLocalizations.of(context)!.tomorrow10am,
                              onTap: () => _quickSchedule(const Duration(days: 1), hour: 10),
                            ),
                            _solidButton(
                              AppLocalizations.of(context)!.chooseDateTime,
                              color: ReceiveColors.primary,
                              textColor: Colors.white,
                              onPressed: _scheduleAppointmentPicker,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Step 2: Prepare
                  _buildSectionHeader("02", AppLocalizations.of(context)!.prepareBayTitle),
                  const SizedBox(height: 12),
                  _ActionCard(
                    isActive: _scheduledDate != null,
                    isDone: _isPrepared,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_scheduledDate == null)
                          Text("Please schedule drop-off first.", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic))
                        else ...[
                          Text(
                            AppLocalizations.of(context)!.assignBayLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: ReceiveColors.textDark),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _bays.map((b) {
                              final sel = _bay == b;
                              return ChoiceChip(
                                label: Text(b),
                                selected: sel,
                                onSelected: (_) => setState(() => _bay = b),
                                selectedColor: ReceiveColors.primary,
                                labelStyle: TextStyle(color: sel ? Colors.white : Colors.grey[700]),
                                backgroundColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: _solidButton(
                              _isPrepared ? AppLocalizations.of(context)!.preparedButton : AppLocalizations.of(context)!.confirmPreparationButton,
                              color: _isPrepared ? Colors.green : ReceiveColors.primary,
                              textColor: Colors.white,
                              onPressed: _isPrepared ? null : _prepareWarehouse,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Step 3: Inspect & Update
                  _buildSectionHeader("03", AppLocalizations.of(context)!.inspectionPhotosTitle),
                  const SizedBox(height: 12),
                  _ActionCard(
                    isActive: _isPrepared,
                    isDone: _isUpdated,
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         if (!_isPrepared)
                            Text("Prepare warehouse first.", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic))
                         else ...[
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              activeTrackColor: ReceiveColors.primary,
                              title: Text(AppLocalizations.of(context)!.adminDocumentPhotos, style: const TextStyle(fontSize: 14)),
                              value: _damagePhotosByAdmin,
                              onChanged: (v) => setState(() => _damagePhotosByAdmin = v),
                            ),
                            const Divider(),
                            TextField(
                              controller: _notesCtrl,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.notesAdminLabel,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isUpdated ? null : _updateSystemInstantly,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ReceiveColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(_isUpdated ? "All Done" : AppLocalizations.of(context)!.updateNowButton, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                         ]
                       ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI Components matching BookingPage style

  Widget _buildProgressCard(double pct) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progress",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                "${(pct * 100).toInt()}%",
                style: const TextStyle(color: ReceiveColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: const AlwaysStoppedAnimation(ReceiveColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String number, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ReceiveColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            number,
            style: const TextStyle(color: ReceiveColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ReceiveColors.textDark),
        ),
      ],
    );
  }

  Widget _pillButton(String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: ReceiveColors.primary),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Text(text, style: const TextStyle(color: ReceiveColors.primary, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _solidButton(String text, {required Color color, required Color textColor, VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(text),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final Widget child;
  final bool isActive;
  final bool isDone;

  const _ActionCard({required this.child, this.isActive = true, this.isDone = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: isDone
            ? Border.all(color: Colors.green.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: ReceiveColors.cardBorder),
        boxShadow: isActive
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))]
            : [],
      ),
      child: Stack(
        children: [
          child,
          if (isDone)
            const Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
        ],
      ),
    );
  }
}
