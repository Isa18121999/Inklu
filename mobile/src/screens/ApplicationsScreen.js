import React, { useCallback, useMemo, useState } from "react";
import { ActivityIndicator, Pressable, RefreshControl, ScrollView, Text, View, StyleSheet } from "react-native";
import { useFocusEffect } from "@react-navigation/native";
import CandidateBottomNav from "../components/CandidateBottomNav";
import AccessibleButton from "../components/AccessibleButton";
import { API_URL } from "../config/api";
import { authHeaders } from "../config/session";
import { colors } from "../theme/colors";
import { font, horizontalPadding, rs } from "../theme/responsive";

const tabs = ["Todas", "Postulado", "CV visto", "En proceso", "Proceso finalizado"];
const normalizeStatus = (value) => String(value || "Postulado").toLowerCase();
const progressFor = (value) => { const status = normalizeStatus(value); if (status.includes("finalizado")) return 100; if (status.includes("proceso")) return 75; if (status.includes("visto")) return 50; return 25; };
const statusSteps = ["Postulado", "CV visto", "En proceso", "Proceso finalizado"];

export default function ApplicationsScreen({ navigation }) {
  const [applications, setApplications] = useState([]); const [loading, setLoading] = useState(true); const [refreshing, setRefreshing] = useState(false); const [activeTab, setActiveTab] = useState("Todas");
  const loadApplications = useCallback(async (isRefresh = false) => { if (isRefresh) setRefreshing(true); else setLoading(true); try { const res = await fetch(`${API_URL}/applications`, { headers: authHeaders() }); if (!res.ok) throw new Error(); setApplications(await res.json()); } catch (_error) { if (!isRefresh) setApplications([]); } finally { if (isRefresh) setRefreshing(false); else setLoading(false); } }, []);
  useFocusEffect(useCallback(() => { loadApplications(); }, [loadApplications]));
  const filtered = useMemo(() => activeTab === "Todas" ? applications : applications.filter((item) => normalizeStatus(item.status) === activeTab.toLowerCase()), [applications, activeTab]);

  return <View style={styles.screen}>
    <ScrollView contentContainerStyle={styles.container} refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => loadApplications(true)} />}>
      <Text style={styles.headerTitle} accessibilityRole="header">Mis postulaciones</Text>
      <Text style={styles.subtitle}>Sigue cada etapa de tu proceso y conoce tu Match integral.</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.tabs} keyboardShouldPersistTaps="handled">
        {tabs.map((tab) => <Pressable key={tab} onPress={() => setActiveTab(tab)} style={[styles.tab, activeTab === tab && styles.tabActive]} accessibilityRole="tab" accessibilityState={{ selected: activeTab === tab }} accessibilityLabel={`Filtrar por ${tab}`}>
          <Text numberOfLines={1} adjustsFontSizeToFit minimumFontScale={0.78} style={[styles.tabText, activeTab === tab && styles.tabTextActive]}>{tab}</Text>
        </Pressable>)}
      </ScrollView>
      {loading && <ActivityIndicator color={colors.primary} style={styles.loader} />}
      {!loading && filtered.map((application) => { const progress = progressFor(application.status); const currentStep = Math.max(0, Math.min(3, Math.ceil(progress / 25) - 1)); const canChat = normalizeStatus(application.status) !== "postulado"; return <View key={application._id} style={styles.card} accessible accessibilityLabel={`${application.jobId?.title || "Oferta"}, ${application.jobId?.companyId?.name || "Empresa"}, Match ${Number(application.matchScore ?? 0)}%, ${application.status || "Postulado"}`}>
        <View style={styles.cardHeader}><View style={styles.cardInfo}><Text style={styles.job}>{application.jobId?.title || "Oferta"}</Text><Text style={styles.company}>{application.jobId?.companyId?.name || "Empresa"}</Text></View><View style={styles.matchBadge}><Text style={styles.matchText}>{Number(application.matchScore ?? 0)}%</Text><Text style={styles.matchLabel}>MATCH</Text></View></View>
        <Text style={styles.status}>{application.status || "Postulado"}</Text><Text style={styles.date}>{application.createdAt ? new Date(application.createdAt).toLocaleDateString() : ""}{application.candidateCount ? ` · ${application.candidateCount} candidatos` : ""}</Text>
        <Text style={styles.progressTitle}>Progreso de la postulación</Text><View style={styles.progressTrack}><View style={[styles.progressFill, { width: `${progress}%` }]} /></View><View style={styles.steps}>{statusSteps.map((step, index) => <View key={step} style={styles.step}><View style={[styles.stepDot, index <= currentStep && styles.stepDotActive]} /><Text numberOfLines={2} style={[styles.stepText, index <= currentStep && styles.stepTextActive]}>{step}</Text></View>)}</View>
        {application.matchBreakdown && Object.keys(application.matchBreakdown).length > 0 && <View style={styles.breakdownBox}><Text style={styles.breakdownTitle}>¿Por qué este Match?</Text>{Object.entries(application.matchBreakdown).map(([key, value]) => <Text key={key} style={styles.breakdown}>• {{ skills: "Habilidades", experience: "Experiencia", education: "Educación", modality: "Modalidad", accessibility: "Accesibilidad" }[key] || key}: {value}%</Text>)}</View>}
        {canChat && <AccessibleButton title="💬 Abrir chat" type="secondary" accessibilityHint="Abre la conversación con la empresa sobre esta postulación." onPress={() => navigation.navigate("Chat", { applicationId: application._id })} />}
      </View>; })}
      {!loading && !filtered.length && <View style={styles.empty}><Text style={styles.emptyTitle}>No tienes postulaciones en esta categoría</Text><Text style={styles.emptyText}>Explora las oportunidades disponibles y encuentra tu próximo empleo.</Text></View>}
    </ScrollView><CandidateBottomNav navigation={navigation} active="applications" />
  </View>;
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  container: { flexGrow: 1, paddingBottom: 112 },
  headerTitle: { color: colors.text, textAlign: "left", fontSize: font(29), fontWeight: "800", paddingHorizontal: horizontalPadding, paddingTop: rs(22, 18, 26), paddingBottom: 3 },
  subtitle: { paddingHorizontal: horizontalPadding, paddingTop: 3, color: "#64748B", fontSize: font(15.5), lineHeight: font(22) },
  tabs: { paddingHorizontal: rs(18, 14, 22), paddingTop: rs(16, 12, 19), paddingBottom: rs(12, 10, 15), gap: rs(8, 6, 10), alignItems: "center" },
  tab: { minHeight: rs(50, 46, 54), paddingHorizontal: rs(16, 12, 20), borderRadius: rs(25, 22, 28), borderWidth: 1, borderColor: "#E2E8F0", backgroundColor: colors.white, alignItems: "center", justifyContent: "center" },
  tabActive: { backgroundColor: "#EDE9FE", borderColor: "#DDD6FE" },
  tabText: { fontSize: font(13.5), color: colors.text, fontWeight: "700" },
  tabTextActive: { color: colors.primary },
  loader: { marginTop: 12 },
  card: { marginHorizontal: rs(18, 14, 22), marginBottom: 16, padding: rs(18, 15, 20), borderRadius: 20, backgroundColor: colors.white, elevation: 3 },
  cardHeader: { flexDirection: "row", alignItems: "center", gap: 12 },
  cardInfo: { flex: 1, minWidth: 0 },
  job: { fontWeight: "800", fontSize: font(20), color: colors.text, lineHeight: font(27) },
  company: { fontSize: font(15), color: "#64748B", marginTop: 4 },
  matchBadge: { width: rs(66, 60, 70), height: rs(66, 60, 70), borderRadius: rs(33, 30, 35), borderWidth: 5, borderColor: colors.primary, alignItems: "center", justifyContent: "center" },
  matchText: { fontWeight: "800", color: colors.primary, fontSize: font(15) },
  matchLabel: { fontSize: font(8), fontWeight: "800", color: "#64748B" },
  status: { fontSize: font(16), fontWeight: "800", color: colors.primary, marginTop: 14 },
  date: { fontSize: font(13), color: "#64748B", marginTop: 3 },
  progressTitle: { marginTop: 18, fontWeight: "800", color: colors.text },
  progressTrack: { height: 8, borderRadius: 5, backgroundColor: "#E2E8F0", marginTop: 8, overflow: "hidden" },
  progressFill: { height: 8, borderRadius: 5, backgroundColor: colors.primary },
  steps: { flexDirection: "row", justifyContent: "space-between", marginTop: 10 },
  step: { flex: 1, alignItems: "center", minWidth: 0 },
  stepDot: { width: 11, height: 11, borderRadius: 6, backgroundColor: "#CBD5E1" },
  stepDotActive: { backgroundColor: colors.primary },
  stepText: { fontSize: font(9), color: "#64748B", textAlign: "center", marginTop: 4 },
  stepTextActive: { color: colors.primary, fontWeight: "800" },
  breakdownBox: { marginTop: 15, paddingTop: 13, borderTopWidth: 1, borderTopColor: "#E2E8F0" },
  breakdownTitle: { fontWeight: "800", color: colors.primary, marginBottom: 4 },
  breakdown: { color: colors.text, marginTop: 2, fontSize: font(13) },
  empty: { margin: 28, alignItems: "center" },
  emptyTitle: { fontSize: font(19), fontWeight: "800", color: colors.text, textAlign: "center" },
  emptyText: { marginTop: 10, fontSize: font(15), lineHeight: font(22), color: "#64748B", textAlign: "center" }
});
