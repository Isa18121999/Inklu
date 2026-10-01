import React, { useState } from "react";
import { Alert, ScrollView, Text, StyleSheet, View } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { API_URL } from "../config/api";
import { authHeaders, getSessionRole } from "../config/session";
import { colors } from "../theme/colors";

const criteriaLabels = { skills: "Habilidades", experience: "Experiencia", education: "Educación", modality: "Modalidad", accessibility: "Accesibilidad" };

export default function JobDetailScreen({ route, navigation }) {
  const { job } = route.params || {};
  const [applied, setApplied] = useState(false);
  const [role, setRole] = useState(null);
  const [loading, setLoading] = useState(false);
  const [checkingApplication, setCheckingApplication] = useState(true);
  const [applicationMatch, setApplicationMatch] = useState(job?.score);

  React.useEffect(() => {
    let mounted = true;
    const checkApplication = async () => {
      try {
        const sessionRole = await getSessionRole();
        if (!mounted) return;
        setRole(sessionRole);
        if (sessionRole !== "candidate" || !job?._id) return;
        const response = await fetch(API_URL + "/applications", { headers: authHeaders() });
        if (!response.ok) return;
        const applications = await response.json();
        const existing = applications.find((item) => item.jobId?._id === job._id || item.jobId === job._id);
        if (existing && mounted) {
          setApplied(true);
          setApplicationMatch(existing.matchScore);
        }
      } catch (error) {
        // The server remains authoritative when the user attempts to apply.
      } finally {
        if (mounted) setCheckingApplication(false);
      }
    };
    checkApplication();
    return () => { mounted = false; };
  }, [job?._id]);
  if (!job) return <Text style={styles.empty}>No se encontró la oferta.</Text>;
  const apply = async () => {
    if (role !== "candidate" || applied || checkingApplication) return; setLoading(true); try { const response = await fetch(`${API_URL}/applications`, { method: "POST", headers: { "Content-Type": "application/json", ...authHeaders() }, body: JSON.stringify({ jobId: job._id }) }); const data = await response.json(); if (!response.ok) throw new Error(data.message || "No se pudo registrar la postulación"); setApplied(true); setApplicationMatch(data.matchScore); Alert.alert("Postulación registrada", `Tu postulación fue guardada. Match integral: ${data.matchScore}%`); } catch (error) { Alert.alert("Error", error.message); } finally { setLoading(false); } };
  return <ScrollView contentContainerStyle={styles.container}><Text style={styles.title}>{job.title}</Text><Text style={styles.company}>🏢 {job.companyId?.name || "Empresa"}</Text>{applicationMatch !== undefined && <View style={styles.matchCard}><Text style={styles.matchLabel}>Match integral</Text><Text style={styles.match}>{applicationMatch}%</Text>{Object.entries(job.breakdown || {}).map(([key, value]) => <Text key={key} style={styles.breakdown}>• {criteriaLabels[key] || key}: {value}%</Text>)}{job.missingSkills?.length > 0 && <Text style={styles.warning}>⚠️ Habilidades faltantes: {job.missingSkills.join(" · ")}</Text>}</View>}<Text style={styles.section}>Información de la oferta</Text><Text style={styles.text}>Área: {job.area}</Text><Text style={styles.text}>Modalidad: {job.modality || "No especificada"}</Text>{job.experienceRequired !== undefined && <Text style={styles.text}>Experiencia mínima: {job.experienceRequired} años</Text>}{job.educationRequired && <Text style={styles.text}>Formación requerida: {job.educationRequired}</Text>}<Text style={styles.section}>Requisitos</Text><Text style={styles.text}>{(job.requirements || []).join(" · ") || "No especificados"}</Text><Text style={styles.section}>♿ Accesibilidad</Text><Text style={styles.text}>{(job.accessibility || []).join(" · ") || "A coordinar"}</Text><AccessibleButton title={applied ? "✓ Postulación enviada" : checkingApplication ? "Verificando postulación..." : loading ? "Enviando..." : "📌 Postular"} onPress={apply} disabled={role !== "candidate" || applied || loading || checkingApplication} /><AccessibleButton title="Volver a empleos" type="secondary" onPress={() => navigation.goBack()} /></ScrollView>;
}
const styles = StyleSheet.create({ container: { flexGrow: 1, padding: 24, backgroundColor: colors.white }, title: { fontSize: 30, fontWeight: "800", color: colors.primary, marginBottom: 8 }, company: { fontSize: 17, color: colors.text }, section: { fontSize: 18, fontWeight: "800", color: colors.secondary, marginTop: 20, marginBottom: 8 }, text: { fontSize: 16, lineHeight: 24, color: colors.text }, matchCard: { marginTop: 20, padding: 18, borderRadius: 16, backgroundColor: colors.background }, matchLabel: { fontSize: 16, fontWeight: "700", color: colors.text }, match: { fontSize: 36, fontWeight: "800", color: colors.secondary, marginVertical: 4 }, breakdown: { fontSize: 15, marginTop: 3 }, warning: { marginTop: 8 }, empty: { padding: 24 } });
