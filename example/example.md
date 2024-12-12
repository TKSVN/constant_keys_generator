# Example for using `constant_keys_generator`

## Prepare json files

[assets/translations/en.json](assets/translations/en.json)
[assets/translations/vi.json](assets/translations/vi.json)
[assets/translations/ja.json](assets/translations/ja.json)

## Update `pubspec.yaml`

Add the following configuration to [`pubspec.yaml`](pubspec.yaml)

```yaml
constant_keys_generator:
  file_configs:
    - input_file: "assets/translations/*.json"
      output_file: "locale_keys"
```

## Run `build_runner` build

```bash
dart run build_runner build
```

## Verify generated file in path `lib/generated/constant_keys/locale_keys.g.dart`

```dart
// ignore_for_file: camel_case_types
class _LocaleKeys_Common {
  final String appName = 'common.appName';
  _LocaleKeys_Common();
}

class _LocaleKeys {
  final _LocaleKeys_Common common = _LocaleKeys_Common();
  _LocaleKeys();
}

// ignore: non_constant_identifier_names
final LocaleKeys = _LocaleKeys();
```

## Using type-safe constants from generated file for [`easy_localization`](https://pub.dev/packages/easy_localization)'s keys

**main.dart**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ja'), Locale('vi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp()
    ),
  );
}
```

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: tr(LocaleKeys.common.appName)),
    );
  }
}
```
