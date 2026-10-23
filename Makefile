HOST ?= $(shell hostname -s)

.DEFAULT_GOAL := help
.PHONY: help check-host install update

help:
	@printf '%s\n' \
		'make install [HOST=name]  Install for the selected host' \
		'make update  [HOST=name]  Apply the existing locked configuration' \
		'Default host: $(HOST). No remote deployment or flake.lock updates.'

check-host:
	@nix eval --raw --file ./hosts.nix \
		--apply 'hosts: if builtins.hasAttr "$(HOST)" hosts then "" else throw "Unknown host: $(HOST)"'

ifeq ($(HOST),arashi)
install update: check-host
	sudo nixos-rebuild switch --flake ".#$(HOST)" --no-update-lock-file
else
install: check-host
	nix profile add --no-update-lock-file ".#$(HOST)"

update: check-host
	nix profile upgrade --no-update-lock-file "$(HOST)"
endif
