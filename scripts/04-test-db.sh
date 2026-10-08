#!/usr/bin/env bash
# 04-test-db.sh — Conectividad hacia la base de datos del servidor de datos
# Ejecutar en un servidor web de la DMZ (caja o inventario).
# Uso:  ./04-test-db.sh [IP_DEL_SERVIDOR_DE_DATOS]     (por defecto 10.22.42.4)
#
# Consulta de prueba opcional (las credenciales NO se guardan en el script):
#   export DB_USER=usuario DB_PASS=contraseña
#   ./04-test-db.sh

DATOS="${1:-10.22.42.4}"

# port_open host puerto  -> éxito si el puerto TCP responde en 3 segundos
port_open() { timeout 3 bash -c "</dev/tcp/$1/$2" 2>/dev/null; }

echo "== Servidor de datos ($DATOS) probado desde $(hostname) — $(date '+%F %T') =="

ENCONTRADA=0
for entrada in "3306:MySQL/MariaDB" "5432:PostgreSQL"; do
  puerto="${entrada%%:*}"
  nombre="${entrada#*:}"
  if port_open "$DATOS" "$puerto"; then
    echo "[OK]  $nombre responde en el puerto $puerto"
    ENCONTRADA=1
  else
    echo "[--]  $nombre sin respuesta en el puerto $puerto"
  fi
done

if [ "$ENCONTRADA" -eq 0 ]; then
  echo "[FAIL] No se encontró un servicio de base de datos accesible en $DATOS"
  exit 1
fi

# Consulta de prueba, solo si se definieron DB_USER y DB_PASS
if [ -n "${DB_USER:-}" ] && [ -n "${DB_PASS:-}" ]; then
  if command -v mysql >/dev/null && port_open "$DATOS" 3306; then
    MYSQL_PWD="$DB_PASS" mysql -h "$DATOS" -u "$DB_USER" -e "SELECT 'consulta OK' AS resultado;"
  elif command -v psql >/dev/null && port_open "$DATOS" 5432; then
    PGPASSWORD="$DB_PASS" psql -h "$DATOS" -U "$DB_USER" -c "SELECT 'consulta OK' AS resultado;"
  else
    echo "Cliente de base de datos no instalado; se omite la consulta de prueba."
  fi
fi
