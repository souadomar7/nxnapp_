import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _push = true;
  bool _email = true;
  bool _sms = false;
  bool _marketing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationSettingsTitle, style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            activeTrackColor: AppColors.bluePrimary,
            title: Text(AppLocalizations.of(context)!.pushNotificationsLabel),
            value: _push,
            onChanged: (val) => setState(() => _push = val),
          ),
          const Divider(),
          SwitchListTile(
            activeTrackColor: AppColors.bluePrimary,
            title: Text(AppLocalizations.of(context)!.emailNotificationsLabel),
            value: _email,
            onChanged: (val) => setState(() => _email = val),
          ),
          const Divider(),
          SwitchListTile(
            activeTrackColor: AppColors.bluePrimary,
            title: Text(AppLocalizations.of(context)!.smsNotificationsLabel),
            value: _sms,
            onChanged: (val) => setState(() => _sms = val),
          ),
          const Divider(),
          SwitchListTile(
            activeTrackColor: AppColors.bluePrimary,
            title: Text(AppLocalizations.of(context)!.marketingUpdatesLabel),
            value: _marketing,
            onChanged: (val) => setState(() => _marketing = val),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: AppLocalizations.of(context)!.saveChangesButton,
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
            },
          ),
        ],
      ),
    );
  }
}
