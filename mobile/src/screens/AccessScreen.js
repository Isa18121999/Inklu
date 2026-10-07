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
        title="Iniciar sesión"
        accessibilityHint="Abre el inicio de sesión."
        onPress={() => navigation.navigate("Login")}
      />

      <AccessibleButton
        title="Crear una cuenta"
        accessibilityHint="Permite elegir si deseas registrarte como candidato o empresa."
        type="secondary"
        onPress={() => navigation.navigate("CreateAccount")}
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
