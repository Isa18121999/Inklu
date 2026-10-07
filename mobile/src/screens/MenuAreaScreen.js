import React, { useCallback, useState } from "react";
import { Alert, Pressable, ScrollView, Text, View, StyleSheet } from "react-native";
import { useFocusEffect } from "@react-navigation/native";
import CandidateBottomNav from "../components/CandidateBottomNav";
import { API_URL } from "../config/api";
import { authHeaders, clearSessionToken } from "../config/session";
import { colors } from "../theme/colors";

export default function MenuAreaScreen({ navigation }) {
  const [profile, setProfile] = useState({}); const [applications, setApplications] = useState([]);
  const load = useCallback(async () => { try { const [profileRes, applicationsRes] = await Promise.all([fetch(`${API_URL}/profile/me`, { headers: authHeaders() }), fetch(`${API_URL}/applications`, { headers: authHeaders() })]); if (profileRes.ok) setProfile(await profileRes.json()); if (applicationsRes.ok) setApplications(await applicationsRes.json()); } catch (_error) {} }, []);
  useFocusEffect(useCallback(() => { load(); }, [load]));
  const completed = [profile.name, profile.phone, profile.professionalTitle, profile.experience !== undefined && profile.experience !== null, profile.skills?.length, profile.education, profile.modality, profile.accessibility?.length].filter(Boolean).length;
  const completion = Math.round((completed / 8) * 100);
  const submitted = applications.filter((item) => String(item.status || "").toLowerCase() === "postulado").length;
  const cvViewed = applications.filter((item) => ["cv visto", "en proceso", "finalista"].includes(String(item.status || "").toLowerCase())).length;
  const inProcess = applications.filter((item) => String(item.status || "").toLowerCase() === "en proceso").length;
  const finalists = applications.filter((item) => String(item.status || "").toLowerCase() === "finalista").length;
  const logout = () => Alert.alert("Cerrar sesión", "¿Quieres cerrar tu sesión?", [{ text: "Cancelar", style: "cancel" }, { text: "Cerrar sesión", style: "destructive", onPress: async () => { await clearSessionToken(); navigation.replace("Welcome"); } }]);

  return <View style={styles.screen}><ScrollView contentContainerStyle={styles.container}>
    <Text style={styles.headerTitle}>Mi área</Text><Text style={styles.subtitle}>Tu perfil y actividad</Text>
    <Pressable style={styles.profileCard} onPress={() => navigation.navigate("CandidateProfile")} accessibilityRole="button" accessibilityLabel="Editar mi perfil">
      <View style={styles.avatar}><Text style={styles.avatarText}>{String(profile.name || "U").trim().charAt(0).toUpperCase()}</Text></View><View style={styles.profileInfo}><Text style={styles.name}>{profile.name || "Mi perfil"}</Text><Text style={styles.profession}>{profile.professionalTitle || "Perfil profesional"}</Text><Text style={styles.completion}>Perfil completado <Text style={styles.completionValue}>{completion}%</Text></Text></View><Text style={styles.chevron}>›</Text>
    </Pressable>
    <View style={styles.statsRow}><Stat label="Postulaciones" value={applications.length} /><Stat label="Favoritos" value="—" /><Stat label="Match" value={applications.length ? `${Math.round(applications.reduce((sum, item) => sum + Number(item.matchScore || 0), 0) / applications.length)}%` : "—"} /></View>
    <View style={styles.listCard}>
      <MenuRow icon="CV" label="Mi CV" onPress={() => navigation.navigate("CV")} />
      <MenuRow icon="♡" label="Ofertas ocultas" onPress={() => Alert.alert("Ofertas ocultas", "No tienes ofertas ocultas.")} />
      <MenuRow icon="+" label="Desarrollo profesional" onPress={() => Alert.alert("Desarrollo profesional", "Próximamente encontrarás recursos para potenciar tu perfil.")} />
      <MenuRow icon="⚙" label="Configuración" onPress={() => Alert.alert("Configuración", "Las opciones de configuración se habilitarán próximamente.")} />
      <MenuRow icon="↪" label="Cerrar sesión" onPress={logout} last />
    </View>
    <View style={styles.applicationSummary}><Text style={styles.summaryTitle}>Resumen de postulaciones</Text><View style={styles.summaryGrid}><StatSmall label="Postulado" value={submitted} /><StatSmall label="CV Visto" value={cvViewed} /><StatSmall label="En proceso" value={inProcess} /><StatSmall label="Finalista" value={finalists} /></View></View>
  </ScrollView><CandidateBottomNav navigation={navigation} active="menu" /></View>;
}
function Stat({ label, value }) { return <View style={styles.stat}><Text style={styles.statValue}>{value}</Text><Text style={styles.statLabel}>{label}</Text></View>; }
function StatSmall({ label, value }) { return <View style={styles.statSmall}><Text style={styles.statSmallValue}>{value}</Text><Text style={styles.statSmallLabel}>{label}</Text></View>; }
function MenuRow({ icon, label, onPress, last }) { return <Pressable style={[styles.listRow, !last && styles.listBorder]} onPress={onPress} accessibilityRole="button" accessibilityLabel={label}><Text style={styles.rowIcon}>{icon}</Text><Text style={styles.rowLabel}>{label}</Text><Text style={styles.chevronSmall}>›</Text></Pressable>; }
const styles = StyleSheet.create({ screen: { flex: 1, backgroundColor: colors.background }, container: { flexGrow: 1, paddingBottom: 108 }, headerTitle: { color: colors.text, backgroundColor: colors.background, textAlign: "left", fontSize: 29, fontWeight: "800", paddingHorizontal: 24, paddingTop: 22, paddingBottom: 2 }, subtitle: { paddingHorizontal: 24, color: "#64748B", fontSize: 15, marginBottom: 14 }, profileCard: { marginHorizontal: 18, padding: 18, backgroundColor: colors.white, borderRadius: 22, flexDirection: "row", alignItems: "center", elevation: 3 }, avatar: { width: 74, height: 74, borderRadius: 37, backgroundColor: "#EDE9FE", alignItems: "center", justifyContent: "center", marginRight: 15 }, avatarText: { fontSize: 31, fontWeight: "800", color: colors.primary }, profileInfo: { flex: 1 }, name: { fontSize: 22, fontWeight: "800", color: colors.text }, profession: { fontSize: 15, color: "#64748B", marginTop: 4 }, completion: { fontSize: 13, color: colors.text, marginTop: 7 }, completionValue: { color: colors.success, fontWeight: "800" }, chevron: { fontSize: 30, color: "#64748B" }, statsRow: { flexDirection: "row", gap: 9, marginHorizontal: 18, marginTop: 16 }, stat: { flex: 1, backgroundColor: colors.white, borderRadius: 17, paddingVertical: 14, alignItems: "center", borderWidth: 1, borderColor: "#E2E8F0" }, statValue: { fontSize: 22, fontWeight: "800", color: colors.primary }, statLabel: { fontSize: 11, fontWeight: "700", color: "#64748B", marginTop: 4, textAlign: "center" }, listCard: { marginHorizontal: 18, marginTop: 16, backgroundColor: colors.white, borderRadius: 18, overflow: "hidden" }, listRow: { minHeight: 62, flexDirection: "row", alignItems: "center", paddingHorizontal: 18 }, listBorder: { borderBottomWidth: 1, borderBottomColor: "#E2E8F0" }, rowIcon: { width: 48, fontSize: 18, fontWeight: "800", color: colors.primary }, rowLabel: { flex: 1, fontSize: 16, fontWeight: "700", color: colors.text }, chevronSmall: { fontSize: 25, color: "#64748B" }, applicationSummary: { marginHorizontal: 18, marginTop: 16, marginBottom: 6, padding: 15, borderRadius: 18, backgroundColor: "#EDE9FE" }, summaryTitle: { fontWeight: "800", color: colors.primary, marginBottom: 10 }, summaryGrid: { flexDirection: "row", flexWrap: "wrap", gap: 8 }, statSmall: { width: "48%", backgroundColor: colors.white, borderRadius: 12, padding: 10 }, statSmallValue: { fontSize: 19, fontWeight: "800", color: colors.primary }, statSmallLabel: { fontSize: 11, color: "#64748B", marginTop: 2 } });
