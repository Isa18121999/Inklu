import React from "react";
import { View, Text, Image, StyleSheet } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { colors } from "../theme/colors";

export default function WelcomeScreen({ navigation }) {
  return (
    <View style={styles.container}>
      <Image
        source={require("../../assets/inklu-icon-512.png")}
        style={styles.logoImage}
        resizeMode="contain"
        accessibilityRole="image"
        accessibilityLabel="Logo de Inklu"
      />

      <Text style={styles.appName} accessibilityRole="header">Inklu</Text>

      <Text style={styles.tagline}>
        Oportunidades laborales inclusivas para todos.
      </Text>

      <AccessibleButton
        title="Empezar"
        accessibilityHint="Continúa a las opciones de acceso de Inklu."
        onPress={() => navigation.navigate("Access")}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    padding: 32,
    backgroundColor: colors.white,
  },
  logoImage: {
    width: 220,
    height: 220,
    alignSelf: "center",
    marginBottom: 14,
  },
  appName: {
    textAlign: "center",
    fontSize: 46,
    fontWeight: "800",
    color: colors.primary,
    marginBottom: 12,
  },
  tagline: {
    textAlign: "center",
    fontSize: 18,
    lineHeight: 26,
    color: colors.text,
    marginBottom: 30,
  },
});
