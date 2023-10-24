# README

This project is a light wrapper around [code-maat](https://github.com/adamtornhill/code-maat) and its scripts.

Project performs analysis on your code, as described in Adam Tornhill’s book [Your Code as a Crime Scene](https://pragprog.com/titles/atcrime/your-code-as-a-crime-scene/).

The code is not production quality. It's more like a quick hack job to get something working.

## Compatibility

I ran the code on macOS with homebrew installed. I didn't test it on any other environments.

## Prerequisites

- `$HOME/bin` is in your PATH.
- Understand what [code-maat](https://github.com/adamtornhill/code-maat) can do.

### Dependencies

- bash
- [cloc](https://github.com/AlDanial/cloc)
- [direnv](https://direnv.net/)
- [git](https://git-scm.com/)
- [Java](https://www.java.com/en/)
- [python 3](https://www.python.org/)
- [wget](https://www.gnu.org/software/wget/)

### Python packages

- virtualenv

### Homebrew on macOS

You can install the dependencies with [Homebrew](https://brew.sh/):

```bash
brew install cloc direnv java git python
sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
```

## Installation

To install [code-maat](https://github.com/adamtornhill/code-maat), two additional commands, and some additional dependencies, run the following command in your terminal:

```bash
src/install.sh
```

Keep in mind that this script:

- Installs [code-maat](https://github.com/adamtornhill/code-maat) into `$HOME/bin`.
- Downloads extra dependencies from the internet.
- Symlinks `maat-analyze` and `maat-analyze-complexity-trend` into `$HOME/bin` so you can call them anywhere.

Take a moment to go through the script and understand what it does before you proceed.

## Usage

In your repository, run

```bash
maat-analyze --help
maat-analyze-complexity-trend --help
```

and go from there.

## Related

- https://github.com/adamtornhill/code-maat
- https://github.com/islomar/your-code-as-a-crime-scene
