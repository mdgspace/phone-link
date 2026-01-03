import 'package:flutter/material.dart';

void showPermissionsSheet(BuildContext context) {
  final List<PermissionItem> permissions = [
    PermissionItem(
      name: "SMS",
      description: "Read and send SMS messages",
      enabled: true,
    ),
    PermissionItem(
      name: "Clipboard Sharing",
      description: "Sync clipboard between devices",
    ),
    PermissionItem(
      name: "File Sharing",
      description: "Send and receive files",
    ),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (context, scrollController) {
          return Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Column(
              children: [
                // ───── drag handle ─────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const Text(
                  "Permissions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 3),

                // ───── permissions list ─────
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: permissions.length,
                    itemBuilder: (context, index) {
                      return permissionTile(permissions[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class PermissionItem {
  final String name;
  final String description;
  bool enabled;

  PermissionItem({
    required this.name,
    required this.description,
    this.enabled = false,
  });
}

Widget permissionTile(PermissionItem item) {
  return StatefulBuilder(
    builder: (context, setState) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(item.name),
            subtitle: Text(item.description),
            trailing: Switch(
              value: item.enabled,
              onChanged: (value) {
                setState(() {
                  item.enabled = value;
                });
              },
            ),
          ),
        ),
      );
    },
  );
}
