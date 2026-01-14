# Nano Examples

This directory contains example applications demonstrating how to use the Nano library.

## Projects

### 1. [Nano Hub](./nano_hub) (Recommended)
The flagship showcase application. It demonstrates the full modular capabilities of Nano v0.7.0+, including:
- **Complex State Management**: Streams, Futures, and keyed atoms (`AtomFamily`).
- **Architecture**: Clean separation of Logic, UI, and Services.
- **DevTools**: Integration with the Nano DevTools extension.
- **Persistence**: Saving state to local storage.
- **Forms**: Reactive form handling.

### 2. [Crypto Tracker](./crypto_tracker)
A simpler example focusing on the core concepts:
- **Basic Atoms**: Reading and writing state.
- **NanoLogic**: Organizing business logic.
- **Theming**: Dynamic theme switching.
- **Async Data**: Handling simple API mock data.

## Running the Examples

Navigate to the respective directory and run:

```bash
cd nano_hub # or cd crypto_tracker
flutter pub get
flutter run
```
