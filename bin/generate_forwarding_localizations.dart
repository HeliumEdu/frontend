// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

/// Writes lib/utils/forwarding_localizations.dart: for each package
/// localizations interface Helium customizes, an abstract class that forwards
/// every member to a wrapped `base` instance, so Helium's subclasses override
/// only what they change.
///
/// The interfaces are read with package:analyzer from the resolved package
/// config, so the output follows the locked package versions. Members are
/// emitted in alphabetical order and the result is run through `dart format`
/// with the Dart SDK running this script.
///
/// Usage: dart bin/generate_forwarding_localizations.dart [output path]
const _outputPath = 'lib/utils/forwarding_localizations.dart';

const _literalDefault = r"^(true|false|null|-?\d+(\.\d+)?|'[^'\\$]*')$";

const _targets = [
  _ForwardingTarget(
    library: 'package:flutter/material.dart',
    interface: 'MaterialLocalizations',
    className: 'ForwardingMaterialLocalizations',
    doc: [
      '[MaterialLocalizations] that answer every member from [base], so a',
      'subclass overrides only what it changes for any locale.',
    ],
  ),
  _ForwardingTarget(
    library: 'package:syncfusion_flutter_core/localizations.dart',
    interface: 'SfLocalizations',
    className: 'ForwardingSfLocalizations',
    doc: [
      '[SfLocalizations] that answer every label from [base], so a subclass',
      'overrides only what it changes for any locale.',
    ],
  ),
  _ForwardingTarget(
    library: 'package:flutter_quill/flutter_quill.dart',
    interface: 'FlutterQuillLocalizations',
    className: 'ForwardingQuillLocalizations',
    superInitializer: 'super(base.localeName)',
    doc: [
      '[FlutterQuillLocalizations] that answer every label from [base], so a',
      'subclass overrides only what it changes for any locale.',
    ],
  ),
];

Future<void> main(List<String> args) async {
  final outputPath = args.isNotEmpty ? args.first : _outputPath;
  try {
    final source = await _generate();
    File(outputPath).writeAsStringSync(await _format(source));
  } on ForwardingGenerationException catch (e) {
    stderr.writeln('generate_forwarding_localizations: ${e.message}');
    exit(1);
  }
}

class ForwardingGenerationException implements Exception {
  final String message;

  ForwardingGenerationException(this.message);

  @override
  String toString() => message;
}

class _ForwardingTarget {
  final String library;
  final String interface;
  final String className;
  final String? superInitializer;
  final List<String> doc;

  const _ForwardingTarget({
    required this.library,
    required this.interface,
    required this.className,
    required this.doc,
    this.superInitializer,
  });
}

class _ImportScope {
  final List<LibraryElement> libraries;

  _ImportScope(this.libraries);

  void requireVisible(Element element) {
    final name = element.name;
    final visible = {
      for (final library in libraries) ?library.exportNamespace.get2(name!),
    };
    if (visible.length == 1 && visible.single == element) {
      return;
    }
    final declaredIn = element.library?.uri;
    throw ForwardingGenerationException(
      visible.isEmpty
          ? '$name (from $declaredIn) is not exported by the imported libraries'
          : '$name (from $declaredIn) is ambiguous or shadowed across the '
                'imported libraries',
    );
  }
}

Future<String> _generate() async {
  final root = Directory.current.absolute.path;
  final session = AnalysisContextCollection(
    includedPaths: [root],
  ).contextFor('$root/pubspec.yaml').currentSession;

  final libraries = <String, LibraryElement>{};
  for (final uri in ['dart:core', ..._targets.map((t) => t.library)]) {
    libraries[uri] = await _resolveLibrary(session, uri);
  }
  final scope = _ImportScope(libraries.values.toList());

  final classes = [
    for (final target in _targets)
      _renderClass(
        target,
        _lookUpInterface(libraries[target.library]!, target),
        scope,
      ),
  ];
  final imports = (_targets.map((t) => t.library).toSet().toList()..sort())
      .map((uri) => "import '$uri';")
      .join('\n');
  final deprecated = classes.any((c) => c.usesDeprecated);

  return [
    '// AUTO-GENERATED — DO NOT EDIT.',
    '// Written from the package localizations interfaces by:',
    '//   frontend/bin/generate_forwarding_localizations.dart',
    if (deprecated) ...['', '// ignore_for_file: deprecated_member_use'],
    '',
    imports,
    '',
    classes.map((c) => c.source).join('\n\n'),
    '',
  ].join('\n');
}

Future<LibraryElement> _resolveLibrary(
  AnalysisSession session,
  String uri,
) async {
  final result = await session.getLibraryByUri(uri);
  if (result is! LibraryElementResult) {
    throw ForwardingGenerationException(
      'could not resolve $uri (${result.runtimeType}); run flutter pub get',
    );
  }
  return result.element;
}

InterfaceElement _lookUpInterface(
  LibraryElement library,
  _ForwardingTarget target,
) {
  final element = library.exportNamespace.get2(target.interface);
  if (element is! InterfaceElement) {
    throw ForwardingGenerationException(
      '${target.interface} is not a class exported by ${target.library}',
    );
  }
  return element;
}

