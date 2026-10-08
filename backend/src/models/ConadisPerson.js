const mongoose = require("mongoose");

const ConadisPersonSchema = new mongoose.Schema({
  rui: { type: String, required: true, unique: true, index: true, match: /^\d{6}$/ },
  estadoRegistro: { type: String, enum: ["ACTIVO", "INACTIVO"], default: "ACTIVO" },
  sexo: { type: String, enum: ["MASCULINO", "FEMENINO", "NO_ESPECIFICADO"] },
  anioNacimiento: { type: Number, min: 1900, max: 2026 },
  edad: { type: Number, min: 0, max: 126 },
  departamento: String,
  provincia: String,
  distrito: String,
  ubigeo: String,
  tipoDiscapacidad: {
    type: String,
    enum: ["INTELECTUAL", "DEFICIENCIA", "HABLA", "AUDITIVA", "VISUAL", "MOTORA", "OTROS"]
  },
  nivelGravedad: { type: String, enum: ["LEVE", "MODERADA", "SEVERA", "NO_ESPECIFICADO"] },
  fechaInscripcion: Date,
  fechaActualizacion: Date,
  tieneCarneConadis: { type: Boolean, default: true },
  tipoCarne: { type: String, enum: ["CELESTE", "AMARILLO", "NO_ESPECIFICADO"] }
}, { timestamps: true, collection: "conadis_personas" });

module.exports = mongoose.model("ConadisPerson", ConadisPersonSchema);
