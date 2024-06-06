import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBSetting {
  final String name;
  final String userVisibleName;
  final String value;
  final String icon;

  const DBSetting({
    required this.name,
    required this.userVisibleName,
    required this.value,
    required this.icon,
  });
  Map<String, Object?> toMap() {
    return {
      "name": name,
      "userVisibleName": userVisibleName,
      "value": value,
      "icon": icon,
    };
  }

  @override
  String toString() {
    return 'DBSetting{name: $name, userVisibleName: $userVisibleName, value: $value}';
  }
}

Future<void> insertSetting(DBSetting setting) async {
  final database = openDatabase(
    join(await getDatabasesPath(), 'settings_database.db'),
    onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE settings(name TEXT PRIMARY KEY, userVisibleName TEXT, value TEXT, icon TEXT)');
    },
    version: 1,
  );

  final db = await database;
  await db.insert(
    "settings",
    setting.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

void loadDefaults() async {
  final database = openDatabase(
    join(await getDatabasesPath(), 'settings_database.db'),
    onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE settings(name TEXT PRIMARY KEY, userVisibleName TEXT, value TEXT, icon TEXT)');
    },
    version: 1,
  );

  final db = await database;
  const defaults = <DBSetting>[
    DBSetting(
      name: "debugmode",
      icon: "0xf8a0",
      userVisibleName: "Debug Mode",
      value: "false",
    ),
    DBSetting(
      name: "darkmode",
      icon: "0xf717",
      userVisibleName: "Dark Mode",
      value: "false",
    )
  ];
  for (var i in defaults) {
    await db.insert(
      "settings",
      i.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}

Future<List<DBSetting>> savedSettings() async {
  final database = openDatabase(
    join(await getDatabasesPath(), 'settings_database.db'),
    onCreate: (db, version) {
      loadDefaults();
      return db.execute(
          'CREATE TABLE settings(name TEXT PRIMARY KEY, userVisibleName TEXT, value TEXT, icon TEXT)');
    },
    version: 1,
  );
  final db = await database;
  final List<Map<String, Object?>> settingMaps = await db.query("settings");
  return [
    for (final {
          "name": name as String,
          "userVisibleName": userVisibleName as String,
          "value": value as String,
          "icon": icon as String,
        } in settingMaps)
      DBSetting(
        name: name,
        userVisibleName: userVisibleName,
        value: value,
        icon: icon,
      )
  ];
}

Future<bool> getActivated(String name) async {
  var settings = await savedSettings();
  for (var i in settings) {
    if (i.toMap()["name"] == name) {
      return i.toMap()["value"] == true;
    }
  }
  return false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  loadDefaults();

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
        currentIndex: 0,
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
    return FutureBuilder(
      builder: (BuildContext ctx, AsyncSnapshot<List<DBSetting>> snapshot) {
        if (ConnectionState.done == snapshot.connectionState) {
          var remappedData = snapshot.data?.map((x) => x.toMap());
          if (remappedData != null) {
            return CupertinoPageScaffold(
              child: Column(
                children: <Widget>[
                  CupertinoListSection(
                    header: const Text("Preferences"),
                    topMargin: 50,
                    children: <SwitchSetting>[
                      for (final {
                            "name": name as String,
                            "userVisibleName": userVisibleName as String,
                            "value": value as String,
                            "icon": icon as String,
                          } in remappedData)
                        SwitchSetting(
                          name: name,
                          userVisibleName: userVisibleName,
                          value: value,
                          icon: int.parse(icon),
                        )
                    ],
                  )
                ],
              ),
            );
          } else {
            return const CupertinoActivityIndicator();
          }
        } else {
          return const CupertinoActivityIndicator();
        }
      },
      future: savedSettings(),
    );
  }
}

class SwitchSetting extends StatefulWidget {
  final String name;
  final int icon;
  final String userVisibleName;
  final String value;
  const SwitchSetting({
    super.key,
    required this.name,
    required this.icon,
    required this.value,
    required this.userVisibleName,
  });

  @override
  State<SwitchSetting> createState() => SwitchSettingState();
}

class SwitchSettingState extends State<SwitchSetting> {
  bool _lights = false;
  bool freshInit = true;

  @override
  Widget build(BuildContext context) {
    if (freshInit == true) {
      _lights = widget.value == "true";
      freshInit = false;
    }
    return MergeSemantics(
      child: CupertinoListTile(
        title: Row(
          children: <Widget>[
            Icon(
              IconData(
                widget.icon,
                fontFamily: 'CupertinoIcons',
                fontPackage: 'cupertino_icons',
              ),
            ),
            const Text(" "),
            Text(widget.userVisibleName),
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
          insertSetting(
            DBSetting(
              userVisibleName: widget.userVisibleName,
              name: widget.name,
              icon: widget.icon.toString(),
              value: _lights.toString(),
            ),
          );
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
    return const CupertinoPageScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: CupertinoActivityIndicator(
              radius: 32,
            ),
          ),
          Center(child: Text("Scanner Active")),
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
