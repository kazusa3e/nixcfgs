HOST ?= $(shell hostname -s)

.DEFAULT_GOAL := help
.PHONY: help check-host install sync history pin unpin

help:
	@printf '%s\n' \
		'make install [HOST=name]  Install for the selected host' \
		'make sync    [HOST=name]  Apply the existing locked configuration' \
		'make history PACKAGE=name  Show recorded package upgrades and revisions' \
		'make pin PACKAGE=name REV=hash  Pin a tool to a nixpkgs revision' \
		'make pin PACKAGE=name FROM=commit INPUT=input  Pin from a historical lock' \
		'make unpin PACKAGE=name  Restore the configured package source' \
		'Default host: $(HOST). Install/sync do not update flake.lock or deploy remotely.'

history:
	python3 -B scripts/pin_package.py history "$(PACKAGE)"

pin:
	python3 -B scripts/pin_package.py pin "$(PACKAGE)" \
		$(if $(REV),--rev "$(REV)") $(if $(FROM),--from "$(FROM)") $(if $(INPUT),--input "$(INPUT)")

unpin:
	python3 -B scripts/pin_package.py unpin "$(PACKAGE)"

check-host:
	@nix eval --raw --file ./hosts \
		--apply 'hosts: if builtins.hasAttr "$(HOST)" hosts then "" else throw "Unknown host: $(HOST)"'

ifeq ($(HOST),arashi)
install sync: check-host
	sudo nixos-rebuild switch --flake ".#$(HOST)" --no-update-lock-file
else
install: check-host
	nix profile add --no-update-lock-file ".#$(HOST)"

sync: check-host
	nix profile upgrade --no-update-lock-file "$(HOST)"
endif