({String source, bool usesDeprecated}) _renderClass(
  _ForwardingTarget target,
  InterfaceElement interface,
  _ImportScope scope,
) {
  final members =
      interface.interfaceMembers.values
          .where((member) => !_isObjectMember(member))
          .where(
            (member) => target.superInitializer == null || member.isAbstract,
          )
          .toList()
        ..sort((a, b) => a.lookupName!.compareTo(b.lookupName!));
  if (members.isEmpty) {
    throw ForwardingGenerationException(
      '${target.interface} has no members to forward',
    );
  }

  final name = target.interface;
  final superInitializer = target.superInitializer;
  final header = superInitializer != null
      ? [
          'abstract class ${target.className} extends $name {',
          '  final $name base;',
          '',
          '  ${target.className}(this.base) : $superInitializer;',
        ]
      : [
          'abstract class ${target.className} implements $name {',
          '  final $name base;',
          '',
          '  const ${target.className}(this.base);',
        ];

  return (
    source: [
      ...target.doc.map((line) => '/// $line'),
      ...header,
      for (final member in members) ...['', _renderMember(member, scope)],
      '}',
    ].join('\n'),
    usesDeprecated: members.any(_isDeprecated),
  );
}

bool _isObjectMember(ExecutableElement member) {
  final owner = member.enclosingElement;
  return owner is ClassElement && owner.isDartCoreObject;
}

bool _isDeprecated(ExecutableElement member) =>
    member.metadata.hasDeprecated ||
    (member is PropertyAccessorElement &&
        member.variable.metadata.hasDeprecated);

String _renderMember(ExecutableElement member, _ImportScope scope) {
  final name = member.name!;
  final returnType = _renderType(member.returnType, scope);
  final parameters = member.formalParameters;

  final String signature;
  final String body;
  if (member is GetterElement) {
    signature = '$returnType get $name';
    body = 'base.$name';
  } else if (member is MethodElement &&
      !member.isOperator &&
      member.typeParameters.isEmpty) {
    signature = '$returnType $name${_renderParameters(parameters, scope)}';
    body = 'base.$name${_renderArguments(parameters)}';
  } else {
    throw ForwardingGenerationException(
      'unsupported member kind ${member.runtimeType} for $name',
    );
  }
  return '  @override\n  $signature => $body;';
}

String _renderParameters(
  List<FormalParameterElement> parameters,
  _ImportScope scope,
) {
  final required = <String>[];
  final optional = <String>[];
  final named = <String>[];
  for (final parameter in parameters) {
    final name = parameter.name;
    final declaration =
        [_renderType(parameter.type, scope), ?name].join(' ') +
        _renderDefault(parameter);
    if (parameter.isNamed) {
      named.add(
        parameter.isRequiredNamed ? 'required $declaration' : declaration,
      );
    } else if (parameter.isOptionalPositional) {
      optional.add(declaration);
    } else {
      required.add(declaration);
    }
  }
  return '(${[...required, if (optional.isNotEmpty) '[${optional.join(', ')}]', if (named.isNotEmpty) '{${named.join(', ')}}'].join(', ')})';
}

String _renderDefault(FormalParameterElement parameter) {
  final code = parameter.defaultValueCode;
  if (code == null) {
    return '';
  }
  if (!RegExp(_literalDefault).hasMatch(code)) {
    throw ForwardingGenerationException(
      'default value `$code` of ${parameter.enclosingElement?.name}.${parameter.name} is not a literal',
    );
  }
  return ' = $code';
}

String _renderArguments(List<FormalParameterElement> parameters) {
  final arguments = parameters.map(
    (p) => p.isNamed ? '${p.name}: ${p.name}' : p.name!,
  );
  return '(${arguments.join(', ')})';
}

String _renderType(DartType type, _ImportScope scope) {
  final suffix = type.nullabilitySuffix == NullabilitySuffix.question
      ? '?'
      : '';
  final alias = type.alias;
  if (alias != null) {
    scope.requireVisible(alias.element);
    return '${alias.element.name}${_renderTypeArguments(alias.typeArguments, scope)}$suffix';
  }
  return switch (type) {
    DynamicType() => 'dynamic',
    VoidType() => 'void',
    NeverType() => 'Never$suffix',
    InterfaceType() => _renderInterfaceType(type, scope) + suffix,
    _ => throw ForwardingGenerationException(
      'unsupported type ${type.runtimeType}: $type',
    ),
  };
}

String _renderInterfaceType(InterfaceType type, _ImportScope scope) {
  scope.requireVisible(type.element);
  return '${type.element.name}${_renderTypeArguments(type.typeArguments, scope)}';
}

String _renderTypeArguments(List<DartType> typeArguments, _ImportScope scope) =>
    typeArguments.isEmpty
    ? ''
    : '<${typeArguments.map((t) => _renderType(t, scope)).join(', ')}>';

Future<String> _format(String source) async {
  final process = await Process.start(Platform.resolvedExecutable, [
    'format',
    '--stdin-name=$_outputPath',
  ]);
  process.stdin.write(source);
  await process.stdin.close();
  final formatted = process.stdout.transform(utf8.decoder).join();
  final errors = process.stderr.transform(utf8.decoder).join();
  if (await process.exitCode != 0) {
    throw ForwardingGenerationException('dart format failed:\n${await errors}');
  }
  return formatted;
}
