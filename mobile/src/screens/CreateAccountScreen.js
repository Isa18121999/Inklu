import React from "react";
import { View, Text, StyleSheet } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { colors } from "../theme/colors";

export default function CreateAccountScreen({ navigation }) {
  return (
    <View style={styles.container}>
      <Text style={styles.title} accessibilityRole="header">
        Crear una cuenta
      </Text>
      <Text style={styles.description}>
        Selecciona cómo quieres usar Inklu.
      </Text>

      <AccessibleButton
        title="Soy candidato"
        accessibilityHint="Crear una cuenta como candidato."
        onPress={() => navigation.navigate("CandidateRegister")}
      />
      <AccessibleButton
        title="Soy empresa"
        accessibilityHint="Crear una cuenta como empresa."
        type="secondary"
        onPress={() => navigation.navigate("CompanyRegister")}
      />
      <AccessibleButton
        title="Volver"
        accessibilityHint="Volver a la pantalla de inicio."
        type="secondary"
        onPress={() => navigation.goBack()}
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
