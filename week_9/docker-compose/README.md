# Week 9: Multi-Container Orchestration (Docker Compose)

## Objetivo

Coordinar múltiples contenedores que trabajan juntos en un único stack definido en un fichero `docker-compose.yml`. El objetivo no es solo que los servicios arranquen, sino que se comuniquen, persistan datos y sean fáciles de operar.

---

## Estructura

```
week_9/
└── docker-compose/
    ├── docker-compose.yml  # Definición del stack completo
    ├── .env.example        # Plantilla de variables de entorno
    ├── .gitignore          # Excluye .env del repositorio
    └── README.md           # Esta documentación
```

---

## Arquitectura del stack

```
                        ┌─────────────────────────────────────────┐
  Internet              │              Docker Host                 │
  ──────────            │                                          │
  :80 ──────────────────┤──▶  [nginx]          red: frontend      │
  :3000 ────────────────┤──▶  [simple-app]     red: frontend      │
                        │        │              red: backend       │
                        │        ▼                                 │
                        │     [redis]           red: backend       │
                        │                                          │
                        │  Volumes:                                │
                        │    app-data ──▶ simple-app:/app/data     │
                        │    redis-data ──▶ redis:/data            │
                        └─────────────────────────────────────────┘
```

### Flujo de tráfico

1. El cliente accede a `:80` → **nginx** sirve contenido estático
2. El cliente accede a `:3000` → **simple-app** responde directamente (también accesible desde nginx internamente via `http://simple-app:3000`)
3. **simple-app** puede comunicarse con **redis** en `redis:6379` (red backend, no expuesta al exterior)

---

## Servicios

### nginx

- **Imagen**: `sssalma/nginx-gsx:v1` (construida en Week 8)
- **Puerto**: `80:80`
- **Red**: `frontend` únicamente — nginx no necesita acceder a redis directamente
- **Dependencia**: arranca solo después de que `simple-app` esté healthy (no solo "started")
- **Por qué este orden**: si nginx intenta hacer proxy al backend antes de que esté listo, fallará con connection refused. `condition: service_healthy` usa el healthcheck del backend para esperar de verdad.

### simple-app

- **Imagen**: `sssalma/simple-app-gsx:v1` (corrección del nombre respecto al commit anterior)
- **Puerto**: `3000:3000`
- **Redes**: `frontend` (accesible desde nginx y el host) + `backend` (accede a redis)
- **Volumen**: `app-data:/app/data` — cualquier fichero que la app escriba en `/app/data` sobrevive a reinicios del contenedor
- **Variables de entorno**: `APP_ENV` y `PORT` leídas del `.env`

### redis

- **Imagen**: `redis:7-alpine` — elegimos Alpine por el mismo motivo que en Week 8: mucho más ligero que `redis:latest`
- **Red**: solo `backend` — redis no tiene por qué ser accesible desde el exterior ni desde nginx
- **Volumen**: `redis-data:/data` — redis persiste los datos en disco. Sin este volumen, un `docker compose down` haría perder todo el estado

---

## Redes personalizadas

Se definen dos redes:

| Red | Servicios | Motivo |
|-----|-----------|--------|
| `frontend` | nginx, simple-app | Tráfico web orientado al usuario |
| `backend` | simple-app, redis | Datos internos, no expuestos al exterior |

Esto aplica el principio de **menor exposición**: redis no es accesible desde nginx ni desde el host, solo desde los servicios que realmente lo necesitan.

Si se usara la red por defecto de Compose (sin declarar redes), todos los servicios estarían en la misma red y podrían comunicarse entre sí sin restricción. Las redes personalizadas permiten segmentar el tráfico y es la práctica recomendada para producción.

---

## Persistencia de datos

Se definen dos volúmenes:

- **`app-data`**: montado en `/app/data` dentro de `simple-app`. Para que la app pueda escribir datos (logs, ficheros generados) que no se pierdan al reiniciar el contenedor.
- **`redis-data`**: montado en `/data` dentro de `redis`. Redis usa este directorio para guardar snapshots RDB. Sin él, un `docker compose down` implicaría perder todos los datos en memoria.

