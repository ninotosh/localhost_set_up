.PHONY: all
all: help

.PHONY: help
help: list
	@echo
	@echo Edit the files above and do \"make run\".
	@echo
	@echo The commands below will help you edit \"vars.yml\" files for Homebrew.
	@echo make generate_MacOSX_homebrew_formulae_vars_yml
	@echo make generate_MacOSX_homebrew_casks_vars_yml

.PHONY: list
list:
	@find . -name 'vars.yml' -o -name '*.j2'

.PHONY: install
install: install_ansible

.PHONY: ruby_exists
ruby_exists:
	@if [ ! -x /usr/bin/ruby ]; then echo ruby not installed; false; fi

.PHONY: curl_exists
curl_exists:
	@if [ -z `which curl` ]; then echo curl not installed; false; fi

.PHONY: install_brew
install_brew: curl_exists
	@which brew || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

.PHONY: update_brew
update_brew: install_brew
	@brew update

.PHONY: install_ansible
install_ansible: install_brew update_brew
	@brew list --versions ansible || brew install ansible

.PHONY: run
run: install play uninstall

.PHONY: play
play:
	ansible-playbook site.yml

.PHONY: generate_MacOSX_homebrew_formulae_vars_yml
generate_MacOSX_homebrew_formulae_vars_yml:
	@echo '# state: absent | present | upgraded'
	@echo '# put "formulae: []" to do nothing'
	@echo 'formulae:'
	@for f in `brew list`; do echo "  - name: $$f"; echo "    state: upgraded"; done

.PHONY: generate_MacOSX_homebrew_casks_vars_yml
generate_MacOSX_homebrew_casks_vars_yml:
	@echo '# state: absent | present | upgraded'
	@echo '# put "casks: []" to do nothing'
	@echo 'casks:'
	@for f in `brew list --cask`; do echo "  - name: $$f"; echo "    state: upgraded"; done

.PHONY: uninstall
uninstall: clean_cache clear_formulae

# also removes installed packages
.PHONY: uninstall_brew
uninstall_brew: curl_exists
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"

.PHONY: clean_cache
clean_cache: install_brew
	-brew cleanup

TEMP_PRESENT := $(shell mktemp)
TEMP_UNINSTALLABLE := $(shell mktemp)
FORMULAE_VARS := MacOSX/homebrew/formulae/vars.yml
# this may remove packages needed by installed packages
.PHONY: clear_formulae
clear_formulae: ruby_exists install_brew
	@/usr/bin/ruby -ryaml -e 'puts YAML.load_file("$(FORMULAE_VARS)")["formulae"].map{|f| puts f["name"] if ["present", "upgraded"].include?(f["state"])}.compact' > $(TEMP_PRESENT)
	@brew list | grep -v -f $(TEMP_PRESENT) > $(TEMP_UNINSTALLABLE); true
	@for i in `cat $(TEMP_UNINSTALLABLE)`; do \
		for f in `brew list | grep -v -f $(TEMP_PRESENT)`; do \
			brew list --versions $$f > /dev/null && brew uninstall $$f 2> /dev/null || true; \
		done \
	done
	@rm $(TEMP_PRESENT) $(TEMP_UNINSTALLABLE)
