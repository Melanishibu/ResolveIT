// Deliberately broken sample (AB#175): a use case that imports Dio.
// It lives under test/ only, never under lib/, and proves the import-boundary check fails on it.
import 'package:dio/dio.dart';

typedef SampleUseCaseClient = Dio;
