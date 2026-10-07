import React from "react";
import { View, Text, Image, StyleSheet } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { colors } from "../theme/colors";

export default function WelcomeScreen({ navigation }) {
  return <View style={styles.container}>
    <Image source={require("../../assets/inklu-icon-512.png")} style={styles.logoImage} resizeMode="contain" accessibilityRole="image" accessibilityLabel="Logo de Inklu" />
    <Text style={styles.title} accessibilityRole="header">¡Bienvenido a Inklu!</Text>
    <Text style={styles.description}>Encuentra oportunidades de trabajo{`\n`}de forma inclusiva e inteligente.</Text>
    <AccessibleButton title="Iniciar sesión" accessibilityHint="Abre el inicio de sesión." onPress={() => navigation.navigate("Login")} />
    <AccessibleButton title="Crear una cuenta" accessibilityHint="Permite elegir si deseas registrarte como candidato o empresa." type="secondary" onPress={() => navigation.navigate("CreateAccount")} />
  </View>;
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: "center", padding: 24, backgroundColor: colors.white },
  logoImage: { width: 150, height: 150, alignSelf: "center", marginBottom: 18 },
  title: { textAlign: "center", fontSize: 30, fontWeight: "800", color: colors.text, marginBottom: 10 },
  description: { textAlign: "center", fontSize: 17, lineHeight: 25, color: "#64748B", marginBottom: 28 }
});
