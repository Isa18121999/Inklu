import React, { useCallback, useState } from "react";
import { useFocusEffect } from "@react-navigation/native";
import { ActivityIndicator, Alert, ScrollView, View, Text, StyleSheet } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { API_URL } from "../config/api";
import { colors } from "../theme/colors";
import { authHeaders, clearSessionToken } from "../config/session";

const criteriaLabels = { skills: "Habilidades", experience: "Experiencia", education: "Educación", modality: "Modalidad", accessibility: "Accesibilidad" };

export default function CandidateDashboard({ navigation }) {
  const [profileName, setProfileName] = useState("");
  const [matches, setMatches] = useState([]); const [loading, setLoading] = useState(true);
  const [unreadCount, setUnreadCount] = useState(0);

  const loadProfileName = useCallback(async () => {
    try {
      const response = await fetch(`${API_URL}/profile/me`, { headers: authHeaders() });
      if (!response.ok) return;
      const profile = await response.json();
      setProfileName(String(profile.name || "").trim());
    } catch (_error) {
      setProfileName("");
    }
  }, []);

  const loadUnreadCount = useCallback(async () => {
    try {
      const response = await fetch(`${API_URL}/notifications`, { headers: authHeaders() });
      if (!response.ok) return;
      const data = await response.json();
      setUnreadCount(Number(data.unreadCount || 0));
    } catch (_error) {
      setUnreadCount(0);
    }
  }, []);
  const loadMatches = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch(`${API_URL}/profile/matches`, { headers: authHeaders() });
      const data = response.ok ? await response.json() : { matches: [] };
      setMatches((data.matches || []).slice(0, 3));
    } catch (_error) {
      setMatches([]);
    } finally {
      setLoading(false);
    }
  }, []);
  useFocusEffect(useCallback(() => {
    loadProfileName();
    loadMatches();
    loadUnreadCount();
  }, [loadProfileName, loadMatches, loadUnreadCount]));
  const handleLogout = async () => { await clearSessionToken(); navigation.replace("Welcome"); };
  const confirmLogout = () => Alert.alert("Cerrar sesión", "¿Quieres cerrar tu sesión?", [{ text: "Cancelar", style: "cancel" }, { text: "Cerrar sesión", style: "destructive", onPress: handleLogout }]);
  return <ScrollView contentContainerStyle={styles.container}>
    <Text style={styles.title} accessibilityRole="header">Hola{profileName ? `, ${profileName}` : ""}</Text><Text style={styles.status}>Acreditación registrada 🟢</Text>
    <View style={styles.matchCard} accessible accessibilityLabel="Tus mejores coincidencias"><Text style={styles.matchTitle}>Tus mejores coincidencias</Text>
      {loading ? <ActivityIndicator color={colors.primary} /> : matches.length ? matches.map((job) => <View key={job._id} style={styles.matchRow}><View style={styles.matchInfo}><Text style={styles.jobTitle}>{job.title}</Text><Text>{job.companyId?.name || "Empresa"}</Text><Text style={styles.breakdownTitle}>Match integral</Text>{Object.entries(job.breakdown || {}).map(([key, value]) => <Text key={key} style={styles.breakdown}>• {criteriaLabels[key] || key}: {value}%</Text>)}{job.missingSkills?.length > 0 && <Text style={styles.warning}>⚠️ Faltan: {job.missingSkills.join(" · ")}</Text>}</View><Text style={styles.match}>{job.score}%</Text></View>) : <Text style={styles.caption}>Completa tus habilidades para encontrar coincidencias.</Text>}
    </View>
    <AccessibleButton title="🔎 Buscar empleos" onPress={() => navigation.navigate("Jobs")} />
    <AccessibleButton title={`🔔 Notificaciones${unreadCount ? ` (${unreadCount})` : ""}`} type="secondary" onPress={() => navigation.navigate("Notifications")} />
    <AccessibleButton title="📄 Mis postulaciones" type="secondary" onPress={() => navigation.navigate("Applications")} />
    <AccessibleButton title="👤 Editar mi perfil" onPress={() => navigation.navigate("CandidateProfile")} />
    <AccessibleButton title="🚪 Cerrar sesión" type="secondary" onPress={confirmLogout} />
  </ScrollView>;
}
const styles = StyleSheet.create({ container: { flexGrow: 1, padding: 24, backgroundColor: colors.white }, title: { fontSize: 30, fontWeight: "800", color: colors.primary }, status: { marginTop: 8, fontSize: 17, color: colors.success }, matchCard: { marginTop: 24, padding: 20, borderRadius: 16, backgroundColor: colors.background }, matchTitle: { fontSize: 18, fontWeight: "700", color: colors.text, marginBottom: 12 }, matchRow: { flexDirection: "row", alignItems: "flex-start", justifyContent: "space-between", paddingVertical: 14, borderTopWidth: 1, borderTopColor: "#CBD5E1" }, matchInfo: { flex: 1, paddingRight: 12 }, jobTitle: { fontSize: 16, fontWeight: "700", color: colors.text }, breakdownTitle: { marginTop: 8, fontWeight: "700", color: colors.primary }, breakdown: { fontSize: 14, marginTop: 2 }, warning: { marginTop: 6 }, match: { fontSize: 28, fontWeight: "800", color: colors.secondary }, caption: { color: colors.text } });
