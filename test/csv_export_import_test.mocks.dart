// Mocks generated by Mockito 5.1.0 from annotations
// in track_my_indoor_exercise/test/csv_export_import_test.dart.
// Do not manually edit this file.

import 'package:mockito/mockito.dart' as _i1;
import 'package:package_info_plus/package_info_plus.dart' as _i2;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types

/// A class which mocks [PackageInfo].
///
/// See the documentation for Mockito's code generation for more information.
class MockPackageInfo extends _i1.Mock implements _i2.PackageInfo {
  MockPackageInfo() {
    _i1.throwOnMissingStub(this);
  }

  @override
  String get appName =>
      (super.noSuchMethod(Invocation.getter(#appName), returnValue: '')
          as String);
  @override
  String get packageName =>
      (super.noSuchMethod(Invocation.getter(#packageName), returnValue: '')
          as String);
  @override
  String get version =>
      (super.noSuchMethod(Invocation.getter(#version), returnValue: '')
          as String);
  @override
  String get buildNumber =>
      (super.noSuchMethod(Invocation.getter(#buildNumber), returnValue: '')
          as String);
  @override
  String get buildSignature =>
      (super.noSuchMethod(Invocation.getter(#buildSignature), returnValue: '')
          as String);
}
