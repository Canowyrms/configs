# Windows Sandbox Templates

## How to Use

- Have Windows Sandbox installed/enabled.
- Create desktop/start menu shortcuts to *.wsb files (or just run them directly).


## Important Considerations

The templates utilize mapped directories. These directories use absolute paths on the host and in the sandbox. If this directory moves, the host paths must be updated.


## Templates

### Base Template

The base template applies simple customizations to the sandbox environment so that it more closely matches my host environment


### Scoop Template

The scoop template uses the base template as a foundation and installs Scoop, Git, Windows Terminal, PowerShell 7.
