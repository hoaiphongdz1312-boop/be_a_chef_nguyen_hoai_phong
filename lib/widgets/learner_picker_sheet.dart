import 'package:flutter/material.dart';

import '../data/models/learner.dart';

/// Bảng chọn học viên thủ công. Trả về học viên được chọn hoặc `null`.
Future<Learner?> showLearnerPicker(BuildContext context, List<Learner> learners) {
  return showModalBottomSheet<Learner>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn là ai?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: learners.length,
                itemBuilder: (context, i) {
                  final learner = learners[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(learner.name.characters.first.toUpperCase()),
                    ),
                    title: Text(learner.name),
                    onTap: () => Navigator.of(context).pop(learner),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
