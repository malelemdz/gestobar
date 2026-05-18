#!/bin/bash

# Colores elegantes para la terminal
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}======================================================${NC}"
# Flag especial de sembrado (--seed)
if [ "$1" == "--seed" ]; then
    echo -e "${YELLOW}Ejecutando seeding de la base de datos Gestobar...${NC}"
    SEED_RESPONSE=$(curl -s -X POST http://localhost:3000/seed)
    
    if [[ $SEED_RESPONSE == *"Seed completado con éxito"* ]]; then
        echo -e "${GREEN}✓ ¡Base de datos sembrada con éxito!${NC}"
        echo -e "${CYAN}------------------------------------------------------${NC}"
        echo -e "${GREEN}Credenciales de desarrollo listas:${NC}"
        echo -e "  • SuperAdmin: superadmin / superpassword"
        echo -e "  • Admin Local: admin / adminpassword"
        echo -e "  • Cajero/Barman: barman / barmanpassword"
        echo -e "  • Dama: dama / damapassword"
        echo -e "${CYAN}------------------------------------------------------${NC}"
    else
        echo -e "${RED}⚠️  No se pudo completar el seeding. Asegúrate de que el backend ya esté corriendo en la otra pestaña.${NC}"
    fi
    exit 0
fi

# 1. Comprobar si OrbStack / Docker Daemon está corriendo
echo -e "\n${YELLOW}[1/4] Verificando estado de OrbStack...${NC}"
if ! docker info >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  OrbStack no está activo. Iniciándolo automáticamente...${NC}"
    open -a OrbStack
    # Esperar a que el demonio esté listo
    while ! docker info >/dev/null 2>&1; do
        echo -n "."
        sleep 1
    done
    echo ""
    echo -e "${GREEN}✓ OrbStack iniciado correctamente.${NC}"
else
    echo -e "${GREEN}✓ OrbStack ya está activo y corriendo.${NC}"
fi

# 2. Levantar el contenedor de la Base de Datos
echo -e "\n${YELLOW}[2/4] Levantando contenedor de PostgreSQL (Puerto 5434)...${NC}"
docker-compose up -d
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Contenedor PostgreSQL levantado en segundo plano.${NC}"
else
    echo -e "${RED}✗ Error al levantar la base de datos con docker-compose.${NC}"
    exit 1
fi

# 3. Esperar a que PostgreSQL acepte conexiones
echo -e "\n${YELLOW}[3/4] Esperando a que PostgreSQL esté listo en el puerto 5434...${NC}"
while ! nc -z localhost 5434; do
  echo -n "."
  sleep 0.5
done
echo ""
echo -e "${GREEN}✓ PostgreSQL está listo para recibir conexiones.${NC}"

# 4. Iniciar el Backend NestJS en primer plano (Foreground)
echo -e "\n${YELLOW}[4/4] Iniciando servidor Backend NestJS en primer plano...${NC}"
echo -e "${GREEN}🚀 Servidor listo. Los logs de NestJS se imprimirán a continuación en tiempo real.${NC}"
echo -e "${CYAN}💡 NOTA: Si necesitas sembrar la base de datos, abre otra pestaña de terminal en VS Code y ejecuta:${NC} ${YELLOW}./dev.sh --seed${NC}"
echo -e "${RED}Presiona Ctrl + C o cierra esta pestaña para matar el backend por completo (sin procesos huérfanos).${NC}\n"

cd backend
exec npm run start:dev

