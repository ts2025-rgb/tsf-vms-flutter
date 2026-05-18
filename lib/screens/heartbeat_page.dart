import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../services/heartbeat_service.dart';
import '../models/heartbeat_entry.dart';
import '../widgets/heartbeat_dialog.dart';

class HeartbeatPage extends StatefulWidget {
  final String programId;
  const HeartbeatPage({super.key, required this.programId});

  @override
  State<HeartbeatPage> createState() => _HeartbeatPageState();
}

class _HeartbeatPageState extends State<HeartbeatPage> {
  final HeartbeatService _service = HeartbeatService();
  List<HeartbeatEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    setState(() => _loading = true);
    final entries = await _service.getMyEntries();
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _openCreateDialog() async {
    await showHeartbeatDialog(context, (hours, activity, detail) async {
      final ok = await _service.createEntry(
        hours: hours,
        activityType: activity,
        activityDetail: detail,
      );
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Entry saved'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        await _fetchEntries();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save entry'),
            backgroundColor: AppColors.accentOrange,
          ),
        );
      }
    });
  }

  Future<void> _deleteEntry(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text(
              'Confirm delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            content: Text('Delete this entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(c).pop(true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.accentOrange),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final ok = await _service.deleteEntry(id);
      if (ok) {
        await _fetchEntries();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed'),
            backgroundColor: AppColors.accentOrange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Heartbeat Helpers',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _openCreateDialog,
      ),
      body:
          _loading
              ? Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              )
              : Padding(
                padding: const EdgeInsets.all(12.0),
                child:
                    _entries.isEmpty
                        ? Center(
                          child: Text(
                            'No entries yet. Tap + to add.',
                            style: GoogleFonts.poppins(),
                          ),
                        )
                        : ListView.separated(
                          itemCount: _entries.length,
                          separatorBuilder:
                              (_, __) => Divider(color: AppColors.divider),
                          itemBuilder: (context, i) {
                            final e = _entries[i];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  '${e.activityType} — ${e.hours} hr(s)',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle:
                                    e.activityDetail != null &&
                                            e.activityDetail!.isNotEmpty
                                        ? Text(
                                          e.activityDetail!,
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade700,
                                          ),
                                        )
                                        : null,
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: AppColors.accentOrange,
                                  ),
                                  onPressed: () => _deleteEntry(e.id),
                                ),
                              ),
                            );
                          },
                        ),
              ),
    );
  }
}
