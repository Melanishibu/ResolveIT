// Deliberately broken sample (AB#170): a feature view that uses a raw Material button instead of
// AppButton. It lives under test/ only, never under lib/, and proves the guard test fails on it.
import 'package:flutter/material.dart';

class SampleView extends StatelessWidget {
  const SampleView({super.key});

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: () {}, child: const Text('Save'));
}
