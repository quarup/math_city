import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_category.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/domain/questions/answer_check.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/question_source.dart';
import 'package:math_city/presentation/question/question_screen.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';

/// Loopback port the harness listens on. Reach it from the host with
/// `adb forward tcp:8081 tcp:8081`.
const int kDebugHarnessPort = 8081;

/// A **kDebugMode-only** HTTP control port that lets an external driver
/// (see `tools/ux_sweep/uxctl.py`) walk every implemented concept without
/// screenshotting its way through the UI.
///
/// It exists because a screenshot-and-tap sweep over ~360 concepts costs
/// ~7 screenshots each and forces the driver to *solve* each question by
/// reading pixels — which produces false bug reports whenever it gets the
/// maths wrong. This port hands back the correct answer, a reproducible
/// seed, and any framework errors raised while the screen rendered.
///
/// Never started outside `kDebugMode`; `main()` is the only caller of
/// [start].
///
/// ## Endpoints
///
/// - `GET  /ping` — liveness + whether the home screen has mounted.
/// - `GET  /concepts` — every implemented concept, grouped by category in
///   curriculum.md order.
/// - `POST /open` `{conceptId, band, seed, settleMs}` — resets the
///   navigator to the root route and pushes a question. Returns the full
///   question snapshot, including [GeneratedQuestion.correctAnswer].
/// - `POST /answer` `{correct, settleMs}` — submits the right answer or a
///   distractor through the real submit path. Returns the outcome.
/// - `POST /back` — pops back to the root route.
class DebugHarness {
  DebugHarness._();

  static final DebugHarness instance = DebugHarness._();

  /// Wired into `MaterialApp.navigatorKey` so the harness can drive
  /// navigation from outside the widget tree.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  HttpServer? _server;
  bool _homeReady = false;

  /// Framework errors captured since the last request drained them.
  final List<String> _errors = <String>[];

  _AttachedQuestion? _question;
  _AttachedResult? _result;

  bool get _enabled => _server != null;

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------

