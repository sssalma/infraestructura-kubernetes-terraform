# Core Services Research: DNS, DHCP, NTP

## 1. DNS (Domain Name System)

**¿Qué es?**
Traduce nombres (greendevcorp.com) a direcciones IP (203.0.113.42).

**¿Qué problema resuelve?**
- Facilita recordar direcciones (nombres vs IPs)
- Permite cambiar servidores sin actualizar cliente
- Load balancing (un nombre → múltiples IPs)

**Para GreenDevCorp:**
- Descubrimiento interno: `db.dev.internal` vs `10.0.1.15:5432`
- Registros públicos: `www.greendevcorp.com`
- Registros mail: MX records
- Kubernetes service discovery (automático con CoreDNS)

**Implementar:** AWS Route53 (servicio administrado) o BIND (open-source)

---

## 2. DHCP (Dynamic Host Configuration Protocol)

**¿Qué es?**
Asigna automáticamente IP, máscara de subred, gateway y DNS a dispositivos.

**¿Qué problema resuelve?**
- Configuración manual imposible a escala
- Evita colisiones de IP (dos dispositivos con misma IP)
- Soporte para dispositivos móviles/temporales

**Para GreenDevCorp:**
- WiFi corporativa: laptops y móviles de empleados
- Escritorios: computadoras fijas
- Dispositivos: impresoras, escáneres
- Visitantes: red WiFi de invitados

**Nota:** Kubernetes no usa DHCP en pods (asigna IPs automáticamente). Pero infraestructura física sí.

---

## 3. NTP (Network Time Protocol)

**¿Qué es?**
Sincroniza relojes de todos los dispositivos en la red.

**¿Qué problema resuelve?**
- Logs con timestamps consistentes (debugging distribuido)
- Certificados HTTPS válidos (validación por timestamp)
- Tokens JWT con expiración correcta (Kerberos, OAuth)
- Auditoría legal (probar qué pasó a qué hora)

**Para GreenDevCorp:**
- Sincronización entre servidores en múltiples oficinas
- Kubernetes DEBER estar sincronizado (crítico)
- Logs centralizados (ELK, Splunk)
- Compliance (GDPR, HIPAA requieren timestamps verificables)

**Configuración típica:**
```bash
apt-get install ntp
# /etc/ntp.conf:
server pool.ntp.org prefer
systemctl start ntp && systemctl enable ntp
ntpq -p  # verificar sincronización
```

