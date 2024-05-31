import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBSetting {
  final String name;
  final String userVisibleName;
  final String description;
  final String value;
  final String icon;

  const DBSetting({
    required this.name,
    required this.userVisibleName,
    required this.description,
    required this.value,
    required this.icon,
  });
  Map<String, Object?> toMap() {
    return {
      "name": name,
      "userVisibleName": userVisibleName,
      "description": description,
      "value": value,
      "icon": icon,
    };
  }

  @override
  String toString() {
    return 'DBSetting{name: $name, userVisibleName: $userVisibleName, description: $description, value: $value}';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'settings_database.db'),
    onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE settings(name TEXT PRIMARY KEY, userVisibleName TEXT, value TEXT, icon TEXT)');
    },
    version: 1,
  );

  Future<void> insertSetting(DBSetting setting) async {
    final db = await database;
    await db.insert(
      "settings",
      setting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DBSetting>> savedSettings() async {
    final db = await database;
    final List<Map<String, Object?>> settingMaps = await db.query("settings");
    return [
      for (final {
            "name": name as String,
            "userVisibleName": userVisibleName as String,
            "description": description as String,
            "value": value as String,
            "icon": icon as String,
          } in settingMaps)
        DBSetting(
          name: name,
          userVisibleName: userVisibleName,
          description: description,
          value: value,
          icon: icon,
        )
    ];
  }

  print(await savedSettings());
  runApp(Hyacinth());
}

class Hyacinth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Hyacinth',
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: HyacinthHomePage(),
    );
  }
}

class HyacinthHomePage extends StatefulWidget {
  const HyacinthHomePage({Key? key}) : super(key: key);

  @override
  _HyacinthHomePageState createState() => _HyacinthHomePageState();
}

class _HyacinthHomePageState extends State<HyacinthHomePage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBuilder: (BuildContext context, int index) {
        return const <Widget>[
          HyacinthMainPage(),
          HyacinthScanner(),
          HyacinthSettingsPage(),
        ][index];
      },
      tabBar: CupertinoTabBar(
        currentIndex: 1,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.lock),
            label: 'Codes',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.radiowaves_left),
            label: 'Scanner',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HyacinthMainPage extends StatelessWidget {
  const HyacinthMainPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: <Widget>[],
      ),
    );
  }
}

class HyacinthSettingsPage extends StatelessWidget {
  const HyacinthSettingsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: <Widget>[
          SwitchSetting(name: "darkmode", icon: "moon"),
        ],
      ),
    );
  }
}

class SwitchSetting extends StatefulWidget {
  final String name;
  final int icon;
  SwitchSetting({
    super.key,
    required this.name,
    required this.icon,
  });

  @override
  State<SwitchSetting> createState() => SwitchSettingState();
}

class SwitchSettingState extends State<SwitchSetting> {
  bool _lights = true;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoListTile(
        title: Row(
          children: <Widget>[
            Icon(
              IconData(widget.icon, fontFamily: 'MaterialIcons'),
            ),
            Text(widget.name),
          ],
        ),
        trailing: CupertinoSwitch(
          value: _lights,
          onChanged: (bool value) {
            setState(() {
              _lights = value;
            });
          },
        ),
        onTap: () {
          setState(() {
            _lights = !_lights;
          });
        },
      ),
    );
  }
}

class HyacinthScannerOverlap extends StatelessWidget {
  const HyacinthScannerOverlap({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        LogoScale(initdelay: const Duration(milliseconds: 500)),
        LogoScale(initdelay: const Duration(seconds: 1)),
        LogoScale(initdelay: const Duration(seconds: 0)),
      ],
    );
  }
}

class HyacinthScanner extends StatelessWidget {
  const HyacinthScanner({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: HyacinthScannerOverlap(),
          ),
          const Center(
            child: CupertinoActivityIndicator(
              radius: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class LogoScale extends StatefulWidget {
  const LogoScale({
    super.key,
    required this.initdelay,
  });
  final Duration initdelay;
  @override
  State<LogoScale> createState() => LogoScaleState();
}

class LogoScaleState extends State<LogoScale> {
  double scale = 1.0;
  double transparency = 0.0;
  bool firstbuild = true;
  bool transparencyup = true;
  void transparencyLoop() {
    Timer(const Duration(milliseconds: 100), () {
      _opacityChangeBounce();
      transparencyLoop();
    });
  }

  void _changeScale() {
    if (scale == 3.0) {}
    setState(() => scale = scale == 1.0 ? 3.0 : 2.0);
  }

  void _opacityChangeBounce() {
    if (transparency >= 1.0) {
      setState(() => transparency = 1.0);
      setState(() => transparencyup = false);
    } else if (transparency <= 0.0) {
      setState(() => transparency = 0.0);
      setState(() => transparencyup = false);
    }
    if (transparencyup == true) {
      setState(() => transparency += 0.1 / 3.0);
    } else {
      setState(() => transparency -= 0.1 / 3.0);
    }
  }

  Future<void> _runsAfterBuild() async {
    Timer(widget.initdelay, () {
      if (firstbuild == true) {
        setState(() => firstbuild = false);
        transparencyLoop();
        _changeScale();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Future(_runsAfterBuild);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(50),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(seconds: 3),
            onEnd: _changeScale,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromRGBO(0, 0, 0, 0),
                border: Border.all(
                  color: Color.fromRGBO(0, 0, 0, transparency),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
