import 'package:flutter/material.dart';
import 'newController.dart';
import 'store.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'RF2 LiveTiming Tool';
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
  final controller = Controller();
  TextEditingController xmlPathController = TextEditingController();
  TextEditingController reverseTopXController = TextEditingController();
  bool checkedValue = false;

  _MyCustomFormState();

  @override
  void dispose() {
    xmlPathController.dispose();
    reverseTopXController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    Store.getLogPath().then((lp) {Store.getReverseTopX().then((rtx) {
      setState(() {
        xmlPathController = TextEditingController(text: lp);
        reverseTopXController = TextEditingController(text: rtx?.toString());
      });
    });});
  }

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
              Store.setLogPath(xmlPathController.text.trim());
              Store.setReverseTopX(
                int.parse(reverseTopXController.text.trim())
              );
            },
            child: const Text('Save Values'),
          ),
        ),
        CheckboxListTile(
          title: const Text("enable double race handling?"),
          value: controller.isEnabled(),
          onChanged: (newValue) {
            if (newValue ?? false) {
              setState(() {
                controller.enable();
              });
            } else {
              setState(() {
                controller.disable();
              });
            }
          },
          controlAffinity:
              ListTileControlAffinity.leading, //  <-- leading Checkbox
        ),
        StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)).asyncMap(
              (i) => controller.tick()), // i is null here (check periodic docs)
          builder: (context, snapshot) => 
          Text(snapshot.data.toString()), // builder should also handle the case when data is not fetched yet
        )
      ],
    );
  }
}
