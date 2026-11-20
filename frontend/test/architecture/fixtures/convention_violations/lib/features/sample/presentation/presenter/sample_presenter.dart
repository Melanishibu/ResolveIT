// Deliberately broken sample (AB#175): a presenter that reaches its own feature's data layer.
// It lives under test/ only, never under lib/, and proves the import-boundary check fails on it.
// ignore: uri_does_not_exist
import 'package:resolveit/features/sample/data/repository/sample_repository_impl.dart';

// ignore: undefined_class
typedef SamplePresenterSource = SampleRepositoryImpl;
