Esta práctica ha sido bastante diferente a lo que estamos acostumbrados. Ir construyendo semana a semana, desde un Dockerfile hasta tener todo desplegado con Terraform, tiene sentido como estructura aunque al principio no lo veía claro del todo. 



Lo que más me costó fue Kubernetes. Docker Compose se entiende relativamente rápido, defines los servicios, los arrancas y ya. Pero Kubernetes tiene muchos más conceptos encima: pods, deployments, services, configmaps... y al principio no entendía bien por qué necesitabas todo eso junto para hacer algo que en Compose hacías en veinte líneas. Lo que me ayudó fue cuando borré un pod a mano y vi que Kubernetes lo volvía a crear solo. Eso me hizo entender para qué sirve realmente un Deployment, más que leer la documentación. 



Lo que me sorprendió bastante es que todo esto va principalmente de reproducibilidad. Yo pensaba que DevOps era sobre desplegar rápido o automatizar cosas, pero en realidad el objetivo es que lo que funciona en tu máquina funcione igual en cualquier otro sitio. Docker lo hace a nivel de contenedor, Terraform a nivel de infraestructura. Cuando en el Challenge B destruimos todo con terraform destroy y volvió a levantarse igual con terraform apply, se entiende bien para qué sirve todo esto.



Si empezara de nuevo escribiría la documentación mientras haces las cosas, no al final. Cada semana decíamos "ya lo documentamos luego" y luego no recordábamos bien por qué habíamos tomado ciertas decisiones. También hubiera dedicado más atención a los Dockerfiles desde el principio, porque detalles como el orden de las capas o usar Alpine en vez de la imagen completa parecen pequeños pero luego tienen su impacto. 



La semana de redes me pareció la más interesante porque era diferente, más de pensar que de ejecutar comandos. Diseñar el plan de subnets, implementar las NetworkPolicies con deny-all por defecto y luego abrir solo lo necesario, ese tipo de razonamiento me parece más transferible que aprender la sintaxis de un YAML concreto. 



En general he entendido mejor para qué existe cada herramienta y cuándo tiene sentido usarla. Eso era lo que más me faltaba al principio de la práctica.

