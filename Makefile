init:
	@echo You probably want to run "zig build" instead.
.PHONY: init

# glad updates the GLAD loader. To use this, place the generated glad.zip
# in this directory next to the Makefile, remove vendor/glad and run this target.
#
# Generator: https://gen.glad.sh/
glad: vendor/glad
.PHONY: glad

vendor/glad: vendor/glad/include/glad/gl.h vendor/glad/include/glad/glad.h

vendor/glad/include/glad/gl.h: glad.zip
	rm -rf vendor/glad
	mkdir -p vendor/glad
	unzip glad.zip -dvendor/glad
	find vendor/glad -type f -exec touch '{}' +

vendor/glad/include/glad/glad.h: vendor/glad/include/glad/gl.h
	@echo "#include <glad/gl.h>" > $@

clean:
	rm -rf \
		zig-out .zig-cache \
		macos/build \
		macos/GhosttyKit.xcframework
.PHONY: clean

# Local macOS build of this fork (upstream PR #9857) for Apple Silicon.
# Run `make install` to build and install to ~/Applications.
ZIG_VERSION := $(shell sed -n 's/.*minimum_zig_version = "\(.*\)".*/\1/p' build.zig.zon)
ZIG := mise exec zig@$(ZIG_VERSION) -- zig
# The zig build maps ReleaseFast to the Xcode "ReleaseLocal" configuration.
APP := macos/build/ReleaseLocal/Ghostty.app
INSTALL_DIR ?= $(HOME)/Applications
# Self-signed identity used to sign the installed app. A stable signature
# keeps macOS permissions (e.g. Accessibility for global keybinds) granted
# across rebuilds; ad-hoc signatures change on every build.
SIGN_IDENTITY := Ghostty Local Signing
KEYCHAIN := $(HOME)/Library/Keychains/login.keychain-db
# Upstream PR branch this fork tracks.
FORK_REPO := https://github.com/adrum/ghostty
FORK_BRANCH := feat/quickterm-with-tab

##@ Local macOS Build

setup: setup-zig setup-metal setup-cert ## Install the Zig/Metal toolchains and signing certificate
.PHONY: setup

setup-zig:
	@mise where zig@$(ZIG_VERSION) >/dev/null 2>&1 || mise install zig@$(ZIG_VERSION)
.PHONY: setup-zig

setup-metal:
	@xcrun -sdk macosx metal --version >/dev/null 2>&1 || xcodebuild -downloadComponent MetalToolchain
.PHONY: setup-metal

setup-cert:
	@if ! security find-certificate -c "$(SIGN_IDENTITY)" "$(KEYCHAIN)" >/dev/null 2>&1; then \
		set -e; tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
		/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
			-subj "/CN=$(SIGN_IDENTITY)" \
			-addext "basicConstraints=critical,CA:false" \
			-addext "keyUsage=critical,digitalSignature" \
			-addext "extendedKeyUsage=critical,codeSigning" \
			-keyout "$$tmp/key.pem" -out "$$tmp/cert.pem"; \
		/usr/bin/openssl pkcs12 -export -inkey "$$tmp/key.pem" -in "$$tmp/cert.pem" \
			-out "$$tmp/identity.p12" -passout pass:ghostty; \
		security import "$$tmp/identity.p12" -k "$(KEYCHAIN)" -P ghostty -T /usr/bin/codesign; \
	fi
.PHONY: setup-cert

build: setup ## Build Ghostty.app (ReleaseFast, native arm64 only)
	$(ZIG) build -Doptimize=ReleaseFast -Dxcframework-target=native
.PHONY: build

# Re-signs only the outer bundle with the local identity. Nested code keeps its
# ad-hoc signature, which loads fine because the app disables library validation.
install: build ## Build, install to ~/Applications, and sign Ghostty.app
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_DIR)/Ghostty.app"
	ditto "$(APP)" "$(INSTALL_DIR)/Ghostty.app"
	codesign --force --sign "$(SIGN_IDENTITY)" \
		--preserve-metadata=identifier,entitlements,flags \
		"$(INSTALL_DIR)/Ghostty.app"
	@echo "Installed $(INSTALL_DIR)/Ghostty.app. Restart Ghostty to pick up the new build."
.PHONY: install

run: ## Launch the built app without installing it
	open "$(APP)"
.PHONY: run

sync-fork: ## Merge the latest PR branch from adrum/ghostty into this branch
	git pull --no-rebase $(FORK_REPO) $(FORK_BRANCH)
.PHONY: sync-fork

################################################
# Auto-Generated Help:
# - "##@" denotes a target category
# - "##" denotes a specific target description
###############################################
.DEFAULT_GOAL := help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-19s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
.PHONY: help
