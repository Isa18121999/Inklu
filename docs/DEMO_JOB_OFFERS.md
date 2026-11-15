# Ofertas ficticias para pruebas de INKLU

Este conjunto contiene **20 ofertas laborales ficticias** para probar el feed, filtros, recomendaciones, guardado y flujo de postulación de INKLU. No son vacantes reales ni deben presentarse como oportunidades auténticas.

## Cuenta publicadora

Las 20 ofertas deben publicarse desde la cuenta empresarial existente **18100102@ue.edu.pe**. El script busca esa cuenta y exige que tenga rol `company`. No crea usuarios, no cambia contraseñas ni modifica el perfil de la cuenta. Si no existe o no tiene rol empresarial, se detiene sin insertar ofertas.

## Archivos

- `backend/data/demo-jobs.json`: catálogo de 20 ofertas en 9 categorías, con sueldo, modalidad, ubicación, contrato, requisitos y atributos de accesibilidad.
- `backend/scripts/seed-demo-jobs.js`: carga idempotente usando la cuenta publicadora existente.
- `backend/models/Job.js`: incluye `isDemo` (por defecto `false`) para distinguir los registros de prueba.
- `backend/test/demo-jobs.test.js`: valida cantidad, variedad, integridad y uso de la cuenta indicada.

## Cómo cargar en una base de datos de pruebas

Desde la raíz del repositorio:

```bash
cd backend
npm install
SEED_DEMO_JOBS=true MONGODB_URI="tu_uri_de_mongodb_de_pruebas" node scripts/seed-demo-jobs.js
```

En Windows PowerShell:

```powershell
cd backend
$env:SEED_DEMO_JOBS="true"
$env:MONGODB_URI="tu_uri_de_mongodb_de_pruebas"
node scripts/seed-demo-jobs.js
```

Usa una base de datos de desarrollo o staging, nunca producción. La carga exige confirmación explícita mediante `SEED_DEMO_JOBS=true`. Es idempotente: las ofertas existentes de demostración para esa cuenta se actualizan y las faltantes se crean. No crea cuentas ni genera postulaciones o notificaciones.

## Accesibilidad

Los campos de accesibilidad son **datos declarativos ficticios para probar la interfaz**, no una auditoría de instalaciones reales. Para vacantes reales, la empresa debe verificar cada característica y detallar los ajustes razonables disponibles.