  Future<void> start() async {
    if (!kDebugMode || _server != null) return;
    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        kDebugHarnessPort,
      );
    } on SocketException catch (e) {
      debugPrint('[debug-harness] could not bind $kDebugHarnessPort: $e');
      return;
    }
    _installErrorCapture();
    debugPrint('[debug-harness] listening on 127.0.0.1:$kDebugHarnessPort');
    unawaited(_serve());
  }

  /// Route framework errors into [_errors] as well as the normal console.
  /// Overflow banners and build exceptions are the single largest bug
  /// class in a diagram-heavy app, and catching them here means the
  /// driver gets them as data instead of having to spot red-and-yellow
  /// stripes in a screenshot.
  void _installErrorCapture() {
    final prior = FlutterError.onError;
    FlutterError.onError = (details) {
      _errors.add(details.exceptionAsString());
      prior?.call(details);
    };
  }

  Future<void> _serve() async {
    final server = _server;
    if (server == null) return;
    await for (final request in server) {
      try {
        await _handle(request);
      } on Object catch (e, st) {
        _writeJson(request, <String, Object?>{
          'ok': false,
          'error': '$e',
          'stack': '$st',
        }, status: 500);
      }
    }
  }

  // ---------------------------------------------------------------------
  // Hooks called from the widget tree
  // ---------------------------------------------------------------------

  /// Called by `HomeScreen.initState`. The splash screen replaces itself
  /// with the home screen ~1.5 s after launch; opening a question before
  /// that lands would be clobbered by the replacement.
  void markHomeReady() {
    if (kDebugMode) _homeReady = true;
  }

  /// Called by `QuestionScreen` once its question has been generated.
  ///
  /// Deliberately never cleared on dispose: `pushReplacement` to the
  /// result screen disposes the question screen, and the driver still
  /// needs the question it just answered.
  void attachQuestion({
    required GeneratedQuestion question,
    required List<String> displayedChoices,
    required bool usesKeypad,
    required ValueChanged<String> submit,
  }) {
    if (!_enabled) return;
    _question = _AttachedQuestion(
      question: question,
      displayedChoices: List<String>.unmodifiable(displayedChoices),
      usesKeypad: usesKeypad,
      submit: submit,
    );
  }

  /// Called by `ResultScreen.initState`.
  void attachResult({required AnswerOutcome outcome}) {
    if (!_enabled) return;
    _result = _AttachedResult(outcome: outcome);
  }

  // ---------------------------------------------------------------------
  // Request routing
  // ---------------------------------------------------------------------

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    final body = await _readJsonBody(request);

    switch (path) {
      case '/ping':
        _writeJson(request, <String, Object?>{
          'ok': true,
          'homeReady': _homeReady,
          'errors': _drainErrors(),
        });
      case '/concepts':
        _writeJson(request, <String, Object?>{
          'ok': true,
          'categories': await _conceptCatalog(),
        });
      case '/open':
        _writeJson(request, await _open(body));
      case '/answer':
        _writeJson(request, await _answer(body));
      case '/back':
        navigatorKey.currentState?.popUntil((r) => r.isFirst);
        _question = null;
        _result = null;
        _writeJson(request, <String, Object?>{
          'ok': true,
          'errors': _drainErrors(),
        });
      default:
        _writeJson(request, <String, Object?>{
          'ok': false,
          'error': 'unknown path "$path"',
        }, status: 404);
    }
  }

  // ---------------------------------------------------------------------
  // /concepts
  // ---------------------------------------------------------------------

  /// The container lives above `MaterialApp`, so the navigator's context
  /// can reach it. Read lazily — it doesn't exist until the first frame.
  ProviderContainer? get _container {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return null;
    return ProviderScope.containerOf(ctx, listen: false);
  }

  /// Uses [QuestionSource.implementedConceptIds] — the union of the
  /// generator registry *and* the bundled dataset pool — rather than the
  /// registry alone. Four concepts (`closest_to_target`,
  /// `function_evaluate_at_point`, `kth_value_in_list`, `sort_rationals`)
  /// are dataset-only, and listing just the registry would silently drop
  /// them from every sweep.
  Future<List<Map<String, Object?>>> _conceptCatalog() async {
    final container = _container;
    if (container == null) return <Map<String, Object?>>[];
    final source = await container.read(questionSourceProvider.future);
    final implemented = source.implementedConceptIds.toSet();

    final byCategory = <String, List<Concept>>{};
    for (final c in allConcepts) {
      if (!implemented.contains(c.id)) continue;
      byCategory.putIfAbsent(c.categoryId, () => <Concept>[]).add(c);
    }
    for (final list in byCategory.values) {
      list.sort(
        (a, b) => a.categoryRowOrder.compareTo(b.categoryRowOrder),
      );
    }

    final categories = allCategories.toList()
      ..sort(
        (a, b) => a.displayOrder.compareTo(b.displayOrder),
      );

    return <Map<String, Object?>>[
      for (final cat in categories)
        if (byCategory[cat.id] != null)
          <String, Object?>{
            'id': cat.id,
            'name': cat.displayName,
            'order': cat.displayOrder,
            // curriculum.md numbers its sub-concept sections 3.1 … 3.12 in
            // displayOrder sequence.
            'section': '3.${cat.displayOrder + 1}',
            'concepts': <Map<String, Object?>>[
              for (final c in byCategory[cat.id]!)
                <String, Object?>{
                  'id': c.id,
                  'name': c.name,
                  'grade': c.primaryGrade,
                  'row': c.categoryRowOrder,
                  // Non-zero means some questions for this concept come
                  // from the bundled dataset rather than a generator, so
                  // one probe may not be representative.
                  'datasetPool': source.datasetPoolSize(c.id),
                },
            ],
          },
    ];
  }

  // ---------------------------------------------------------------------
  // /open
  // ---------------------------------------------------------------------

  Future<Map<String, Object?>> _open(Map<String, Object?> body) async {
    final conceptId = body['conceptId'] as String?;
    if (conceptId == null) {
      return <String, Object?>{'ok': false, 'error': 'conceptId is required'};
    }
    final bandName = (body['band'] as String?) ?? 'mc';
    final band = bandName == 'keypad'
        ? ProficiencyBand.comfortable
        : ProficiencyBand.challenging;
    final seed = (body['seed'] as num?)?.toInt() ?? 0;
    final settleMs = (body['settleMs'] as num?)?.toInt() ?? 350;

    if (findConceptById(conceptId) == null) {
      return <String, Object?>{
        'ok': false,
        'error': 'unknown concept "$conceptId"',
      };
    }

    if (!await _waitFor(() => _homeReady)) {
      return <String, Object?>{
        'ok': false,
        'error': 'home screen never came up',
      };
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return <String, Object?>{'ok': false, 'error': 'no navigator'};
    }

    _question = null;
    _result = null;
    _errors.clear();

    navigator.popUntil((r) => r.isFirst);
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => QuestionScreen(
            conceptId: conceptId,
            band: band,
            debugMode: true,
            seed: seed,
          ),
        ),
      ),
    );

    if (!await _waitFor(() => _question != null)) {
      return <String, Object?>{
        'ok': false,
        'error': 'question never rendered',
        'errors': _drainErrors(),
      };
    }
    await _settle(settleMs);

    final attached = _question!;
    final q = attached.question;
    return <String, Object?>{
      'ok': true,
      'conceptId': conceptId,
      'conceptName': findConceptById(conceptId)?.name,
      'seed': seed,
      'band': bandName,
      'inputMode': attached.usesKeypad ? 'keypad' : 'mc',
      'prompt': q.prompt,
      'correctAnswer': q.correctAnswer,
      'displayedChoices': attached.displayedChoices,
      'distractors': q.distractors,
      'answerFormat': q.answerFormat.name,
      'answerShape': q.answerShape.name,
      'multipleChoiceOnly': q.multipleChoiceOnly,
      'diagram': q.diagram?.runtimeType.toString(),
      'explanation': q.explanation,
      'explanationDiagram': q.explanationDiagram?.runtimeType.toString(),
      'errors': _drainErrors(),
    };
  }

  // ---------------------------------------------------------------------
  // /answer
  // ---------------------------------------------------------------------

  Future<Map<String, Object?>> _answer(Map<String, Object?> body) async {
    final wantCorrect = (body['correct'] as bool?) ?? true;
    final settleMs = (body['settleMs'] as num?)?.toInt() ?? 350;

    final attached = _question;
    if (attached == null) {
      return <String, Object?>{'ok': false, 'error': 'no question open'};
    }

    // Distractors are guaranteed non-equivalent to the canonical answer,
    // so the first one is a safe "wrong" for both input modes.
    final answer = wantCorrect
        ? attached.question.correctAnswer
        : attached.question.distractors.first;

    _result = null;
    _errors.clear();
    attached.submit(answer);

    if (!await _waitFor(() => _result != null)) {
      return <String, Object?>{
        'ok': false,
        'error': 'result screen never rendered',
        'submitted': answer,
        'errors': _drainErrors(),
      };
    }
    await _settle(settleMs);

    final outcome = _result!.outcome;
    return <String, Object?>{
      'ok': true,
      'submitted': answer,
      'intendedCorrect': wantCorrect,
      'outcome': outcome.name,
      'gradedCorrect': outcome != AnswerOutcome.wrong,
      'errors': _drainErrors(),
    };
  }

  // ---------------------------------------------------------------------
  // Plumbing
  // ---------------------------------------------------------------------

  Future<bool> _waitFor(
    bool Function() done, {
    int timeoutMs = 10000,
  }) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (!done()) {
      if (DateTime.now().isAfter(deadline)) return false;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    return true;
  }

  /// Let the pushed route finish its transition and paint before the
  /// driver screenshots it.
  Future<void> _settle(int ms) async {
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(Duration(milliseconds: ms));
    await SchedulerBinding.instance.endOfFrame;
  }

  List<String> _drainErrors() {
    final out = List<String>.of(_errors);
    _errors.clear();
    return out;
  }

  Future<Map<String, Object?>> _readJsonBody(HttpRequest request) async {
    if (request.method != 'POST') return <String, Object?>{};
    final raw = await utf8.decoder.bind(request).join();
    if (raw.trim().isEmpty) return <String, Object?>{};
    final decoded = jsonDecode(raw);
    return decoded is Map<String, Object?> ? decoded : <String, Object?>{};
  }

  void _writeJson(
    HttpRequest request,
    Map<String, Object?> payload, {
    int status = 200,
  }) {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(payload));
    unawaited(request.response.close());
  }
}

class _AttachedQuestion {
  const _AttachedQuestion({
    required this.question,
    required this.displayedChoices,
    required this.usesKeypad,
    required this.submit,
  });

  final GeneratedQuestion question;
  final List<String> displayedChoices;
  final bool usesKeypad;
  final ValueChanged<String> submit;
}

class _AttachedResult {
  const _AttachedResult({required this.outcome});

  final AnswerOutcome outcome;
}
