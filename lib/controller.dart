import 'dart:convert';

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

  static bool _enabled = false;
  static bool _comesFromR2 = false;
  static String xmlResultFileFolder = "";
  static int reverseTopX = 0;
  static SessionInfo? currentSessionInfo;

  static bool getEnabledState() => _enabled;
  static String getConfig() =>
      "Reverse Top $reverseTopX | Search at '$xmlResultFileFolder'";

  static void enableDoubleWeekendMode() {
    _enabled = true;
    _setRaceCount(2);
  }

  static void disableDoubleWeekendMode() {
    _enabled = false;
    _setRaceCount(1);
  }

  static void evaluateSideEffects() {
    if (_enabled) {
      if (currentSessionInfo?.session == "RACE2") {
        _comesFromR2 = true;
        _sendChatCmd("/restartwarmup");
        return;
      } else if (currentSessionInfo?.session == "WARMUP" &&
          (currentSessionInfo?.timeRemaining() ?? 86400) < 5.0 &&
          _comesFromR2) {
        setReverseGrid();
        disableDoubleWeekendMode();
      } else {
        _comesFromR2 = false;
      }
    } else if (currentSessionInfo?.session == "WARMUP" &&
          (currentSessionInfo?.timeRemaining() ?? 86400) < 0.0) {
        _sendChatCmd("/straighttorace");
        disableDoubleWeekendMode();
      }
  }

  static Future<String> fetchServerData() async {
    final response =
        await http.get(Uri.parse("$_httpBaseUrl/rest/watch/sessionInfo"));
    currentSessionInfo = SessionInfo.fromJson(jsonDecode(response.body));

    evaluateSideEffects();

    return "${currentSessionInfo?.session} ${currentSessionInfo?.timeRemaining()}";
  }

  static void setReverseGrid() async {
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
    commands.forEach(_sendChatCmd);

    
  }

  static void forwardToRace() {
    if (_enabled) {
      _sendChatCmd("/straighttorace");
    }
  }

  static void _sendChatCmd(String cmd) {
    http.post(
      Uri.parse('$_httpBaseUrl/rest/chat'),
      body: cmd,
    );
  }

  static void _setRaceCount(int count) {
    http.post(Uri.parse("$_httpBaseUrl/rest/sessions/race/$count"));
  }
}
