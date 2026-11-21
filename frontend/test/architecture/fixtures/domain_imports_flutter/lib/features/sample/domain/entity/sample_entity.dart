// Deliberately broken sample (AB#11): a domain file that imports Flutter.
// It lives under test/ only, never under lib/, and proves the import-boundary check fails on it.
import 'package:flutter/widgets.dart';

typedef SampleEntityView = Widget;
