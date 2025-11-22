.PHONY: init envs traefik db erpnext site locale backups lint all all-nobackup status start restart stop destroy
init:       ; bash scripts/00_init.sh
envs:       ; bash scripts/05_render_envs.sh
traefik:    ; bash scripts/10_traefik_up.sh
db:         ; bash scripts/20_mariadb_up.sh
erpnext:    ; bash scripts/30_erpnext_up.sh
site:       ; bash scripts/40_site_new.sh
locale:     ; bash scripts/41_site_locale.sh
backups:    ; bash scripts/60_backups_install.sh
lint:       ; bash scripts/lint.sh
status:     ; bash scripts/90_status.sh
start:      ; bash scripts/70_start.sh all
restart:    ; bash scripts/85_restart.sh all
all: init envs traefik db erpnext site locale backups status
all-nobackup: init envs traefik db erpnext site locale status
stop:       ; bash scripts/80_stop.sh all
destroy:    ; bash scripts/99_destroy.sh
