import React from "react";
import { View, Text, StyleSheet } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { colors } from "../theme/colors";

export default function AccessScreen({ navigation }) {
  return (
    <View style={styles.container}>
      <Text style={styles.title} accessibilityRole="header">
        ¡Bienvenido a Inklu!
      </Text>

      <Text style={styles.description}>
        Conectamos talento con oportunidades laborales inclusivas mediante tecnología accesible e inteligencia artificial.
      </Text>

      <AccessibleButton
        title="Soy candidato"
        accessibilityHint="Abre el registro de candidato."
        onPress={() => navigation.navigate("CandidateRegister")}
      />

      <AccessibleButton
        title="Soy empresa"
        accessibilityHint="Abre el registro de empresa."
        type="secondary"
        onPress={() => navigation.navigate("CompanyRegister")}
      />

      <AccessibleButton
        title="👀 Ver demo sin backend"
        type="secondary"
        accessibilityHint="Permite recorrer pantallas de ejemplo sin conexión al servidor."
        onPress={() => navigation.navigate("Demo")}
      />

      <AccessibleButton
        title="Iniciar sesión"
        accessibilityHint="Abre el inicio de sesión."
        onPress={() => navigation.navigate("Login")}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    padding: 24,
    backgroundColor: colors.white,
  },
  title: {
    textAlign: "center",
    fontSize: 30,
    fontWeight: "800",
    color: colors.text,
    marginBottom: 16,
  },
  description: {
    textAlign: "center",
    fontSize: 17,
    lineHeight: 25,
    color: colors.text,
    marginBottom: 24,
  },
});
