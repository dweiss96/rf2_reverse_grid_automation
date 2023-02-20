import 'dart:convert';

import 'package:rf2_double_race_manager/StateMachine.dart';

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
  final RaceStateMachine _rsm = RaceStateMachine();

  bool _enabled = false;
  static String xmlResultFileFolder = "";
  static int reverseTopX = 0;
  static SessionInfo? currentSessionInfo;

  bool isEnabled() => _enabled;

  void enable() => _enabled = true;
  void disable() => _enabled = false;

  String debug() => '''
Reverse Top $reverseTopX and search for logs herre: $xmlResultFileFolder

current state = ${_rsm.getStateMachine().current.name}
current session = ${currentSessionInfo?.session} - ${currentSessionInfo?.timeRemaining().round()}s remaining
''';

  Controller() {
    _rsm.goToWarmup1.stream.listen((stateChange) async {
      await _setRaceCount(2);
    });
    _rsm.goToGrid1.stream.listen((stateChange) async {
      await _forwardSession();
    });
    _rsm.goToGrid2.stream.listen((stateChange) async {
      await _setReverseGrid();
      await _forwardSession();
    });
    _rsm.goToUnwantedRace.stream.listen((stateChange) async {
      await _restartWarmup();
    });
    _rsm.goToWarmup2.stream.listen((stateChange) async {
      await _setRaceCount(1);
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
          _rsm.restartServer();
          break;
        case "qualifying":
          _rsm.goToQualy();
          break;
        case "warmup":
          if ((currentSessionInfo?.timeRemaining() ?? 666) < 1) {
            _rsm.goToGrid2();
            _rsm.goToGrid1();
          } else {
            _rsm.goToWarmup2();
            _rsm.goToWarmup1();
          }
          break;
        case "race1":
          _rsm.goToRace2();
          _rsm.goToRace1();
          break;
        case "race2":
          _rsm.goToUnwantedRace();
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
