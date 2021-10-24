PKGNAME ?= grub-btrfs
PREFIX ?= /usr

INITCPIO ?= false

SHARE_DIR = $(DESTDIR)$(PREFIX)/share
LIB_DIR = $(DESTDIR)$(PREFIX)/lib
BIN_DIR = $(DESTDIR)$(PREFIX)/bin
OPENRC =  $(shell strings /sbin/init | grep -q "sysvinit" && echo true || echo false)
SYSTEMD = $(shell test -d /run/systemd/system && echo true || echo false)

.PHONY: install uninstall help

install:
	@if test "$(shell id -u)" != 0; then \
		echo "You are not root, run this target as root please."; \
		exit 1; \
	fi
	@install -Dm755 -t "$(DESTDIR)/etc/grub.d/" 41_snapshots-btrfs
	@install -Dm644 -t "$(DESTDIR)/etc/default/grub-btrfs/" config
	@# Systemd detected on system, install systemd service
	@if [[ $(SYSTEMD) = true ]]; then \
		install -Dm644 -t "$(LIB_DIR)/systemd/system/" grub-btrfs.path; \
		install -Dm644 -t "$(LIB_DIR)/systemd/system/" grub-btrfs.service; \
        fi
	@# OpenRC detected on system, install OpenRC daemon
	@if [[ $(OPENRC) = true ]]; then \
		install -Dm744 -t "$(BIN_DIR)/" grub-btrfs-openrc; \
		install -Dm744 -t "$(DESTDIR)/init.d/" grub-btrfsd; \
        fi
	@# Arch Linux like distros only :
	@if test "$(INITCPIO)" = true; then \
		install -Dm644 "initramfs/Arch Linux/overlay_snap_ro-install" "$(LIB_DIR)/initcpio/install/grub-btrfs-overlayfs"; \
		install -Dm644 "initramfs/Arch Linux/overlay_snap_ro-hook" "$(LIB_DIR)/initcpio/hooks/grub-btrfs-overlayfs"; \
	 fi
	@install -Dm644 -t "$(SHARE_DIR)/licenses/$(PKGNAME)/" LICENSE 
	@install -Dm644 -t "$(SHARE_DIR)/doc/$(PKGNAME)/" README.md
	@install -Dm644 "initramfs/readme.md" "$(SHARE_DIR)/doc/$(PKGNAME)/initramfs-overlayfs.md"

uninstall:
	@if test "$(shell id -u)" != 0; then \
		echo "You are not root, run this target as root please."; \
		exit 1; \
	fi
	@grub_dirname="$$(grep -oP '^[[:space:]]*GRUB_BTRFS_GRUB_DIRNAME=\K.*' "$(DESTDIR)/etc/default/grub-btrfs/config" | sed "s|\s*#.*||;s|(\s*\(.\+\)\s*)|\1|;s|['\"]||g")"; \
	 rm -f "$${grub_dirname:-/boot/grub}/grub-btrfs.cfg"
	@rm -f "$(DESTDIR)/etc/default/grub-btrfs/config"
	@rm -f "$(DESTDIR)/etc/grub.d/41_snapshots-btrfs"
	@if [[ $(SYSTEMD) = true ]]; then \
		rm -f "$(LIB_DIR)/systemd/system/grub-btrfs.path; \
		rm -f "$(LIB_DIR)/systemd/system/grub-btrfs.service; \
        fi
	@# OpenRC detected on system, install OpenRC daemon
	@if [[ $(OPENRC) = true ]]; then \
		rm -f "$(BIN_DIR)/grub-btrfs.openrcbin; \
		rm -f "$(DESTDIR)/init.d/grub-btrfs.openrc; \
        fi
	@rm -f "$(LIB_DIR)/initcpio/install/grub-btrfs-overlayfs"
	@rm -f "$(LIB_DIR)/initcpio/hooks/grub-btrfs-overlayfs"
	@# Arch Linux UNlike distros only :
	@if test "$(INITCPIO)" != true && test -d "$(LIB_DIR)/initcpio"; then \
		rmdir --ignore-fail-on-non-empty "$(LIB_DIR)/initcpio/install" || :; \
		rmdir --ignore-fail-on-non-empty "$(LIB_DIR)/initcpio/hooks" || :; \
		rmdir --ignore-fail-on-non-empty "$(LIB_DIR)/initcpio" || :; \
	 fi
	@rm -f "$(SHARE_DIR)/doc/$(PKGNAME)/README.md"
	@rm -f "$(SHARE_DIR)/doc/$(PKGNAME)/initramfs-overlayfs.md"
	@rm -f "$(SHARE_DIR)/licenses/$(PKGNAME)/LICENSE"
	@rmdir --ignore-fail-on-non-empty "$(SHARE_DIR)/doc/$(PKGNAME)/" || :
	@rmdir --ignore-fail-on-non-empty "$(SHARE_DIR)/licenses/$(PKGNAME)/" || :
	@rmdir --ignore-fail-on-non-empty "$(DESTDIR)/etc/default/grub-btrfs" || :

help:
	@echo
	@echo "Usage: $(MAKE) [ <parameter>=<value> ... ] [ <action> ]"
	@echo
	@echo "  actions: install"
	@echo "           uninstall"
	@echo "           help"
	@echo
	@echo "  parameter | type | description                    | defaults"
	@echo "  ----------+------+--------------------------------+----------------------------"
	@echo "  DESTDIR   | path | install destination            | <unset>"
	@echo "  PREFIX    | path | system tree prefix             | '/usr'"
	@echo "  SHARE_DIR | path | shared data location           | '\$$(DESTDIR)\$$(PREFIX)/share'"
	@echo "  LIB_DIR   | path | system libraries location      | '\$$(DESTDIR)\$$(PREFIX)/lib'"
	@echo "  PKGNAME   | name | name of the ditributed package | 'grub-btrfs'"
	@echo "  INITCPIO  | bool | include mkinitcpio hook        | false"
	@echo
