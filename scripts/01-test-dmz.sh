#!/usr/bin/env bash
# 01-test-dmz.sh — Pruebas de seguridad de la DMZ
# Ejecutar en cualquier servidor de la DMZ (caja, inventario o datos).
# Edita las IP de los usuarios con las que recibieron por DHCP (comando: ip a).
 
GW_DMZ="10.22.42.1"
USER_VLAN10="10.22.41.10"     # IP de vlan10-usuario
USER_VLAN20="10.22.41.140"    # IP de vlan20-usuario
 
PASS=0; FAIL=0
 
# check "descripción" ok|fail comando...
check() {
  local desc="$1" expect="$2" result
  shift 2
  if "$@" >/dev/null 2>&1; then result=ok; else result=fail; fi
  if [ "$result" = "$expect" ]; then
    echo "[PASS] $desc"; PASS=$((PASS + 1))
  else
    echo "[FAIL] $desc (esperado: $expect, obtenido: $result)"; FAIL=$((FAIL + 1))
  fi
}
 
echo "== DMZ: $(hostname) — $(date '+%F %T') =="
check "Gateway de la DMZ responde"              ok   ping -c 2 -W 2 "$GW_DMZ"
check "Sin acceso a usuarios VLAN 10"           fail ping -c 2 -W 2 "$USER_VLAN10"
check "Sin acceso a usuarios VLAN 20"           fail ping -c 2 -W 2 "$USER_VLAN20"
check "Sin ping abierto a Internet (8.8.8.8)"   fail ping -c 2 -W 2 8.8.8.8
check "DNS resuelve archive.ubuntu.com"         ok   getent hosts archive.ubuntu.com
check "HTTP al repositorio de Ubuntu permitido" ok   curl -sI --max-time 5 http://archive.ubuntu.com
check "HTTP a example.com bloqueado"            fail curl -sI --max-time 5 http://example.com
check "HTTPS a example.com bloqueado"           fail curl -sI --max-time 5 https://example.com
 
echo "-- Resultado: $PASS aprobadas, $FAIL fallidas --"
[ "$FAIL" -eq 0 ]
