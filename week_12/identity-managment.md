# Identity Management: Authentication, Authorization & Strategy

## 1. Authentication vs. Authorization

**Authentication (¿Quién eres?)**
Verifica identidad: username + password, certificado, biometría, MFA.

**Authorization (¿Qué puedes hacer?)**
Verifica permisos: roles, grupos, ACLs.
Ejemplo: ¿Juan está en grupo "database-admins"? → ✓ Sí → Acceso permitido
---

## 2. Centralized Identity: LDAP, Active Directory, SSO

### LDAP (Lightweight Directory Access Protocol)

Base de datos centralizada de usuarios y grupos. Cada aplicación consulta LDAP para verificar credenciales.

**Ventajas:** Gratis, estándar abierto, ligero  
**Desventajas:** Requiere mantener servidor, no es SSO completo

### Active Directory (Microsoft)

LDAP + Kerberos + Group Policy + auditoría. Integración total con Windows.

**Ventajas:** Completo, seguro (Kerberos), auditoría avanzada  
**Desventajas:** Caro, complejo, mejor para entornos Windows

### SSO (Single Sign-On)

Un login → acceso a múltiples aplicaciones sin reingresar credenciales.

**Protocolos:** Kerberos (AD), SAML 2.0 (empresas grandes), OAuth 2.0 + OIDC (moderno)

---

## 3. Identity Strategy para GreenDevCorp (20+ personas)

### Recomendación: Google Workspace + Kubernetes OIDC

**Por qué:**
- ✓ Escalable sin esfuerzo (no mantienes servidores)
- ✓ Integración fácil (GitHub, Jira, Jenkins, Slack, Kubernetes)
- ✓ Costo razonable (~$15-30/usuario/mes)
- ✓ Seguridad → Google maneja SSL, backups, 24/7
- ✓ MFA built-in
- ✓ Auditoría completa

### Arquitectura:
Google Workspace (SSO Central)
↓ OIDC Token
├─ GitHub SSO
├─ Jira SSO
├─ Kubernetes OIDC
├─ Slack SSO
└─ Jenkins SSO
Kubernetes RBAC:

developers@greendevcorp.com → pueden deploy staging
database-admins@... → acceso production secrets
managers@... → solo lectura

## Conclusión

Para GreenDevCorp hoy:
1. **Inmediato:** Google Workspace como SSO central
2. **Corto plazo (3-6 meses):** Integrar Kubernetes OIDC + RBAC