#!/usr/bin/env bash
# 02-test-usuario.sh — Pruebas de acceso de un usuario hacia la DMZ
# Uso:  ./02-test-usuario.sh 10    (en vlan10-usuario)
#       ./02-test-usuario.sh 20    (en vlan20-usuario)

VLAN="${1:-}"
CAJA="10.22.42.2"
INVENTARIO="10.22.42.3"
DATOS="10.22.42.4"

case "$VLAN" in
  10) GW="10.22.41.1" ;;
  20) GW="10.22.41.129" ;;
  *)  echo "Uso: $0 10|20"; exit 2 ;;
esac

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

# port_open host puerto  -> éxito si el puerto TCP responde en 3 segundos
port_open() { timeout 3 bash -c "</dev/tcp/$1/$2" 2>/dev/null; }

echo "== Usuario VLAN $VLAN: $(hostname) — $(date '+%F %T') =="
check "IP por DHCP en la red de usuarios" ok bash -c "ip -4 -o addr show | grep -q ' 10\.22\.41\.'"
check "Gateway ($GW) responde"            ok ping -c 2 -W 2 "$GW"

# SSH: solo la VLAN 20 puede entrar a los servidores
if [ "$VLAN" = "20" ]; then SSH_ESPERADO=ok; else SSH_ESPERADO=fail; fi
for host in "$CAJA" "$INVENTARIO" "$DATOS"; do
  check "SSH (22) hacia $host" "$SSH_ESPERADO" port_open "$host" 22
done

# VLAN 10: el Sistema de Inventario debe mostrar la página de violación
if [ "$VLAN" = "10" ]; then
  check "Inventario muestra la página de bloqueo" ok \
    bash -c "curl -s --max-time 5 http://$INVENTARIO | grep -qi blocked"
fi

# Ninguna VLAN de usuarios debe llegar directo a la base de datos
for puerto in 3306 5432; do
  check "Puerto de base de datos $puerto hacia $DATOS bloqueado" fail port_open "$DATOS" "$puerto"
done

echo "-- Resultado: $PASS aprobadas, $FAIL fallidas --"
[ "$FAIL" -eq 0 ]
