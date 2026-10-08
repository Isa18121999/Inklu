import React from "react";
import { View, Text, StyleSheet, Pressable } from "react-native";
import { colors } from "../theme/colors";
import { font, horizontalPadding, rs } from "../theme/responsive";

export default function CreateAccountScreen({ navigation }) {
  return <View style={styles.container}>
    <Text style={styles.title} accessibilityRole="header">¿Cómo deseas registrarte?</Text>
    <Text style={styles.description}>Elige el tipo de cuenta que usarás en Inklu.</Text>

    <Pressable style={[styles.option, styles.candidate]} onPress={() => navigation.navigate("CandidateRegister")} accessibilityRole="button" accessibilityLabel="Registrarme como candidato">
      <View style={styles.iconCircle}><Text style={styles.iconText}>C</Text></View>
      <View style={styles.optionText}><Text style={styles.optionTitle}>Soy candidato</Text><Text style={styles.optionDescription}>Busca y postula a empleos</Text></View>
      <Text style={styles.chevron}>›</Text>
    </Pressable>

    <Pressable style={[styles.option, styles.company]} onPress={() => navigation.navigate("CompanyRegister")} accessibilityRole="button" accessibilityLabel="Registrarme como empresa">
      <View style={[styles.iconCircle, styles.companyIcon]}><Text style={[styles.iconText, styles.companyIconText]}>E</Text></View>
      <View style={styles.optionText}><Text style={styles.optionTitle}>Soy empresa</Text><Text style={styles.optionDescription}>Publica y gestiona oportunidades inclusivas</Text></View>
      <Text style={styles.chevron}>›</Text>
    </Pressable>

    <Pressable onPress={() => navigation.goBack()} accessibilityRole="button" accessibilityLabel="Volver"><Text style={styles.back}>Volver</Text></Pressable>
  </View>;
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: "center", paddingHorizontal: horizontalPadding, backgroundColor: colors.white },
  title: { textAlign: "center", fontSize: font(30), fontWeight: "800", color: colors.primary, marginBottom: rs(8, 6, 10) },
  description: { textAlign: "center", fontSize: font(17), color: colors.text, marginBottom: rs(32, 24, 36) },
  option: { flexDirection: "row", alignItems: "center", padding: rs(20, 15, 22), borderRadius: rs(22, 18, 24), backgroundColor: colors.white, marginBottom: rs(16, 12, 18), borderWidth: 2 },
  candidate: { borderColor: colors.primary },
  company: { borderColor: colors.secondary },
  iconCircle: { width: rs(52, 44, 56), height: rs(52, 44, 56), borderRadius: rs(26, 22, 28), backgroundColor: colors.primary, alignItems: "center", justifyContent: "center", marginRight: rs(15, 11, 17) },
  companyIcon: { backgroundColor: colors.secondary },
  iconText: { fontSize: font(23), fontWeight: "800", color: colors.white },
  companyIconText: { color: colors.white },
  optionText: { flex: 1 },
  optionTitle: { fontSize: font(21), fontWeight: "800", color: colors.text },
  optionDescription: { fontSize: font(14), color: colors.text, marginTop: 4 },
  chevron: { fontSize: font(30), color: colors.primary },
  back: { textAlign: "center", color: colors.primary, fontWeight: "700", marginTop: 8 }
});
