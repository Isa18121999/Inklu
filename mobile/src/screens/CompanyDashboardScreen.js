import React, { useCallback, useEffect, useState } from "react";
import { useFocusEffect } from "@react-navigation/native";
import { Alert, ActivityIndicator, ScrollView, Text, View, StyleSheet } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { API_URL } from "../config/api";
import { colors } from "../theme/colors";
import { authHeaders } from "../config/session";

const CRITERIA_LABELS = { skills: "Habilidades", experience: "Experiencia", education: "Educación", modality: "Modalidad", accessibility: "Accesibilidad" };
const NEXT_STATUS = { Postulado: "CV visto", "CV visto": "En proceso", "En proceso": "Proceso finalizado", "Proceso finalizado": null };

export default function CompanyDashboardScreen({ navigation }) {
  const [jobs, setJobs] = useState([]); const [selectedJobId, setSelectedJobId] = useState(null); const [candidates, setCandidates] = useState([]); const [loadingJobs, setLoadingJobs] = useState(true); const [loadingCandidates, setLoadingCandidates] = useState(false); const [unreadCount, setUnreadCount] = useState(0);
  const loadUnreadCount = useCallback(async () => { try { const response = await fetch(`${API_URL}/notifications`, { headers: authHeaders() }); if (!response.ok) return; const data = await response.json(); setUnreadCount(Number(data.unreadCount || 0)); } catch (_error) { setUnreadCount(0); } }, []);
  const loadJobs = useCallback(async () => { setLoadingJobs(true); try { const response = await fetch(`${API_URL}/company/my-jobs`, { headers: authHeaders() }); const data = await response.json(); if (!response.ok) throw new Error(data.message || "No se pudieron obtener las ofertas"); const companyJobs = Array.isArray(data) ? data : []; setJobs(companyJobs); setSelectedJobId((current) => current && companyJobs.some((job) => job._id === current) ? current : companyJobs[0]?._id || null); } catch (_error) { setJobs([]); setSelectedJobId(null); setCandidates([]); } finally { setLoadingJobs(false); } }, []);
  const loadCandidates = useCallback(async (jobId) => { if (!jobId) { setCandidates([]); return; } setLoadingCandidates(true); try { const response = await fetch(`${API_URL}/company/candidates/${jobId}`, { headers: authHeaders() }); const data = await response.json(); if (!response.ok) throw new Error(data.message || "No se pudieron obtener los candidatos"); setCandidates(data.candidates || []); } catch (_error) { setCandidates([]); } finally { setLoadingCandidates(false); } }, []);
  useFocusEffect(useCallback(() => { loadJobs(); loadUnreadCount(); }, [loadJobs, loadUnreadCount]));
  useEffect(() => { loadCandidates(selectedJobId); }, [selectedJobId, loadCandidates]);
  const updateStatus = async (candidate, status) => { if (!candidate.applicationId) return Alert.alert("Sin postulación", "Este candidato todavía no tiene una postulación registrada para esta oferta."); try { const response = await fetch(`${API_URL}/applications/${candidate.applicationId}/status`, { method: "PATCH", headers: { ...authHeaders(), "Content-Type": "application/json" }, body: JSON.stringify({ status }) }); const data = await response.json(); if (!response.ok) throw new Error(data.message || "No se pudo actualizar el estado"); setCandidates((current) => current.map((item) => item.applicationId === candidate.applicationId ? { ...item, status: data.status } : item)); } catch (error) { Alert.alert("Error", error.message); } };
  const confirmStatus = (candidate, status) => { const action = status === "CV visto" ? "marcar esta postulación como CV visto" : status === "En proceso" ? "pasar esta postulación a En proceso" : "finalizar el proceso de esta postulación"; Alert.alert("Cambiar estado", `¿Quieres ${action}?`, [{ text: "Cancelar", style: "cancel" }, { text: "Confirmar", onPress: () => updateStatus(candidate, status) }]); };
  const selectedJob = jobs.find((job) => job._id === selectedJobId);
  const handleLogout = async () => { const { clearSessionToken } = await import("../config/session"); await clearSessionToken(); navigation.replace("Welcome"); };
  const confirmLogout = () => Alert.alert("Cerrar sesión", "¿Quieres cerrar tu sesión?", [{ text: "Cancelar", style: "cancel" }, { text: "Cerrar sesión", style: "destructive", onPress: handleLogout }]);

  return <ScrollView contentContainerStyle={styles.container}>
    <Text style={styles.title} accessibilityRole="header">Panel Empresa</Text>
    <Text style={styles.subtitle}>Gestiona ofertas y encuentra talento inclusivo.</Text>
    <AccessibleButton title="👤 Mi perfil de empresa" type="secondary" onPress={() => navigation.navigate("CompanyProfile")} accessibilityHint="Completa o edita la información y las medidas de accesibilidad de tu empresa." />
    <AccessibleButton title="📌 Publicar oferta" onPress={() => navigation.navigate("CreateJob")} />
    <AccessibleButton title={`🔔 Notificaciones${unreadCount ? ` (${unreadCount})` : ""}`} type="secondary" onPress={() => navigation.navigate("Notifications")} />
    <AccessibleButton title="🚪 Cerrar sesión" type="secondary" onPress={confirmLogout} />
    <Text style={styles.section}>💼 Mis ofertas</Text>
    {loadingJobs && <ActivityIndicator color={colors.primary} />}
    {!loadingJobs && !jobs.length && <Text style={styles.empty}>Aún no tienes ofertas publicadas.</Text>}
    {jobs.map((job) => <View key={job._id} style={[styles.jobCard, job._id === selectedJobId && styles.jobCardSelected]}><Text style={styles.jobTitle}>{job.title}</Text>{!!job.area && <Text>{job.area}</Text>}{!!job.modality && <Text>Modalidad: {job.modality}</Text>}<AccessibleButton title={job._id === selectedJobId ? "✓ Oferta seleccionada" : "Ver candidatos"} accessibilityLabel={job._id === selectedJobId ? `Oferta seleccionada: ${job.title}` : `Ver candidatos de la oferta: ${job.title}`} type={job._id === selectedJobId ? "secondary" : "primary"} onPress={() => setSelectedJobId(job._id)} /></View>)}
    {selectedJob && <Text style={styles.section}>🤖 Candidatos para: {selectedJob.title}</Text>}
    {loadingCandidates && <ActivityIndicator color={colors.primary} />}
    {!loadingCandidates && selectedJob && !candidates.length && <Text style={styles.empty}>No hay candidatos para esta oferta todavía.</Text>}
    {candidates.map((candidate) => <View key={candidate._id || candidate.applicationId || candidate.name} style={styles.card} accessible accessibilityLabel={`${candidate.name}, ${candidate.score}% Match integral, estado ${candidate.status}`}>
      <Text style={styles.name}>{candidate.name}</Text><Text style={styles.match}>🤖 {candidate.score}% Match integral</Text>
      <Text style={styles.subsection}>Desglose del Match</Text>{Object.entries(candidate.breakdown || {}).map(([key, value]) => <Text key={key} style={styles.detail}>{CRITERIA_LABELS[key] || key}: {value}%</Text>)}
      <Text style={styles.subsection}>Habilidades</Text><Text>Coinciden: {candidate.matchedSkills?.length ? candidate.matchedSkills.join(" · ") : "Ninguna"}</Text><Text>Faltan: {candidate.missingSkills?.length ? candidate.missingSkills.join(" · ") : "Ninguna"}</Text>
      <Text style={styles.subsection}>Accesibilidad</Text><Text>Coinciden: {candidate.matchedAccessibility?.length ? candidate.matchedAccessibility.join(" · ") : "Ninguna"}</Text><Text>Faltan: {candidate.missingAccessibility?.length ? candidate.missingAccessibility.join(" · ") : "Ninguna"}</Text>
      <Text style={styles.status}>Estado: {candidate.status}</Text><AccessibleButton title="Revisar perfil" onPress={() => navigation.navigate("CandidateCV", { candidate })} />
      {candidate.applicationId && candidate.status !== "Postulado" && <AccessibleButton title="💬 Abrir chat" type="secondary" accessibilityHint="Abre la conversación con este candidato." onPress={() => navigation.navigate("Chat", { applicationId: candidate.applicationId })} />}
      {candidate.applicationId && NEXT_STATUS[candidate.status] && <View style={styles.actions}><AccessibleButton title={NEXT_STATUS[candidate.status] === "CV visto" ? "👁 Marcar CV visto" : NEXT_STATUS[candidate.status] === "En proceso" ? "⏳ Pasar a proceso" : "✓ Finalizar proceso"} type="secondary" onPress={() => confirmStatus(candidate, NEXT_STATUS[candidate.status])} /></View>}
    </View>)}
  </ScrollView>;
}

const styles = StyleSheet.create({ container: { flexGrow: 1, padding: 24, backgroundColor: colors.white }, title: { fontSize: 28, fontWeight: "800", color: colors.primary }, subtitle: { marginVertical: 12, color: colors.text }, section: { marginTop: 24, marginBottom: 8, fontSize: 20, fontWeight: "800", color: colors.secondary }, jobCard: { marginTop: 10, padding: 14, borderWidth: 1, borderColor: "#CBD5E1", borderRadius: 14 }, jobCardSelected: { borderWidth: 2 }, jobTitle: { fontSize: 18, fontWeight: "800" }, empty: { marginVertical: 12 }, card: { marginTop: 16, padding: 16, borderWidth: 1, borderColor: "#E2E8F0", borderRadius: 16 }, name: { fontSize: 18, fontWeight: "700" }, match: { marginVertical: 8, fontWeight: "800", color: colors.success }, subsection: { marginTop: 12, marginBottom: 4, fontWeight: "800" }, detail: { marginTop: 2 }, status: { marginTop: 12, fontWeight: "700" }, actions: { marginTop: 8 }
});
