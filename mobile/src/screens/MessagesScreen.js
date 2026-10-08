import React, { useCallback, useState } from "react";
import { ActivityIndicator, Pressable, ScrollView, Text, View, StyleSheet } from "react-native";
import { useFocusEffect } from "@react-navigation/native";
import CandidateBottomNav from "../components/CandidateBottomNav";
import { API_URL } from "../config/api";
import { authHeaders } from "../config/session";
import { colors } from "../theme/colors";
import { font, horizontalPadding, rs } from "../theme/responsive";

export default function MessagesScreen({ navigation }) {
  const [applications, setApplications] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadMessages = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch(`${API_URL}/applications`, { headers: authHeaders() });
      if (!response.ok) throw new Error();
      const data = await response.json();
      setApplications((data || []).filter((item) => String(item.status || "").toLowerCase() !== "postulado"));
    } catch (_error) {
      setApplications([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useFocusEffect(useCallback(() => { loadMessages(); }, [loadMessages]));

  return (
    <View style={styles.screen}>
      <ScrollView contentContainerStyle={styles.container}>
        <Text style={styles.title} accessibilityRole="header">Mensajes</Text>
        <Text style={styles.subtitle}>Comunícate con las empresas después de avanzar en tu postulación.</Text>
        {loading ? <ActivityIndicator color={colors.primary} style={styles.loader} /> : applications.length ? applications.map((application) => (
          <Pressable key={application._id} style={styles.card} onPress={() => navigation.navigate("Chat", { applicationId: application._id })} accessibilityRole="button" accessibilityLabel={`Abrir chat con ${application.jobId?.companyId?.name || "Empresa"}`}>
            <View style={styles.avatar}><Text style={styles.avatarText}>{String(application.jobId?.companyId?.name || "E").charAt(0).toUpperCase()}</Text></View>
            <View style={styles.info}>
              <Text style={styles.company}>{application.jobId?.companyId?.name || "Empresa"}</Text>
              <Text style={styles.job}>{application.jobId?.title || "Postulación"}</Text>
              <Text style={styles.status}>{application.status || "En proceso"}</Text>
            </View>
            <Text style={styles.chevron}>›</Text>
          </Pressable>
        )) : (
          <View style={styles.empty}>
            <Text style={styles.emptyIcon}>✉</Text>
            <Text style={styles.emptyTitle}>Aún no tienes conversaciones</Text>
            <Text style={styles.emptyText}>Cuando una postulación avance, podrás comunicarte con la empresa desde aquí.</Text>
          </View>
        )}
      </ScrollView>
      <CandidateBottomNav navigation={navigation} active="messages" />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  container: { flexGrow: 1, paddingHorizontal: horizontalPadding, paddingTop: rs(22, 18, 26), paddingBottom: 108 },
  title: { fontSize: font(29), fontWeight: "800", color: colors.text },
  subtitle: { marginTop: 6, fontSize: font(15.5), lineHeight: font(22), color: "#64748B" },
  loader: { marginTop: 30 },
  card: { marginTop: 14, padding: 15, borderRadius: 18, backgroundColor: colors.white, borderWidth: 1, borderColor: "#E2E8F0", flexDirection: "row", alignItems: "center", elevation: 2 },
  avatar: { width: rs(48, 44, 52), height: rs(48, 44, 52), borderRadius: rs(24, 22, 26), backgroundColor: colors.secondary, alignItems: "center", justifyContent: "center" },
  avatarText: { color: colors.white, fontSize: font(20), fontWeight: "800" },
  info: { flex: 1, marginLeft: 12 },
  company: { color: colors.text, fontSize: font(16), fontWeight: "800" },
  job: { color: "#64748B", fontSize: font(14), marginTop: 2 },
  status: { color: colors.primary, fontSize: font(12.5), fontWeight: "700", marginTop: 5 },
  chevron: { color: colors.primary, fontSize: font(30), marginLeft: 8 },
  empty: { marginTop: rs(90, 60, 120), alignItems: "center", paddingHorizontal: 20 },
  emptyIcon: { color: colors.primary, fontSize: font(44) },
  emptyTitle: { marginTop: 12, color: colors.text, fontSize: font(19), fontWeight: "800", textAlign: "center" },
  emptyText: { marginTop: 8, color: "#64748B", fontSize: font(15), lineHeight: font(22), textAlign: "center" }
});
