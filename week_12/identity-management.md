# Identity Management

## Autenticación vs Autorización

La autenticación es comprobar quién eres (usuario y contraseña, y a veces un código extra
para asegurarse). La autorización es lo que viene después: una vez que ya sabes quién es la
persona, decidir qué puede hacer y qué no. O sea, primero te identificas y luego el sistema
mira si tienes permiso. Por ejemplo, en Kubernetes primero validas el token del usuario y
luego el RBAC decide si puede tocar producción o solo mirar.

## LDAP

LDAP es básicamente un protocolo para guardar todos los usuarios de la empresa en un sitio
central y poder consultarlos. En vez de tener las cuentas repartidas por cada aplicación, las
apps preguntan al directorio LDAP si el usuario existe, su contraseña, a qué grupos pertenece,
etc. Así hay una sola lista de usuarios para todo. Lo típico open-source es OpenLDAP.

## Active Directory

Active Directory es lo mismo pero de Microsoft. Por dentro usa LDAP y Kerberos, pero le añade
un montón de cosas para gestionar empresas con Windows (políticas para configurar todos los
ordenadores, etc). Es lo más usado en empresas con muchos equipos Windows. La versión moderna
en la nube es Entra ID (antes Azure AD).

## SSO

SSO (Single Sign-On) es iniciar sesión una sola vez y poder entrar a varias aplicaciones sin
volver a poner la contraseña. Sirve para no tener mil contraseñas distintas: pones una buena
con doble factor en un solo sitio y ya. Y si alguien se va de la empresa, desactivas una cuenta
y pierde el acceso a todo de golpe, en vez de ir app por app. Suele usar protocolos como SAML
u OIDC.

## ¿Qué problema resuelve la identidad centralizada?

Si cada aplicación lleva sus propios usuarios acabas con un lío: cuentas de gente que ya no
está pero siguen activas, contraseñas repetidas y débiles, y dar de alta o de baja a alguien
es ir tocando muchos sitios a mano. Tener la identidad centralizada (un directorio + SSO)
arregla esto: una cuenta por persona, alta y baja rápida, y un único sitio donde ver quién
entró a qué.

Una empresa muy pequeña normalmente no lo necesita montar aparte, le vale con las cuentas que
ya usa para el correo. Una empresa grande sí lo necesita sí o sí, porque con tanta gente y
tantos requisitos legales no se puede llevar de otra forma.

## Recomendación para GreenDevCorp

GreenDevCorp tiene 20 y pico personas, dos oficinas y equipos distintos (dev, data, ops). Yo
recomendaría usar un proveedor de identidad gestionado en la nube, tipo Google Workspace o
Microsoft Entra ID, con SSO y doble factor obligatorio para todos.

La razón es sencilla: con 20 personas no hay nadie dedicado a mantener servidores de identidad,
así que mejor algo que ya viene hecho y se configura en un rato. Además funciona igual desde
las dos oficinas porque está en la nube, y se puede conectar con Kubernetes para controlar quién
toca cada entorno.

La alternativa sería montar Keycloak, que es open-source y lo controlas tú entero. El problema
es que te lo tienes que mantener, actualizar y hacer copias, y para una empresa de este tamaño
no suele compensar. Tendría más sentido cuando crezca bastante o si necesitan tener los datos
en sus propios servidores por algún motivo.

Resumiendo: para como está ahora la empresa, lo práctico es el gestionado con SSO y MFA, y
dejar Keycloak para más adelante si hace falta.
