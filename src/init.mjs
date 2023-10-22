#!/usr/bin/env node

import { execSync, spawn } from "node:child_process";
import fs from "node:fs";
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";
import { parseArgs } from "node:util";

/**
 * @param {string} command
 * @param {import("child_process").ExecSyncOptions | undefined} [options]
 */
const $ = (command, options = {}) =>
  execSync(command, { stdio: "inherit", ...options });

const repoDir = `${homedir()}/projects/my-project`;
const generatedPath = "generated";
const repoLogPath = path.join(generatedPath, "repo.log");
const repoRevisionsPath = path.join(generatedPath, "maat_freqs.csv");
const linesPath = path.join(generatedPath, "maat_lines.csv");
const complexityAndEffortPath = path.join(
  generatedPath,
  "complexity_effort.csv",
);
const hotspotsJSONPath = path.join(generatedPath, "hotspots.json");

/**
 * @param {object} options
 * @param {string} options.since
 * @param {string} options.folder
 */
function generate({ folder, since }) {
  if (!existsSync(generatedPath)) {
    mkdirSync(generatedPath);
  }

  const logStream = fs.createWriteStream(repoLogPath);

  const gitLog = spawn(
    `git log --follow --pretty=format:'[%h] %an %ad %s' --date=short --numstat --after="${since}" -- "${folder}"`,
    {
      cwd: repoDir,
      shell: true,
      stdio: ["inherit", "pipe", "inherit"],
    },
  );

  gitLog.stdout.pipe(logStream);

  logStream.on("close", () => {
    inspect({ folder });
  });
}

/**
 * @param {object} options
 * @param {string} options.folder
 */
function inspect({ folder }) {
  console.log("Summary");
  $(`maat -l ${repoLogPath} -c git -a summary`);

  const revisionsStream = fs.createWriteStream(repoRevisionsPath);
  const maatRevisions = spawn(`maat -l ${repoLogPath} -c git -a revisions`, {
    shell: true,
    stdio: ["inherit", "pipe", "inherit"],
  });

  maatRevisions.stdout.pipe(revisionsStream);

  maatRevisions.on("close", () => {
    const clocLinesStream = fs.createWriteStream(linesPath);
    const cloc = spawn(`cloc  ${folder} --vcs git --by-file --csv --quiet`, {
      shell: true,
      cwd: repoDir,
      stdio: ["inherit", "pipe", "inherit"],
    });

    cloc.stdout.pipe(clocLinesStream);

    cloc.on("close", () => {
      const complexityEffortStream = fs.createWriteStream(
        complexityAndEffortPath,
      );
      const mergeComp = spawn(
        `python scripts/merge/merge_comp_freqs.py ${repoRevisionsPath} ${linesPath}`,
        {
          shell: true,
          stdio: ["inherit", "pipe", "inherit"],
        },
      );

      mergeComp.stdout.pipe(complexityEffortStream);

      complexityEffortStream.on("close", () => {
        hotspots: {
          const jsonForServer = fs.createWriteStream(hotspotsJSONPath);
          const csvAsJson = spawn(
            `python scripts/transform/csv_as_enclosure_json.py --structure ${linesPath} --weights ${complexityAndEffortPath}
            `,
            {
              shell: true,
              stdio: ["inherit", "pipe", "inherit"],
            },
          );

          csvAsJson.stdout.pipe(jsonForServer);
        }
      });
    });
  });
}

function main() {
  const {
    values: { folder = ".", since = "3 months" },
  } = parseArgs({
    options: {
      folder: { type: "string" },
      since: { type: "string" },
    },
  });

  generate({ folder, since });
}

main();
