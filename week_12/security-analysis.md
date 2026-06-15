# Security Analysis

Aquí va lo que podría salir mal en la infraestructura y cómo lo evitamos. La idea es tener
varias capas de seguridad, para que si una falla las otras sigan protegiendo.

## En la red

Lo peor que puede pasar es que alguien entre en un pod (por ejemplo el de nginx) y desde ahí
salte a los demás servicios o a la base de datos. Para evitarlo usamos NetworkPolicies con la
idea de "bloquear todo por defecto y abrir solo lo necesario". La política deny-all corta todo,
y luego solo dejamos pasar lo justo: nginx puede hablar con simple-app y con el DNS, y nada más.

Esto lo probamos de verdad con Calico: nginx llega a simple-app (permitido) pero si intenta
salir a internet se queda colgado (bloqueado). Sin las políticas, cualquier pod podría hablar
con cualquier otro. Aparte, simple-app es ClusterIP, o sea solo se ve desde dentro del clúster,
solo nginx está expuesto fuera.

## En los contenedores

Una imagen vieja puede traer fallos de seguridad conocidos. Por eso usamos imágenes base
pequeñas (alpine) que tienen menos cosas que puedan fallar. Lo ideal sería escanear las
imágenes en el CI y que avise si hay vulnerabilidades, y hacer que los contenedores no corran
como root. Eso último no lo hemos hecho, es la parte de hardening, pero se podría añadir.

## Con los secretos

Subir contraseñas o tokens a Git es de los errores más típicos y más graves. Para evitarlo el
.env está en el .gitignore y solo subimos el .env.example con valores de ejemplo. La config no
sensible va en un ConfigMap, no metida a mano en las imágenes. También dejamos fuera de Git el
estado de Terraform porque puede tener datos sensibles. Para secretos de verdad (contraseñas de
BD) lo suyo sería usar Secrets de Kubernetes en vez de ConfigMaps.

## Con los accesos

El riesgo es que demasiada gente tenga permisos de producción, o que un ex-empleado siga
teniendo acceso. Esto se arregla con identidad centralizada y doble factor (explicado en el
otro documento), y con el RBAC de Kubernetes dando a cada equipo solo lo que necesita, para
que dev no pueda tocar producción.

## Con la disponibilidad

Si un pod se cae o hay un pico de tráfico el servicio podría dejar de funcionar. Por eso los
Deployments tienen réplicas y si un pod muere Kubernetes lo levanta solo. Las probes de
liveness/readiness detectan los pods que no responden, y los límites de CPU y memoria evitan
que un pod se coma todos los recursos del nodo.

## Para no liarla con la configuración

A veces el problema es configurar mal una protección y creerte que estás seguro cuando no lo
estás (por ejemplo NetworkPolicies que no se aplican porque el CNI no las cumple). Para evitarlo
todo está en Terraform, así queda en Git, es revisable y se puede volver a montar igual. Y las
políticas las probamos en lugar de dar por hecho que funcionan.

## Resumen

No hay una sola cosa que te haga seguro, es la suma de todas: cortar la red por defecto, usar
imágenes pequeñas, no subir secretos, controlar quién accede, tener réplicas y montar todo con
código. Y sobre todo probar que las defensas funcionan de verdad, no solo dejarlas puestas.
