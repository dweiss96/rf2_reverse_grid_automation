import 'dart:convert';

import 'package:rf2_double_race_manager/race_state_machine.dart';
import 'package:rf2_double_race_manager/state_machine.dart';

import 'xml_reader.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class SessionInfo {
  final String session;
  final double currentEventTime;
  final double endEventTime;

  double timeRemaining() => endEventTime - currentEventTime;

  SessionInfo(this.session, this.currentEventTime, this.endEventTime);

  SessionInfo.fromJson(Map<String, dynamic> json)
      : session = json['session'],
        endEventTime = json['endEventTime'],
        currentEventTime = json['currentEventTime'];

  Map<String, dynamic> toJson() => {
        'session': session,
        'currentEventTime': currentEventTime,
        'endEventTime': endEventTime,
      };
}

class Controller {
  static const String _httpBaseUrl = "http://localhost:5397";
  final StateMachine _rsm = RaceStateMachine.initialize();

  bool _enabled = false;
  static String xmlResultFileFolder = "";
  static int reverseTopX = 0;
  static SessionInfo? currentSessionInfo;

  bool isEnabled() => _enabled;

  void enable() => _enabled = true;
  void disable() => _enabled = false;

  String debug() => '''
Reverse Top $reverseTopX and search for logs herre: $xmlResultFileFolder

current state = ${_rsm.currentState.name}
current session = ${currentSessionInfo?.session} - ${currentSessionInfo?.timeRemaining().round()}s remaining
''';

  Controller() {
    _rsm.stream().listen((event) async {
      switch (event) {
        case RST.goToWarmup1:
          await _setRaceCount(2);
          break;
        case RST.goToWarmup2:
          await _setRaceCount(1);
          break;
        case RST.goToGrid1:
          await _forwardSession();
          break;
        case RST.goToGrid2:
          await _setReverseGrid();
          await _forwardSession();
          break;
        case RST.goToUnwantedRace:
          await _restartWarmup();
          break;
      }
    });
  }

  Future<String> tick() async {
    if (isEnabled()) {
      final response =
          await http.get(Uri.parse("$_httpBaseUrl/rest/watch/sessionInfo"));
      currentSessionInfo = SessionInfo.fromJson(jsonDecode(response.body));

      // if multiple states just evalutate in reverse order. only one change should be legal then.
      switch (currentSessionInfo?.session.toLowerCase()) {
        case "practice":
          _rsm.transition(RST.restartWeekend);
          break;
        case "qualifying":
          _rsm.transition(RST.goToQualy);
          break;
        case "warmup":
          if ((currentSessionInfo?.timeRemaining() ?? 666) < 1) {
            _rsm.transition(RST.goToGrid2);
            _rsm.transition(RST.goToGrid1);
          } else {
            _rsm.transition(RST.goToWarmup2);
            _rsm.transition(RST.goToWarmup1);
          }
          break;
        case "race1":
          _rsm.transition(RST.goToRace2);
          _rsm.transition(RST.goToRace1);
          break;
        case "race2":
          _rsm.transition(RST.goToUnwantedRace);
          break;
      }

      return debug();
    }
    return "DISABLED";
  }

  Future<void> _setReverseGrid() async {
    // find latest race result
    final dir = Directory(xmlResultFileFolder);
    final logs = await dir
        .list()
        .map((e) => e.path)
        .where((e) => e.endsWith("R1.xml"))
        .toList();
    logs.sort((a, b) => a.compareTo(b) * -1);

    // generate commands
    final commands = generateGridCommandsFromXml(logs.first, reverseTopX);

    // send commands via chat
    for (int i = 0; i < commands.length; i++) {
      await _sendChatCmd(commands.elementAt(i));
    }
  }

  Future<http.Response?> _restartWarmup() async {
    if (_enabled) {
      return await _sendChatCmd("/callvote restartwarmup");
    }
    return Future(() => null);
  }

  Future<http.Response?> _forwardSession() async {
    if (_enabled) {
      return await _sendChatCmd("/callvote nextsession");
    }
    return Future(() => null);
  }

  Future<http.Response> _sendChatCmd(String cmd) async {
    return await http.post(
      Uri.parse('$_httpBaseUrl/rest/chat'),
      body: cmd,
    );
  }

  Future<http.Response> _setRaceCount(int count) async {
    return await http
        .post(Uri.parse("$_httpBaseUrl/rest/sessions/race/$count"));
  }
}
