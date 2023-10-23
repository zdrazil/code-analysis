#!/usr/bin/env bash
# shellcheck enable=all

my_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

bin_path="${HOME}/bin"

ln -s "${my_dir}/analyze.sh" "${bin_path}/maat-analyze"
ln -s "${my_dir}/analyze-complexity-trend.sh" "${bin_path}/maat-analyze-complexity-trend"

install_maat() {
  wget --show-progress \
    --no-cache \
    --output-document "${HOME}/bin/code-maat.jar" \
    "https://github.com/adamtornhill/code-maat/releases/download/v1.0.4/code-maat-1.0.4-standalone.jar" ||
    exit

  cp "${my_dir}/maat.sh" "${bin_path}/maat" || exit
}

install_maat

scripts_path="${my_dir}/../scripts"

rm -rf "${scripts_path}" || exit

git clone \
  --depth=1 \
  --branch=python3 \
  git@github.com:adamtornhill/maat-scripts.git \
  "${scripts_path}" || exit

rm -rf "${scripts_path}/.git" || exit
rm -rf "${scripts_path}/.github" || exit

pip install -r "${scripts_path}/requirements.txt"