### Verificación de persistencia

```bash
# Escribir algo en el volumen desde el contenedor
docker compose exec simple-app sh -c "echo 'test' > /app/data/test.txt"

# Parar y eliminar los contenedores (no los volúmenes)
docker compose down

# Volver a arrancar
docker compose up -d

# Comprobar que el fichero sigue ahí
docker compose exec simple-app cat /app/data/test.txt
# Salida esperada: test
```

---

## Health checks

Cada servicio define su propio healthcheck:

```yaml
healthcheck:
  test: [...]      # Comando que prueba la salud del servicio
  interval: 30s    # Cada cuánto se ejecuta
  timeout: 5s      # Cuánto esperar la respuesta
  retries: 3       # Cuántos fallos antes de marcar unhealthy
  start_period: 10s  # Tiempo de gracia al arrancar
```

- **nginx**: hace `curl -f http://localhost:80`. Si nginx no responde en 5s, falla.
- **simple-app**: usa `wget --spider` al endpoint `/health` que definimos en Week 8. Este endpoint existe precisamente para esto.
- **redis**: usa `redis-cli ping`. Redis responde con `PONG` si está operativo.

Los health checks permiten que `depends_on: condition: service_healthy` funcione correctamente y que Docker sepa cuándo un servicio está realmente listo.

---

## Configuración y secretos

La configuración se gestiona con variables de entorno:

```bash
# Copiar la plantilla
cp .env.example .env

# Editar .env con valores reales (nunca comitear .env)
nano .env
```

El fichero `.env` está en `.gitignore`. Solo se sube `.env.example` con valores de ejemplo (sin secretos reales).

**Por qué variables de entorno y no hardcoded**: si el puerto o el entorno estuviera fijo en el YAML, habría que modificar el fichero para cada despliegue. Con variables, basta cambiar el `.env`.

---

## Logging

Todos los servicios usan el driver `json-file` con límite de tamaño:

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

Esto evita que los logs crezcan sin límite y llenen el disco. Con estas opciones Docker guarda máximo 3 ficheros de 10MB cada uno (30MB máximo por servicio) y va rotando.

Para ver los logs:

```bash
docker compose logs -f              # todos los servicios
docker compose logs -f simple-app  # solo simple-app
```

---

## Comandos de operación

```bash
# Arrancar el stack en background
docker compose up -d

# Ver estado de los servicios
docker compose ps

# Ver logs en tiempo real
docker compose logs -f

# Probar comunicación entre servicios
docker compose exec nginx curl http://simple-app:3000
docker compose exec nginx curl http://simple-app:3000/health

# Probar que redis responde desde simple-app
docker compose exec simple-app wget -qO- http://redis:6379 || true
# (redis no es HTTP, el error esperado es "Empty reply from server", no "connection refused")

# Parar sin borrar volúmenes
docker compose down

# Parar y borrar volúmenes (¡elimina datos!)
docker compose down -v
```

---

## Conceptos clave aprendidos

**Por qué Compose y no `docker run` manual**
Con tres servicios y sus opciones de red, volumen, healthcheck y restart policy, el comando equivalente serían más de 200 caracteres por servicio. Compose centraliza toda esa configuración en un YAML versionable en Git.

**Cuándo Compose y cuándo Kubernetes**
Compose es ideal para desarrollo local y stacks pequeños. En cuanto se necesita escalar horizontalmente (múltiples instancias del mismo servicio), distribución en varios nodos, o zero-downtime deployments, Kubernetes entra en escena — que es exactamente lo que veremos en Week 10.

**Gestión de secretos**
En esta práctica usamos `.env` con valores simples. En producción real los secretos se gestionan con herramientas como HashiCorp Vault, AWS Secrets Manager o Kubernetes Secrets — nunca en texto plano en el repositorio.
