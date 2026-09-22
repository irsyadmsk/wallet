import 'package:flutter/material.dart';

import '../../../../core.dart';

Widget FloatingAction({required Function onPressed}) {
  return FloatingActionButton(
    heroTag: UniqueKey(),
    onPressed: () async {
      if (await isTapProtected()) return;
      onPressed();
    },
    child: const Icon(Icons.add),
  );
}
