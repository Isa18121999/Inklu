const ConadisPerson = require("../models/ConadisPerson");

async function verifyRui(rui) {
  const normalizedRui = String(rui || "").trim();
  if (!/^\d{6}$/.test(normalizedRui)) {
    return { valid: false, reason: "RUI inválido" };
  }

  const person = await ConadisPerson.findOne({ rui: normalizedRui, estadoRegistro: "ACTIVO" }).lean();
  if (!person) return { valid: false, reason: "RUI no encontrado en el registro simulado" };

  return {
    valid: true,
    rui: person.rui,
    tipoDiscapacidad: person.tipoDiscapacidad,
    nivelGravedad: person.nivelGravedad,
    sexo: person.sexo,
    departamento: person.departamento,
    provincia: person.provincia,
    distrito: person.distrito,
    tieneCarneConadis: person.tieneCarneConadis,
    tipoCarne: person.tipoCarne
  };
}

module.exports = { verifyRui };
