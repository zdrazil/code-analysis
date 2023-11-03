bin_path := $(HOME)/bin
src_path := $(shell pwd)/src
scripts_path := scripts
cache_path := cache

all: build

install: build install_wrappers install_maat

build: clone_scripts download_maat
	pip install -r $(scripts_path)/requirements.txt

clone_scripts:
	echo "$(scripts_path)"
	test -d $(scripts_path) || git clone \
		--depth=1 \
		--branch=python3 \
		'https://github.com/adamtornhill/maat-scripts.git' \
		"$(scripts_path)" \
	&& rm -rf "$(scripts_path)/.git" \
	&& rm -rf "$(scripts_path)/.github"

cache_maat := "$(cache_path)/code-maat-1.0.4-standalone.jar"

# commit which was tested: 3f1afce263b193c41756af53a4cd8fc5553a3357
download_maat:
	mkdir -p $(cache_path)
	test -f $(cache_maat) || wget --show-progress \
		--no-cache \
		--output-document $(cache_maat) \
		"https://github.com/adamtornhill/code-maat/releases/download/v1.0.4/code-maat-1.0.4-standalone.jar"

install_maat: download_maat
	cp "$(src_path)/commands/maat.sh" "$(bin_path)/maat"
	cp "$(cache_path)/code-maat-1.0.4-standalone.jar" "$(bin_path)/code-maat.jar"

install_wrappers:
	ln -s "$(src_path)/analyze.sh" "$(bin_path)/maat-analyze"
	ln -s "$(src_path)/analyze-complexity-trend.sh" "$(bin_path)/maat-analyze-complexity-trend"
	ln -s "$(src_path)/filter-reports.sh" "$(bin_path)/maat-filter"

uninstall:
	rm "$(bin_path)/maat-analyze" || true
	rm "$(bin_path)/maat-analyze-complexity-trend" || true
	rm "$(bin_path)/maat-filter" || true
	rm "$(bin_path)/code-maat.jar" || true
	rm "$(bin_path)/maat" || true

clean:
	rm -r "$(cache_path)" || true
	rm -r "$(scripts_path)" || true