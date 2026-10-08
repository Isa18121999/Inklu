import React, { useState } from "react";
import { Alert, KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, View } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { API_URL } from "../config/api";
import { colors } from "../theme/colors";
import { setSessionToken } from "../config/session";
import { validateEmail } from "../config/validation";
import { font, horizontalPadding, rs } from "../theme/responsive";

const AUTH_URL = `${API_URL}/auth`;
export default function LoginScreen({ navigation }) {
  const [email, setEmail] = useState(""); const [password, setPassword] = useState(""); const [loading, setLoading] = useState(false);
  const handleLogin = async () => {
    const normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail || !password) { Alert.alert("Datos incompletos", "Ingresa tu email y contraseña."); return; }
    if (!validateEmail(normalizedEmail)) { Alert.alert("Correo no válido", "Ingresa un correo electrónico válido."); return; }
    setLoading(true);
    try {
      const response = await fetch(`${AUTH_URL}/login`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email: normalizedEmail, password }) });
      const data = await response.json(); if (!response.ok) throw new Error(data.message || "No se pudo iniciar sesión");
      setSessionToken(data.token); const params = { userId: data.user.id, token: data.token };
      if (data.user.role === "company") navigation.replace("CompanyDashboard", params); else if (data.user.role === "candidate") navigation.replace("CandidateDashboard", params); else Alert.alert("Rol no disponible");
    } catch (error) { Alert.alert("Error de inicio de sesión", error.message || "Error de conexión"); } finally { setLoading(false); }
  };
  return <KeyboardAvoidingView style={styles.screen} behavior={Platform.OS === "ios" ? "padding" : undefined}>
    <View style={styles.container}>
      <Text style={styles.title} accessibilityRole="header">Iniciar sesión</Text>
      <TextInput style={styles.input} placeholder="Email" value={email} onChangeText={setEmail} keyboardType="email-address" autoCapitalize="none" autoCorrect={false} accessibilityLabel="Correo electrónico" accessibilityHint="Ingresa tu correo electrónico" textContentType="emailAddress" />
      <TextInput style={styles.input} placeholder="Contraseña" value={password} onChangeText={setPassword} secureTextEntry accessibilityLabel="Contraseña" accessibilityHint="Ingresa tu contraseña" textContentType="password" />
      <AccessibleButton title={loading ? "Ingresando..." : "Iniciar sesión"} onPress={handleLogin} disabled={loading} accessibilityHint="Activa para acceder a tu cuenta" />
    </View>
  </KeyboardAvoidingView>;
}
const styles = StyleSheet.create({ screen: { flex: 1, backgroundColor: colors.white }, container: { flex: 1, justifyContent: "center", paddingHorizontal: horizontalPadding }, title: { fontSize: font(30), fontWeight: "800", color: colors.primary }, input: { borderWidth: 1, borderColor: colors.secondary, borderRadius: rs(10, 8, 12), padding: rs(16, 13, 18), marginTop: rs(14, 11, 16), fontSize: font(16) } });
