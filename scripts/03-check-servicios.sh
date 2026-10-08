#!/usr/bin/env bash
# 03-check-servicios.sh — Servicios activos y puertos en escucha de un servidor
# Ejecutar en caja, inventario o datos. Solo muestra los servicios que estén instalados.

echo "== Servicios de $(hostname) ($(hostname -I | awk '{print $1}')) — $(date '+%F %T') =="

for svc in ssh apache2 nginx mysql mariadb postgresql; do
  if systemctl list-unit-files "$svc.service" 2>/dev/null | grep -q "^$svc.service"; then
    printf '%-12s %s\n' "$svc" "$(systemctl is-active "$svc")"
  fi
done

echo
echo "Puertos TCP en escucha:"
ss -tln | awk 'NR > 1 { n = split($4, a, ":"); print a[n] }' | sort -un | tr '\n' ' '
echo
