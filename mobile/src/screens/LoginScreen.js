import React, { useState } from "react";
import { Alert, KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, View, Pressable, Linking } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { API_URL } from "../config/api";
import { colors } from "../theme/colors";
import { setSessionToken } from "../config/session";
import { validateEmail } from "../config/validation";
import { font, horizontalPadding, rs } from "../theme/responsive";

const AUTH_URL = `${API_URL}/auth`;
export default function LoginScreen({ navigation }) {
  const [email, setEmail] = useState(""); const [password, setPassword] = useState(""); const [loading, setLoading] = useState(false); const [recoveryLoading, setRecoveryLoading] = useState(false);
  const handleLogin = async () => {
    const normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail || !password) { Alert.alert("Datos incompletos", "Ingresa tu correo electrónico y contraseña."); return; }
    if (!validateEmail(normalizedEmail)) { Alert.alert("Correo no válido", "Ingresa un correo electrónico válido."); return; }
    setLoading(true);
    try {
      const response = await fetch(`${AUTH_URL}/login`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email: normalizedEmail, password }) });
      const data = await response.json(); if (!response.ok) throw new Error(data.message || "No se pudo iniciar sesión");
      setSessionToken(data.token); const params = { userId: data.user.id, token: data.token };
      if (data.user.role === "company") navigation.replace("CompanyDashboard", params); else if (data.user.role === "candidate") navigation.replace("CandidateDashboard", params); else Alert.alert("Rol no disponible");
    } catch (error) { Alert.alert("Error de inicio de sesión", error.message || "Error de conexión"); } finally { setLoading(false); }
  };
  const handleGoogleLogin = async () => {
    try {
      await Linking.openURL(`${AUTH_URL}/google/start`);
    } catch (error) {
      Alert.alert("Google", "No se pudo abrir el inicio de sesión con Google.");
    }
  };
  const handleForgotPassword = async () => {
    const normalizedEmail = email.trim().toLowerCase();
    if (!validateEmail(normalizedEmail)) { Alert.alert("Correo requerido", "Ingresa primero el correo de tu cuenta para enviarte el enlace de recuperación."); return; }
    setRecoveryLoading(true);
    try {
      const response = await fetch(`${AUTH_URL}/forgot-password`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email: normalizedEmail }) });
      const data = await response.json();
      if (!response.ok) throw new Error(data.message || "No se pudo solicitar la recuperación");
      Alert.alert("Revisa tu correo", data.message || "Te enviamos las instrucciones para restablecer tu contraseña.");
    } catch (error) { Alert.alert("Recuperación no disponible", error.message || "Intenta nuevamente más tarde."); } finally { setRecoveryLoading(false); }
  };
  return <KeyboardAvoidingView style={styles.screen} behavior={Platform.OS === "ios" ? "padding" : undefined}>
    <View style={styles.container}>
      <Text style={styles.title} accessibilityRole="header">Iniciar sesión</Text>
      <Text style={styles.subtitle}>Accede a tu cuenta de Inklu</Text>
      <TextInput style={styles.input} placeholder="Correo electrónico" value={email} onChangeText={setEmail} keyboardType="email-address" autoCapitalize="none" autoCorrect={false} accessibilityLabel="Correo electrónico" accessibilityHint="Ingresa tu correo electrónico" textContentType="emailAddress" />
      <TextInput style={styles.input} placeholder="Contraseña" value={password} onChangeText={setPassword} secureTextEntry accessibilityLabel="Contraseña" accessibilityHint="Ingresa tu contraseña" textContentType="password" />
      <Pressable onPress={handleForgotPassword} disabled={recoveryLoading} accessibilityRole="button" accessibilityLabel="¿Olvidaste tu contraseña?" style={styles.forgot}><Text style={styles.forgotText}>{recoveryLoading ? "Enviando..." : "¿Olvidaste tu contraseña?"}</Text></Pressable>
      <AccessibleButton title={loading ? "Ingresando..." : "Iniciar sesión"} onPress={handleLogin} disabled={loading} accessibilityHint="Activa para acceder a tu cuenta" />
      <View style={styles.dividerRow}><View style={styles.divider} /><Text style={styles.or}>o</Text><View style={styles.divider} /></View>
      <AccessibleButton title="Iniciar con Google" type="secondary" onPress={handleGoogleLogin} accessibilityHint="Inicia sesión usando una cuenta de Google" />
    </View>
  </KeyboardAvoidingView>;
}
const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.white },
  container: { flex: 1, justifyContent: "center", paddingHorizontal: horizontalPadding },
  title: { fontSize: font(30), fontWeight: "800", color: colors.primary, marginBottom: rs(6, 5, 8) },
  subtitle: { fontSize: font(16), color: colors.text, marginBottom: rs(8, 6, 10) },
  input: { borderWidth: 1, borderColor: colors.secondary, borderRadius: rs(10, 8, 12), padding: rs(16, 13, 18), marginTop: rs(12, 10, 14), fontSize: font(16), color: colors.text },
  forgot: { alignSelf: "flex-end", marginTop: rs(10, 8, 12), paddingVertical: rs(4, 3, 6) },
  forgotText: { color: colors.primary, fontSize: font(14), fontWeight: "700" },
  dividerRow: { flexDirection: "row", alignItems: "center", marginVertical: rs(10, 8, 12) },
  divider: { flex: 1, height: 1, backgroundColor: "#E2E8F0" },
  or: { marginHorizontal: rs(10, 8, 12), color: "#64748B", fontSize: font(14) }
});
