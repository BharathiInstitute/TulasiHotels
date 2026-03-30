/// Staff messaging / announcements screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/staff/providers/message_provider.dart';
import 'package:tulasihotels/features/staff/services/message_service.dart';
import 'package:tulasihotels/models/message_model.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(recentMessagesProvider);


    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMessageForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Message'),
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (messages) {
          if (messages.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(msg.isBroadcast
                        ? Icons.campaign
                        : Icons.message),
                  ),
                  title: Text(msg.senderName),
                  subtitle: Text(msg.content),
                  trailing: msg.isBroadcast
                      ? const Chip(label: Text('📢'))
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMessageForm(BuildContext context) {
    final contentCtrl = TextEditingController();
    var isBroadcast = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('New Message',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Broadcast'),
                    subtitle: const Text('Visible to all staff'),
                    value: isBroadcast,
                    onChanged: (val) =>
                        setModalState(() => isBroadcast = val),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (contentCtrl.text.isEmpty) return;
                      final msg = MessageModel(
                        id: generateSafeId('msg'),
                        senderId: '',
                        senderName: 'Manager',
                        content: contentCtrl.text.trim(),
                        isBroadcast: isBroadcast,
                        createdAt: DateTime.now(),
                      );
                      MessageService.sendMessage(msg);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Send'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
