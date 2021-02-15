import 'package:flutter/material.dart';
import 'package:clip/clip.dart';

import 'user.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        const ClipLocalizationsDelegate(),
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('ar'),
      ],
      title: 'Flutter Clipy Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _clipKey = GlobalKey<ClipState>();

  final _user = User(
    id: 1,
    name: 'User 01',
    avatar: 'https://avatars2.githubusercontent.com/u/4195236?v=3',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Clipy Demo Home Page'),
      ),
      body: Form(
        key: _formKey,
        child: Clip(
          key: _clipKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              ImageClipField(
                key: ValueKey('avatar'),
                initialValue: _user.avatar,
                builder: (context, image) {
                  return CircleAvatar(
                    radius: 56,
                    child: image != null
                        ? null
                        : Center(
                            child: Icon(
                              Icons.add_a_photo_outlined,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                    backgroundImage: image != null ? MemoryImage(image) : null,
                  );
                },
                onSaved: (avatar) {
                  print(avatar);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submit,
        tooltip: 'Save',
        child: Icon(Icons.done),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _submit() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      _clipKey.currentState.save();
    }
  }
}
