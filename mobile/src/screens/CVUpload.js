import React, { useCallback, useState } from "react";
import { useFocusEffect } from "@react-navigation/native";
import { Alert, ScrollView, View, Text, StyleSheet } from "react-native";
import * as DocumentPicker from "expo-document-picker";
import AccessibleButton from "../components/AccessibleButton";
import CandidateBottomNav from "../components/CandidateBottomNav";
import { API_URL } from "../config/api";
import { colors } from "../theme/colors";
import { authHeaders } from "../config/session";
import { font, horizontalPadding, rs } from "../theme/responsive";

const CV_URL = `${API_URL}/cv`;
const MAX_CV_SIZE = 10 * 1024 * 1024;
const ALLOWED_EXTENSIONS = [".pdf", ".doc", ".docx"];
const ALLOWED_MIME_TYPES = ["application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"];

export default function CVUpload({ navigation }) {
  const [cvName, setCvName] = useState("");
  const [extractedFields, setExtractedFields] = useState([]);
  const [loading, setLoading] = useState(false);

  const loadCvStatus = useCallback(async () => {
    try { const response = await fetch(`${CV_URL}/me`, { headers: authHeaders() }); if (!response.ok) return; const data = await response.json(); if (data.hasCv) setCvName(data.fileName || "CV cargado"); else setCvName(""); }
    catch (_error) {}
  }, []);
  useFocusEffect(useCallback(() => { loadCvStatus(); }, [loadCvStatus]));

  const chooseCV = async () => {
    try {
      const result = await DocumentPicker.getDocumentAsync({ type: ["application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"], copyToCacheDirectory: true });
      if (!result.canceled) { const file = result.assets?.[0]; if (!file) return; const extension = `.${String(file.name || "").split(".").pop()}`.toLowerCase(); const mimeType = file.mimeType || ""; if (!ALLOWED_EXTENSIONS.includes(extension) || (mimeType && !ALLOWED_MIME_TYPES.includes(mimeType))) { Alert.alert("Formato no válido", "El CV debe ser PDF, DOC o DOCX."); return; } if (file.size !== undefined && file.size > MAX_CV_SIZE) { Alert.alert("Archivo demasiado grande", "El CV no puede superar los 10 MB."); return; } await uploadCV(file); }
    } catch (_error) { Alert.alert("Error", "No se pudo seleccionar el CV."); }
  };

  const uploadCV = async (file) => {
    setLoading(true);
    try {
      const formData = new FormData(); formData.append("cv", { uri: file.uri, name: file.name, type: file.mimeType || "application/pdf" });
      const response = await fetch(`${CV_URL}/me`, { method: "POST", headers: authHeaders(), body: formData });
      const data = await response.json(); if (!response.ok) throw new Error(data.message || "Error subiendo CV");
      setCvName(file.name); setExtractedFields(data.extractedFields || []);
      const fieldLabels = { experience: "experiencia", education: "educación", modality: "modalidad", skills: "habilidades", accessibility: "accesibilidad" };
      const extracted = (data.extractedFields || []).map((field) => fieldLabels[field] || field);
      const detail = extracted.length ? "Campos detectados: " + extracted.join(", ") + "." : "No se detectaron campos profesionales automáticamente; puedes completar tu perfil manualmente.";
      Alert.alert("CV actualizado", "Tu CV fue guardado correctamente.\n\n" + detail);
    } catch (error) { Alert.alert("Error", error.message); } finally { setLoading(false); }
  };

  return <View style={styles.screen}>
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title} accessibilityRole="header">Mi CV</Text>
      <Text style={styles.description}>Sube o actualiza tu CV para mejorar tu perfil y Match IA.</Text>
      <View style={styles.fileCard}>{cvName ? <Text style={styles.file} accessibilityLabel={`Archivo de CV seleccionado: ${cvName}`}>✓ {cvName}</Text> : <Text style={styles.empty}>No tienes un CV cargado.</Text>}</View>
      {extractedFields.length > 0 ? <Text style={styles.extracted}>✓ Perfil actualizado con: {extractedFields.map((field) => ({ experience: "experiencia", education: "educación", modality: "modalidad", skills: "habilidades", accessibility: "accesibilidad" }[field] || field)).join(", ")}</Text> : null}
      <AccessibleButton title={loading ? "Subiendo..." : "📤 Subir CV"} accessibilityHint="Abre el selector para elegir un archivo PDF, DOC o DOCX." onPress={chooseCV} disabled={loading} />
      <AccessibleButton title="🔄 Actualizar CV" accessibilityHint="Selecciona un nuevo archivo para reemplazar tu CV." type="accent" onPress={chooseCV} disabled={loading} />
      <AccessibleButton title="Volver a mi perfil" type="secondary" onPress={() => navigation.navigate("CandidateProfile")} />
    </ScrollView>
    <CandidateBottomNav navigation={navigation} active="cv" />
  </View>;
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.white },
  container: { flexGrow: 1, paddingHorizontal: horizontalPadding, paddingTop: rs(24, 18, 30), paddingBottom: 112 },
  title: { fontSize: font(30), fontWeight: "800", color: colors.primary, marginBottom: 12 },
  description: { fontSize: font(16), lineHeight: font(24), color: colors.text, marginBottom: 20 },
  fileCard: { minHeight: 64, borderRadius: 16, borderWidth: 1, borderColor: "#E2E8F0", backgroundColor: colors.background, padding: 16, justifyContent: "center", marginBottom: 12 },
  empty: { fontSize: font(16), color: colors.text },
  file: { fontSize: font(16), fontWeight: "700", color: colors.success },
  extracted: { fontSize: font(15), lineHeight: font(22), color: colors.text, marginBottom: 20 }
});
