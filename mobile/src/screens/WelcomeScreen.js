import React from "react";
import { View, Text, Image, StyleSheet } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { colors } from "../theme/colors";
import { font, horizontalPadding, rs } from "../theme/responsive";

export default function WelcomeScreen({ navigation }) {
  return <View style={styles.container}>
    <Image source={require("../../assets/inklu-icon-512.png")} style={styles.logoImage} resizeMode="contain" accessibilityRole="image" accessibilityLabel="Logo de Inklu" />
    <Text style={styles.title} accessibilityRole="header">¡Bienvenido a Inklu!</Text>
    <Text style={styles.description}>Encuentra oportunidades de trabajo{`\n`}de forma inclusiva e inteligente.</Text>
    <AccessibleButton title="Empezar" accessibilityHint="Comienza el registro y permite elegir entre candidato o empresa." onPress={() => navigation.navigate("CreateAccount")} />
    <AccessibleButton title="Iniciar sesión" type="secondary" accessibilityHint="Abre el inicio de sesión." onPress={() => navigation.navigate("Login")} />
    <AccessibleButton title="Crear una cuenta" type="secondary" accessibilityHint="Abre la selección de tipo de cuenta." onPress={() => navigation.navigate("CreateAccount")} />
  </View>;
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: "center", paddingHorizontal: horizontalPadding, backgroundColor: colors.white },
  logoImage: { width: rs(150, 128, 168), height: rs(150, 128, 168), alignSelf: "center", marginBottom: rs(18, 14, 22) },
  title: { textAlign: "center", fontSize: font(30), fontWeight: "800", color: colors.text, marginBottom: rs(10, 8, 12) },
  description: { textAlign: "center", fontSize: font(17), lineHeight: font(25), color: "#64748B", marginBottom: rs(28, 22, 32) }
});
