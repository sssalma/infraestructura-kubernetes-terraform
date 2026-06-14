# Week 8: Containerization (Docker)

## Objetivo

Empaquetar aplicaciones en contenedores Docker para que se ejecuten de forma
idéntica en cualquier máquina: local, del compañero, o en producción.

---

## Estructura

```
week_8/
├── Dockerfile            # Contenedor Nginx
├── default.conf          # Configuración personalizada de Nginx
├── html/
│   └── index.html        # Página de GreenDevCorp
└── simple-app/
    ├── Dockerfile        # Contenedor Flask
    ├── app.py            # Aplicación Python
    └── requirements.txt  # Dependencias Python
```

---

## Contenedor 1: Nginx

### Imagen base

Se usa `nginx:latest` como base, tal como indica el enunciado. Nginx es un
servidor web ligero y ampliamente usado en producción, adecuado para servir
contenido estático y como proxy reverso hacia nuestra app Flask.

### Proxy reverso

Nginx reenvía `/visits` a `simple-app:3000`, conectando web y app.

```bash
docker build -t nginx-gsx .
```

---

## Contenedor 2: Simple App (Flask)

### Imagen base

Se usa `python:3.12-alpine` en lugar de `python:3.12` completo por dos razones:

- **Tamaño**: Alpine ocupa ~5MB frente a ~900MB de la imagen completa
- **Seguridad**: menos paquetes instalados = menos superficie de ataque

### Aplicación

| Endpoint | Respuesta |
|----------|-----------|
| `GET /` | `Hello from container!` |
| `GET /health` | `{"status": "ok"}` |
| `GET /visits` | `Visitas: N` (contador en memoria) |

El contador de `/visits` se pierde al reiniciar el contenedor. En Week 9
se reemplazará con Redis para que sea persistente.

### Optimización de capas

En el Dockerfile, `requirements.txt` se copia **antes** que `app.py`. Esto
aprovecha la caché de Docker: si solo cambia el código de la app, Docker
reutiliza la capa de dependencias y no las reinstala, acelerando los rebuilds.

### Construcción y ejecución

```bash
# Desde simple-app/
docker build -t simple-app-gsx .

# Ejecutar localmente
docker run -p 3000:3000 simple-app-gsx

# Verificar
curl localhost:3000
curl localhost:3000/health
```

### Sobre las IPs que muestra Flask

Al arrancar el contenedor, Flask muestra dos IPs:

- `127.0.0.1` → loopback, solo accesible desde dentro del contenedor
- `172.17.0.x` → IP interna que Docker asigna al contenedor en su red bridge

El flag `-p 3000:3000` hace que Docker enrute el tráfico de `localhost:3000`
de tu máquina hacia la IP interna del contenedor. Este concepto de red interna
de Docker es la base de la comunicación entre servicios en Week 9.

---

## Docker Hub

Ambas imágenes están publicadas en Docker Hub bajo el usuario `sssalma`:

| Imagen | Docker Hub |
|--------|-----------|
| Nginx | `sssalma/nginx-gsx:v1` |
| Flask | `sssalma/simple-app-gsx:v1` |

### Pasos realizados

```bash
# Login
docker login

# Taggear
docker tag nginx-gsx sssalma/nginx-gsx:v1
docker tag simple-app-gsx sssalma/simple-app-gsx:v1

# Push
docker push sssalma/nginx-gsx:v1
docker push sssalma/simple-app-gsx:v1
```

### Verificación desde Docker Hub

```bash
docker pull sssalma/simple-app-gsx:v1 && docker run -p 3000:3000 sssalma/simple-app-gsx:v1
curl localhost:3000/visits
# Visitas: 1
```

---

## Conceptos clave aprendidos

**Imagen vs Contenedor**
- La imagen es la "receta" estática generada con `docker build`
- El contenedor es la imagen ejecutándose, con su propio proceso y red
- Se pueden crear múltiples contenedores a partir de la misma imagen

**Capas de Docker**
- Cada instrucción del Dockerfile genera una capa
- Docker cachea las capas — el orden importa para optimizar rebuilds

**Red interna de Docker**
- Docker asigna IPs internas (`172.17.x.x`) a cada contenedor
- El flag `-p` mapea puertos entre el host y el contenedor
- Los contenedores pueden comunicarse entre sí por nombre de servicio (Week 9)

**Registro de imágenes**
- Docker Hub actúa como repositorio centralizado de imágenes
- Cualquier persona con acceso puede hacer `pull` y ejecutar la imagen