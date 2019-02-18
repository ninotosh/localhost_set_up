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
install_brew: ruby_exists curl_exists
	@which brew || /usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

.PHONY: install_ansible
install_ansible: install_brew
	@brew list --versions ansible || (brew update && brew install ansible)

.PHONY: run
run: install play clean_cache clear_formulae

.PHONY: play
play:
	ansible-playbook site.yml

.PHONY: clean_cache
clean_cache: install_brew
	-brew cleanup

.PHONY: generate_MacOSX_homebrew_formulae_vars_yml
generate_MacOSX_homebrew_formulae_vars_yml:
	@echo '# state: absent | present | latest'
	@echo '# put "formulae: []" to do nothing'
	@echo 'formulae:'
	@for f in `brew list`; do echo "  - name: $$f"; echo "    state: present"; done

.PHONY: generate_MacOSX_homebrew_casks_vars_yml
generate_MacOSX_homebrew_casks_vars_yml:
	@echo "cask_options: 'appdir=\$$HOME/Applications'"
	@echo '# state: absent | present'
	@echo '# put "casks: []" to do nothing'
	@echo 'casks:'
	@for f in `brew cask list`; do echo "  - name: $$f"; echo "    state: present"; done

.PHONY: export_homebrew
export_homebrew:

.PHONY: uninstall_brew
uninstall_brew: ruby_exists curl_exists
	ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"

TEMP_PRESENT := $(shell mktemp)
TEMP_UNINSTALLABLE := $(shell mktemp)
FORMULAE_VARS := MacOSX/homebrew/formulae/vars.yml
.PHONY: clear_formulae
clear_formulae: ruby_exists install_brew
	@/usr/bin/ruby -ryaml -e 'puts YAML.load_file("$(FORMULAE_VARS)")["formulae"].map{|f| puts f["name"] if ["present", "latest"].include?(f["state"])}.compact' > $(TEMP_PRESENT)
	@brew list | grep -v -f $(TEMP_PRESENT) > $(TEMP_UNINSTALLABLE); true
	@for i in `cat $(TEMP_UNINSTALLABLE)`; do \
		for f in `brew list | grep -v -f $(TEMP_PRESENT)`; do \
			brew list --versions $$f > /dev/null && brew uninstall $$f 2> /dev/null; \
		done \
	done
	@rm $(TEMP_PRESENT) $(TEMP_UNINSTALLABLE)
