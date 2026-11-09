import 'package:flutter/material.dart';

class NotePreview extends StatelessWidget {
  const NotePreview({required this.text, super.key});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final note = text?.trim();
    if (note == null || note.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.note_outlined,
            size: 17,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
