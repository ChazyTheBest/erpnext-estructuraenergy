.PHONY: init envs traefik db erpnext site locale backups all status stop system-settings
init:       ; bash scripts/00_init.sh
envs:       ; bash scripts/05_render_envs.sh
traefik:    ; bash scripts/10_traefik_up.sh
db:         ; bash scripts/20_mariadb_up.sh
erpnext:    ; bash scripts/30_erpnext_up.sh
site:       ; bash scripts/40_site_new.sh
locale:     ; bash scripts/41_site_locale.sh
system-settings: ; bash scripts/42_site_system_settings.sh
backups:    ; bash scripts/60_backups_install.sh
status:     ; bash scripts/90_status.sh
all: init envs traefik db erpnext site locale system-settings backups status
stop:       ; bash scripts/80_stop.sh all