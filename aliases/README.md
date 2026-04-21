# Shell aliases

A smart `tree` function that walks up the directory tree looking for `.treeignore` (like git finds `.git`) and uses it when present. Works in any folder with a `.treeignore` after a one-time rc setup.

Add the relevant source line to your shell rc:

```sh
# ~/.zshrc
source /path/to/dvs2-demo/aliases/tree.zsh

# ~/.bashrc
source /path/to/dvs2-demo/aliases/tree.bash

# ~/.config/fish/config.fish
source /path/to/dvs2-demo/aliases/tree.fish
```

```powershell
# $PROFILE
. /path/to/dvs2-demo/aliases/tree.ps1
```

Start a new shell (or `source` your rc) and `tree` will auto-detect `.treeignore`.
