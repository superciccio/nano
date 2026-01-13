# Nano DevTools Extension

This package contains the official DevTools extension for the Nano state management library.

## Features

*   **Atom Inspector**: View real-time values of all registered Atoms in your application.
*   **State History**: Track the history of state changes with timestamps.
*   **Time Travel**: Revert your application state to any previous point in time.

## Development

To build the extension for local testing:

1.  Navigate to this directory:
    ```bash
    cd packages/nano_devtools_extension
    ```

2.  Build the web assets:
    ```bash
    flutter build web --no-tree-shake-icons --output build
    ```

3.  (Important) Update the `<base>` tag in `build/index.html`:
    Change `<base href="/">` to `<base href="./">`.

4.  Serve the extension.
