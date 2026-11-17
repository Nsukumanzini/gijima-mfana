import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/commerce.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(commerceProvider).notifications;
    return Scaffold(
        appBar: AppBar(title: const AppText('Notifications'), actions: [
          TextButton(
              onPressed: () => ref.read(commerceProvider.notifier).readAll(),
              child: const AppText('Mark all read'))
        ]),
        body: notes.isEmpty
            ? const Center(
                child: AppText(
                    'No updates yet. Order and request updates appear here.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: notes
                    .map((n) => Card(
                        child: ListTile(
                            leading: Icon(n['read'] == true
                                ? Icons.mark_email_read_outlined
                                : Icons.mark_email_unread_outlined),
                            title: AppText(n['text'] as String),
                            subtitle: AppText(n['time'] as String),
                            onTap: () {
                              ref
                                  .read(commerceProvider.notifier)
                                  .readNotification(n['id'] as String);
                              context.push(n['route'] as String);
                            })))
                    .toList()));
  }
}
