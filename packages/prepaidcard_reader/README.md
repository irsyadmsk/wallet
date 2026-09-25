# prepaidcard_reader

A Flutter plugin for reading NFC prepaid cards. This plugin provides functionality to interact with NFC-enabled cards, allowing you to read essential information such as card number, card name, balance, and other relevant details.

<img width="270" height="630" alt="Screenshot_20250808_225922" src="https://github.com/user-attachments/assets/6cf617ce-5c63-4081-b383-2e4d71461482" />

## Features

- **NFC Availability Check**: Determine if NFC is available on the device.
- **Start/Stop NFC Session**: Initiate and terminate NFC scanning sessions.
- **Read Card Data**: Retrieve detailed information from supported NFC prepaid cards, including:
    - `cardId`
    - `cardName`
    - `cardNumber`
    - `balance`
    - `cardCode`
    - `anotherInfo` (for additional data)
- **Error Handling**: Basic error handling for NFC operations.

### Installation

Add `prepaidcard_reader` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  prepaidcard_reader: ^latest_version # Use the latest version
```

Then, run `flutter pub get` to fetch the package.

### Platform Support

| Platform | Support |
|----------|---------|
| Android  | Yes     |
| iOS      | No      |
| Web      | No      |
| Desktop  | No      |

## Usage

To use the plugin, import it in your Dart file:

```dart
import 'package:prepaidcard_reader/prepaidcard_reader.dart';
```

### Checking NFC Availability

```dart
bool isNfcAvailable = await PrepaidcardReader.instance.isAvailable();
if (isNfcAvailable) {
  // NFC is available, proceed with scanning
} else {
  // NFC is not available on this device
}
```

### Starting and Stopping NFC Session

You can start an NFC session and listen for card discoveries:

```dart
PrepaidcardReader.instance.startSession((card) async {
  // Card discovered, process card data
  print('Card Name: ${card.cardName}');
  print('Card Number: ${card.cardNumber}');
  print('Balance: ${card.balance}');
  // ... display other card data

  // Optionally stop the session after reading a card
  PrepaidcardReader.instance.stopSession();
}).catchError((error) {
  // Handle errors during session
  print('Error: $error');
});

// To stop the session manually (e.g., on a button press)
PrepaidcardReader.instance.stopSession();
```

### CardModel

The `CardModel` object contains the following properties:

| Property      | Type   | Description                               |
|---------------|--------|-------------------------------------------|
| `cardId`      | `String` | Unique identifier for the card.           |
| `cardName`    | `String` | Name associated with the card.            |
| `cardNumber`  | `String` | The primary card number.                  |
| `balance`     | `String` | Current balance on the card.              |
| `cardCode`    | `String` | Additional code for the card.             |
| `anotherInfo` | `String` | Any other relevant information.           |

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
