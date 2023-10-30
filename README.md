# README

This project is a light wrapper around [code-maat](https://github.com/adamtornhill/code-maat) and its scripts.

Project performs analysis on your code, as described in Adam Tornhill’s book [Your Code as a Crime Scene](https://pragprog.com/titles/atcrime/your-code-as-a-crime-scene/).

The code is not production quality. It's more like a quick hack job to get something working.

## Compatibility

I ran the code on macOS with Homebrew installed. I didn't test it in any other environment.

## Prerequisites

- `$HOME/bin` is in your PATH.
- Dependencies are installed.
  - Dependencies are listed in the [configure](./configure) script.
- Understand what [code-maat](https://github.com/adamtornhill/code-maat) can do.

Run `./configure` to check that you have the prerequisites ready.

### Homebrew on macOS

You can install the dependencies with [Homebrew](https://brew.sh/):

```bash
brew install cloc direnv java git python wget
sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
```

## Installation

To install [code-maat](https://github.com/adamtornhill/code-maat), three additional commands, and some additional dependencies, run the following commands in your terminal:

```bash
make
make install
```

Keep in mind that these commands will (among other things):

- Install [code-maat](https://github.com/adamtornhill/code-maat) into `$HOME/bin`.
- Download extra dependencies from the internet.
- Symlink `maat-analyze`, `maat-analyze-complexity-trend` and `maat-filter` into `$HOME/bin` so you can call them anywhere.

Take a moment to go through the Makefile and understand what it does before you proceed.

## Usage

In your repository, run

```bash
maat-analyze --help
maat-analyze-complexity-trend --help
maat-filter --help
```

and go from there.

## Uninstallation

```bash
make uninstall
```

## Related

- https://github.com/adamtornhill/code-maat
- https://github.com/islomar/your-code-as-a-crime-scene
