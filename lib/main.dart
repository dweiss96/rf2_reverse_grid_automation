import 'package:flutter/material.dart';
import 'controller.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Form Styling Demo';
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        body: const MyCustomForm(),
      ),
    );
  }
}

// Define a custom Form widget.
class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  State<MyCustomForm> createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final TextEditingController xmlPathController = TextEditingController();
  final TextEditingController reverseTopXController = TextEditingController();
  bool checkedValue = false;

  @override
  void dispose() {
    xmlPathController.dispose();
    reverseTopXController.dispose();
    super.dispose();
  }

  Widget generateFetcher() => Controller.getEnabledState()
      ? StreamBuilder(
          stream: Stream.periodic(Duration(seconds: 1)).asyncMap(
              (i) => Controller.fetchServerData()), // i is null here (check periodic docs)
          builder: (context, snapshot) => 
          Text(snapshot.data.toString()), // builder should also handle the case when data is not fetched yet
        )
      : Text("Double header mode disabled");

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: TextField(
            controller: xmlPathController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'rF2 results directory:',
              hintText: '<path-to-rfactor2>/UserData/player/Log/Results',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: TextField(
            controller: reverseTopXController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'reverse top X:',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            ),
            onPressed: () {
              setState(() {
                checkedValue = true;
              });
              Controller.xmlResultFileFolder = xmlPathController.text.trim();
              Controller.reverseTopX =
                  int.parse(reverseTopXController.text.trim());
            },
            child: const Text('Save Values'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Text(Controller.getConfig()),
        ),
        CheckboxListTile(
          title: const Text("enable double race handling?"),
          value: Controller.getEnabledState(),
          onChanged: (newValue) {
            if (newValue ?? false) {
              setState(() {
                Controller.enableDoubleWeekendMode();
              });
            } else {
              setState(() {
                Controller.disableDoubleWeekendMode();
              });
            }
          },
          controlAffinity:
              ListTileControlAffinity.leading, //  <-- leading Checkbox
        ),
        generateFetcher()
      ],
    );
  }
}
