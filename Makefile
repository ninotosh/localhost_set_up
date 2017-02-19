.PHONY: all
all:
	@echo 'run "make run" instead'

.PHONY: install
install: install_ansible

.PHONY: install_ruby
install_ruby:
ifeq ($(shell test -x /usr/bin/ruby && echo $$?), 0)
	@true
else
	$(error ruby not installed)
endif

.PHONY: install_curl
install_curl:
ifeq ($(shell which curl > /dev/null && echo $$?), 0)
	@true
else
	$(error curl not installed)
endif

.PHONY: install_brew
install_brew: install_ruby install_curl
	@which brew || /usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

.PHONY: install_ansible
install_ansible: install_brew
	@brew list --versions ansible || (brew update && brew install ansible)

.PHONY: run
run: install
	ansible-playbook site.yml

.PHONY: clean
clean: install_brew
	-brew cask cleanup
	-brew cleanup

.PHONY: uninstall_brew
uninstall_brew: install_ruby install_curl
	ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"

.PHONY: uninstall_ansible
uninstall_ansible: install_brew
	brew uninstall ansible
