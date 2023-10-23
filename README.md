# README

This project is a light wrapper around [code-maat](https://github.com/adamtornhill/code-maat) and its scripts.

Project performs analysis on your code, as described in Adam Tornhill’s book [Your Code as a Crime Scene](https://pragprog.com/titles/atcrime/your-code-as-a-crime-scene/).

The code is not production quality.

## Prerequisites

- "$HOME/bin" in your PATH.
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

### Homebrew on MacOS

You can install the dependencies with [Homebrew](https://brew.sh/):

```bash
brew install cloc direnv java git python
sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
```

## Installation

To install [code-maat](https://github.com/adamtornhill/code-maat) and its scripts, run the following command in your terminal:

```bash
src/install.sh
```

Keep in mind that this script installs [code-maat](https://github.com/adamtornhill/code-maat) outside its folder. It also downloads extra dependencies from the internet. Take a moment to go through the script and understand what it does before you proceed.

## Usage

Run

```bash
src/analyze.sh --help
```

and go from there.

## Related

- https://github.com/adamtornhill/code-maat
- https://github.com/islomar/your-code-as-a-crime-scene
