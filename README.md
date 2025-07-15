# Tuxer-UI
An incredibly lightweight library for the [tuxer](https://github.com/LemmaAlliance/tuxer) browser, designed to provide an easier way to create windows.

## Progress
![50%](https://geps.dev/progress/50)

Progress has slowed, I am currently writing the script to open the window.
I have written code to connect to X11, send & recieve handshakes. I am yet to verify the handshake, but no errors are thrown. <br />
### Sections:
✔️ | Opened socket<br />
✔️ | Sent handshake - Needs verifying<br />
✔️ | Recieved handshake - Needs verifying<br />
✔️ | Build args for create window<br />
⭕ | Call create window - needs verifying<br />
⭕ | Get root window ID<br />
⭕ | Turn this from a project to a package<br />

## Contributing
If you want to contribute to this project (or make your own version), first familiarise yourself with the license on "LICENSE", then fork the repo and setup your development enviroment. <br />

REMEMBER: Always read the Xlib [documentation](https://www.x.org/releases/current/doc/libX11/libX11/libX11.html)

For debian based systems:
```bash
sudo apt update
sudo apt install gcc binutils nasm
```

Makefile commands:
```bash
# Install dependencies
make deps

# Compile
make

# Run the binary
make run

# Clean the build directory
make clean
```
Please note that you should never push with an empty build directory

Then you are ready to begin programming!
