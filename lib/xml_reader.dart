import 'dart:io';
import 'package:xml/xml.dart';

class DriverResult {
  String Name;
  int Position;

  DriverResult(this.Name, this.Position);

  DriverResult.fromXML(String? nameString, String? positionString)
      : Name = nameString ?? "",
        Position = int.parse(positionString ?? "80");
}

Iterable<String> generateGridCommandsFromXml(String xmlPath, int reverseTopX) {
  final file = File(xmlPath);
  final document = XmlDocument.parse(file.readAsStringSync());

  final drivers = document
          .getElement('rFactorXML')
          ?.getElement('RaceResults')
          ?.getElement('Race')
          ?.findElements('Driver')
          .map((node) => DriverResult.fromXML(
              node.getElement('Name')?.text, node.getElement('Position')?.text))
          .toList() ??
      List.empty();

  drivers.sort((a, b) => a.Position.compareTo(b.Position));

  if (drivers.length <= reverseTopX) {
    return drivers.reversed.toList()
      .asMap()
      .entries
      .map((entry) => "/editgrid ${entry.key} ${entry.value.Name}");
  }

  final reversedField = drivers.sublist(0, reverseTopX).reversed.toList();
  reversedField.addAll(drivers.sublist(reverseTopX));

  return reversedField
      .asMap()
      .entries
      .map((entry) => "/editgrid ${entry.key} ${entry.value.Name}");
}
