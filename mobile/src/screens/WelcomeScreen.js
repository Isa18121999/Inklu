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

      <Text style={styles.appName}>Inklu</Text>

      <Text style={styles.title} accessibilityRole="header">
        ¡Bienvenidos a Inklu!
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
  logoImage: {
    width: 190,
    height: 190,
    alignSelf: "center",
    marginBottom: 10,
  },
  appName: {
    textAlign: "center",
    fontSize: 40,
    fontWeight: "800",
    color: colors.primary,
    marginBottom: 12,
  },
  title: {
    textAlign: "center",
    fontSize: 28,
    fontWeight: "800",
    color: colors.text,
  },
  description: {
    textAlign: "center",
    marginTop: 14,
    marginBottom: 20,
    fontSize: 17,
    lineHeight: 25,
    color: colors.text,
  },
});
