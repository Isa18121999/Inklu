const mongoose = require("mongoose");
require("dotenv").config();
const connectDatabase = require("../config/database");
const ConadisPerson = require("../models/ConadisPerson");

const departments = [
  ["LIMA", "LIMA", "150101"], ["AREQUIPA", "AREQUIPA", "040101"], ["LA LIBERTAD", "TRUJILLO", "130101"],
  ["PIURA", "PIURA", "200101"], ["CUSCO", "CUSCO", "080101"], ["JUNIN", "HUANCAYO", "120101"],
  ["LAMBAYEQUE", "CHICLAYO", "140101"], ["ANCASH", "HUARAZ", "020101"], ["ICA", "ICA", "110101"],
  ["LORETO", "MAYNAS", "160101"], ["PUNO", "PUNO", "210101"], ["TACNA", "TACNA", "230101"]
];
const disabilityTypes = ["MOTORA", "VISUAL", "AUDITIVA", "INTELECTUAL", "HABLA", "DEFICIENCIA", "OTROS"];
const severities = ["LEVE", "MODERADA", "SEVERA"];
const sexes = ["MASCULINO", "FEMENINO", "NO_ESPECIFICADO"];

function pick(list, index, offset = 0) { return list[(index * 17 + offset) % list.length]; }
function pad6(value) { return String(value).padStart(6, "0"); }

function buildRecords(total = 1000) {
  return Array.from({ length: total }, (_, index) => {
    const n = index + 1;
    const [departamento, provincia, ubigeo] = pick(departments, index);
    const anioNacimiento = 1955 + ((index * 7) % 68);
    const year = new Date().getUTCFullYear();
    const edad = Math.max(0, year - anioNacimiento);
    const month = (index % 12) + 1;
    const day = (index % 27) + 1;
    const fechaInscripcion = new Date(Date.UTC(2018 + (index % 8), month - 1, day));

    return {
      rui: pad6(900000 + n),
      estadoRegistro: index % 37 === 0 ? "INACTIVO" : "ACTIVO",
      sexo: pick(sexes, index),
      anioNacimiento,
      edad,
      departamento,
      provincia,
      distrito: `DISTRITO DEMO ${String((index % 20) + 1).padStart(2, "0")}`,
      ubigeo,
      tipoDiscapacidad: pick(disabilityTypes, index, 2),
      nivelGravedad: pick(severities, index, 1),
      fechaInscripcion,
      fechaActualizacion: new Date(Date.UTC(2026, (index * 3) % 12, ((index * 5) % 27) + 1)),
      tieneCarneConadis: true,
      tipoCarne: index % 3 === 0 ? "AMARILLO" : "CELESTE"
    };
  });
}

async function main() {
  await connectDatabase();
  const records = buildRecords(1000);
  await ConadisPerson.deleteMany({});
  await ConadisPerson.insertMany(records, { ordered: false });
  console.log(`Seed CONADIS simulado completado: ${records.length} registros.`);
  console.log(`RUI de prueba: ${records[0].rui}`);
  await mongoose.connection.close();
}

main().catch(async (error) => {
  console.error("Seed CONADIS error", error);
  await mongoose.connection.close();
  process.exit(1);
});
