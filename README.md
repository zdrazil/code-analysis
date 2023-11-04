# README

This project is a light wrapper around [code-maat](https://github.com/adamtornhill/code-maat) and its scripts.

Project performs analysis on your code, as described in Adam Tornhill’s book [Your Code as a Crime Scene](https://pragprog.com/titles/atcrime/your-code-as-a-crime-scene/).

The code is not production quality.

## Compatibility

I run the code on macOS with Homebrew installed. I didn't test it in any other environment.

## Prerequisites

- `$HOME/bin` is in your PATH.
- Dependencies are installed.
  - Dependencies you'll need are listed in the [configure](./configure) script.
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

## How to use the reports

To get the most out of these reports, I highly recommend reading Adam Tornhill’s book [Your Code as a Crime Scene](https://pragprog.com/titles/atcrime/your-code-as-a-crime-scene/). Here’s a short summary of how you can use them anyway. They are sorted in the order that makes the most sense to go through them for the first time.

To prepare the reports, run these in you repository first:

- `maat-analyze`
- `maat-analyze-complexity-trend [some filepath in your repository]`

### hotspots.csv and localhost:8888/crime-scene-hotspots.html

This report combines the level of churn (number of revisions) and the level of complexity (lines of code) to determine which modules are the “hottest”, that’s why I’ll be calling them hotspots from now on.

| module                                        | revisions | code |
| --------------------------------------------- | --------- | ---- |
| persister/entity/AbstractEntityPersister.java | 132       | 5289 |
| query/sqm/sql/BaseSqmToSqlAstConverter.java   | 120       | 7323 |

Hotspots report helps you pinpoint the modules where you spend most of your development time.

You can also visualize these hotspots with a [zoomable circle-packing algorithm](https://observablehq.com/@d3/pack-component). This visualization is available at <http://localhost:8888/crime-scene-hotspots.html>. In this visualization, the size of each circle represents the complexity of the module measured by lines of code. The color intensity of each circle reflects the amount of effort measured by number of revisions. By looking at the visual representation, you may notice clusters of hotspots, which could suggest that entire components or packages are going through significant changes.

![Example of hotspot analysis](https://vladimirzdrazil.com/media/hotspots-circle-packing.jpg "Example of hotspot analysis")

#### What can you use it for:

- Prioritizing refactors and code improvements.
- Starting point for comprehending the system.
- It helps you identify stable and fragile parts of the codebase.
- If parts of the code base change together, investigate the changes. The change patterns might suggest new modular boundaries.
- It could indicate that a module has too many responsibilities, which is why it undergoes frequent changes.
- Consider exploring the option of splitting its responsibilities.

### maat-analyze-complexity-trend

After you find a hotspot that you’re interested in, you can use the `maat-analyze-complexity-trend` command to analyze file’s complexity trend. Is the complexity increasing, decreasing, or staying the same? What can you do to make it better?

The command also shows commit hashes along with a row number. Use the row number to find the corresponding commit hash and then run `git show <commit hash>` to examine the changes made in that commit that increased the complexity.

The complexity is measured by analyzing the whitespace used for indentation. The unit is the number of whitespace characters.

```
0    rev         n     total     mean  sd
1    6ef9b03f8b  7003  23306.25  3.33  2.14
2    67d751d81d  6959  22916.25  3.29  2.1
```

<dl>
  <dt>rev</dt>
  <dd>commit</dd>
  <dt>n</dt>
  <dd>number of lines</dd>
  <dt>total</dt>
  <dd>total complexity per file</dd>
  <dt>mean</dt>
  <dd>average mean per file</dd>
  <dt>sd</dt>
  <dd>
    <p
      >Standard deviation. The number tells you the average complexity of lines
      in comparison to the mean.</p
    >
    <p
      >In the example, for row 1 the average mean is 3.33. A standard deviation
      of 2.14 means that for 68% of lines in the file, the complexity will fall
      within the range of 3.33 - 2.14 and 3.33 + 2.14.</p
    >
  </dd>
</dl>

![Complexity trend](https://vladimirzdrazil.com/media/maat-complexity-trend.jpg "Complexity trend")

### sum-of-coupling.csv and temporal-coupling.csv

In large codebases, hidden dependencies between subsystems contribute to technical debt. Even when individual modules were meant to be unrelated, couplings can form over time for various reasons. As these couplings grow, the system’s design becomes more rigid and extending its features becomes harder. Detecting these couplings early on and taking action is important to prevent overwhelming refactoring efforts.

The file `sum-of-coupling.csv` shows the number of transactions that are shared between modules. This provides a list of modules that are frequently changed together with others.

The file `temporal-coupling.csv` provides a list of modules that tend to change together. The degree indicates how frequently the files change at the same time, represented as a percentage.

#### What can you use it for

Identify modules which are coupled and consider uncoupling them.

### author-entity-effort.csv and entity-ownership.csv

The file `author-entity-effort.csv` displays the percentage of commits each person contributed to the module.

The file `entity-ownership.csv` shows the number of lines each author added or deleted.

#### What can you use it for

This code helps you find the best person to contact and ask questions about a specific module.

## Related

- https://github.com/adamtornhill/code-maat
- https://github.com/islomar/your-code-as-a-crime-scene
