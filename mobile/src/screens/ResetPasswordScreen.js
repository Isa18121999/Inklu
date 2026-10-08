import React, { useState } from "react";
import { Alert, KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, View } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { API_URL } from "../config/api";
import { colors } from "../theme/colors";
import { font, horizontalPadding, rs } from "../theme/responsive";
import { validatePassword } from "../config/validation";

export default function ResetPasswordScreen({ navigation, route }) {
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const token = route?.params?.token || "";

  const handleReset = async () => {
    if (!token) { Alert.alert("Enlace inválido", "Solicita nuevamente la recuperación de contraseña."); return; }
    if (!validatePassword(password)) { Alert.alert("Contraseña no válida", "Usa 8 a 128 caracteres, con mayúscula, minúscula, número y carácter especial."); return; }
    if (password !== confirmPassword) { Alert.alert("Las contraseñas no coinciden", "Verifica ambos campos."); return; }
    setLoading(true);
    try {
      const response = await fetch(`${API_URL}/auth/reset-password`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ token, password }) });
      const data = await response.json();
      if (!response.ok) throw new Error(data.message || "No se pudo actualizar la contraseña");
      Alert.alert("Contraseña actualizada", "Ya puedes iniciar sesión con tu nueva contraseña.", [{ text: "Iniciar sesión", onPress: () => navigation.replace("Login") }]);
    } catch (error) {
      Alert.alert("Error", error.message || "No se pudo actualizar la contraseña.");
    } finally { setLoading(false); }
  };

  return <KeyboardAvoidingView style={styles.screen} behavior={Platform.OS === "ios" ? "padding" : undefined}>
    <View style={styles.container}>
      <Text style={styles.title} accessibilityRole="header">Nueva contraseña</Text>
      <Text style={styles.subtitle}>Crea una nueva contraseña para tu cuenta de Inklu.</Text>
      <TextInput style={styles.input} placeholder="Nueva contraseña" value={password} onChangeText={setPassword} secureTextEntry accessibilityLabel="Nueva contraseña" textContentType="newPassword" />
      <TextInput style={styles.input} placeholder="Repetir contraseña" value={confirmPassword} onChangeText={setConfirmPassword} secureTextEntry accessibilityLabel="Repetir contraseña" textContentType="newPassword" />
      <AccessibleButton title={loading ? "Actualizando..." : "Actualizar contraseña"} onPress={handleReset} disabled={loading} />
    </View>
  </KeyboardAvoidingView>;
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.white },
  container: { flex: 1, justifyContent: "center", paddingHorizontal: horizontalPadding },
  title: { fontSize: font(30), fontWeight: "800", color: colors.primary, marginBottom: rs(6, 5, 8) },
  subtitle: { fontSize: font(16), color: colors.text, marginBottom: rs(8, 6, 10) },
  input: { borderWidth: 1, borderColor: colors.secondary, borderRadius: rs(10, 8, 12), padding: rs(16, 13, 18), marginTop: rs(12, 10, 14), fontSize: font(16), color: colors.text }
});
