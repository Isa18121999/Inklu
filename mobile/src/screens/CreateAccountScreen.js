import React from "react";
import { View, Text, StyleSheet, Pressable } from "react-native";
import { colors } from "../theme/colors";

export default function CreateAccountScreen({ navigation }) {
  return <View style={styles.container}>
    <Text style={styles.title} accessibilityRole="header">¿Cómo deseas registrarte?</Text>
    <Text style={styles.description}>Elige el tipo de cuenta que usarás en Inklu.</Text>
    <Pressable style={[styles.option, styles.candidate]} onPress={() => navigation.navigate("CandidateRegister")} accessibilityRole="button" accessibilityLabel="Registrarme como candidato">
      <View style={styles.iconCircle}><Text style={styles.iconText}>C</Text></View><View style={styles.optionText}><Text style={styles.optionTitle}>Soy candidato</Text><Text style={styles.optionDescription}>Busca y postula a empleos</Text></View><Text style={styles.chevron}>›</Text>
    </Pressable>
    <Pressable style={[styles.option, styles.company]} onPress={() => navigation.navigate("CompanyRegister")} accessibilityRole="button" accessibilityLabel="Registrarme como empresa">
      <View style={[styles.iconCircle, styles.companyIcon]}><Text style={[styles.iconText, styles.companyIconText]}>E</Text></View><View style={styles.optionText}><Text style={styles.optionTitle}>Soy empresa</Text><Text style={styles.optionDescription}>Publica y gestiona oportunidades inclusivas</Text></View><Text style={styles.chevron}>›</Text>
    </Pressable>
    <Pressable onPress={() => navigation.goBack()} accessibilityRole="button" accessibilityLabel="Volver"><Text style={styles.back}>Volver</Text></Pressable>
  </View>;
}

const styles = StyleSheet.create({ container: { flex: 1, justifyContent: "center", padding: 24, backgroundColor: colors.white }, title: { textAlign: "center", fontSize: 30, fontWeight: "800", color: colors.primary, marginBottom: 8 }, description: { textAlign: "center", fontSize: 17, color: "#64748B", marginBottom: 32 }, option: { flexDirection: "row", alignItems: "center", padding: 20, borderRadius: 22, backgroundColor: colors.white, marginBottom: 16, borderWidth: 2 }, candidate: { borderColor: colors.primary }, company: { borderColor: colors.secondary }, iconCircle: { width: 52, height: 52, borderRadius: 26, backgroundColor: "#EDE9FE", alignItems: "center", justifyContent: "center", marginRight: 15 }, companyIcon: { backgroundColor: "#DBEAFE" }, iconText: { fontSize: 23, fontWeight: "800", color: colors.primary }, companyIconText: { color: colors.secondary }, optionText: { flex: 1 }, optionTitle: { fontSize: 21, fontWeight: "800", color: colors.text }, optionDescription: { fontSize: 14, color: "#64748B", marginTop: 4 }, chevron: { fontSize: 30, color: "#64748B" }, back: { textAlign: "center", color: colors.primary, fontWeight: "700", marginTop: 8 }
});
