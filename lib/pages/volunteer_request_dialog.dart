// New file: lib/widgets/volunteer_request_dialog.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VolunteerRequestDialog extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final String requestId;

  const VolunteerRequestDialog({
    super.key,
    required this.requestData,
    required this.requestId,
  });

  @override
  State<VolunteerRequestDialog> createState() => _VolunteerRequestDialogState();
}

class _VolunteerRequestDialogState extends State<VolunteerRequestDialog> {
  late Timer _timer;
  int _timeLeft = 300; // 5 minutes in seconds

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _handleResponse(false);
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleResponse(bool accepted) async {
    _timer.cancel();
    await FirebaseFirestore.instance
        .collection('volunteerRequests')
        .doc(widget.requestId)
        .update({
          'status': accepted ? 'accepted' : 'declined',
          'responseTime': FieldValue.serverTimestamp(),
        });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Shelter Request'),
          Text('${(_timeLeft / 60).floor()}:${(_timeLeft % 60).toString().padLeft(2, '0')}'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Requester: ${widget.requestData['requesterName']}'),
          Text('Contact: ${widget.requestData['requesterContact']}'),
          Text('Distance: ${widget.requestData['distance'].toStringAsFixed(2)} km'),
          Text('From: ${widget.requestData['donorAddress']}'),
          Text('To: ${widget.requestData['requesterAddress']}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _handleResponse(false),
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () => _handleResponse(true),
          child: const Text('Accept'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}