import React, { useState } from "react";
import { Alert, KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, View } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { API_URL } from "../config/api";
import { colors } from "../theme/colors";
import { setSessionToken } from "../config/session";
import { sanitizePhone, validateEmail, validatePhone, validatePassword } from "../config/validation";
import { font, horizontalPadding, rs } from "../theme/responsive";
const AUTH_URL = `${API_URL}/auth`;
export default function CompanyRegister({ navigation }) {
  const [name, setName] = useState(""); const [email, setEmail] = useState(""); const [phone, setPhone] = useState(""); const [password, setPassword] = useState(""); const [loading, setLoading] = useState(false);
  const handleRegister = async () => {
    const normalizedName = name.trim(), normalizedEmail = email.trim().toLowerCase(), normalizedPhone = phone.trim();
    if (!normalizedName || !normalizedEmail || !normalizedPhone || !password) { Alert.alert("Datos incompletos", "Completa empresa, email, teléfono y contraseña."); return; }
    if (normalizedName.length < 2 || normalizedName.length > 150 || !/[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]/.test(normalizedName)) { Alert.alert("Empresa no válida", "Ingresa un nombre de empresa válido."); return; }
    if (!validateEmail(normalizedEmail)) { Alert.alert("Correo no válido", "Ingresa un correo electrónico válido."); return; }
    if (!validatePhone(normalizedPhone)) { Alert.alert("Teléfono no válido", "El teléfono debe contener solo números (7 a 15 dígitos)."); return; }
    if (!validatePassword(password)) { Alert.alert("Contraseña no válida", "Debe tener 8 a 128 caracteres, una mayúscula, una minúscula, un número y un carácter especial."); return; }
    setLoading(true);
    try { const response = await fetch(`${AUTH_URL}/register`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name: normalizedName, email: normalizedEmail, phone: normalizedPhone, password, role: "company" }) }); const data = await response.json(); if (!response.ok) throw new Error(data.message || "No se pudo completar el registro"); setSessionToken(data.token); Alert.alert("Registro exitoso", "Tu empresa fue registrada correctamente.", [{ text: "Continuar", onPress: () => navigation.replace("CompanyDashboard", { userId: data.user.id, token: data.token }) }]); }
    catch (error) { Alert.alert("Error de registro", error.message || "No se pudo conectar con el servidor."); } finally { setLoading(false); }
  };
  return <KeyboardAvoidingView style={styles.screen} behavior={Platform.OS === "ios" ? "padding" : undefined}><View style={styles.container}>
    <Text style={styles.title} accessibilityRole="header">Registro de empresa</Text><Text style={styles.subtitle}>Crea una cuenta para publicar oportunidades inclusivas.</Text>
    <TextInput style={styles.input} placeholder="Nombre de la empresa" value={name} onChangeText={setName} maxLength={150} accessibilityLabel="Nombre de la empresa" />
    <TextInput style={styles.input} placeholder="Email corporativo" value={email} onChangeText={setEmail} keyboardType="email-address" autoCapitalize="none" autoCorrect={false} accessibilityLabel="Email corporativo" />
    <TextInput style={styles.input} placeholder="Teléfono (7 a 15 dígitos)" value={phone} onChangeText={(value) => setPhone(sanitizePhone(value))} keyboardType="phone-pad" accessibilityLabel="Teléfono" maxLength={15} />
    <TextInput style={styles.input} placeholder="Contraseña" value={password} onChangeText={setPassword} secureTextEntry accessibilityLabel="Contraseña" /><Text style={styles.passwordHint}>8–128 caracteres · mayúscula · minúscula · número · carácter especial</Text>
    <AccessibleButton title={loading ? "Registrando..." : "Crear cuenta de empresa"} onPress={handleRegister} disabled={loading} /><AccessibleButton title="Volver" type="secondary" onPress={() => navigation.goBack()} disabled={loading} />
  </View></KeyboardAvoidingView>;
}
const styles = StyleSheet.create({ screen: { flex: 1, backgroundColor: colors.white }, container: { flex: 1, justifyContent: "center", paddingHorizontal: horizontalPadding }, title: { fontSize: font(30), fontWeight: "800", color: colors.primary, textAlign: "center" }, subtitle: { fontSize: font(17), lineHeight: font(24), color: colors.text, textAlign: "center", marginTop: 10, marginBottom: rs(24, 18, 28) }, input: { minHeight: rs(52, 48, 56), borderWidth: 1, borderColor: colors.secondary, borderRadius: rs(10, 8, 12), paddingHorizontal: rs(16, 13, 18), fontSize: font(17), color: colors.text, marginBottom: rs(14, 11, 16), backgroundColor: colors.white }, passwordHint: { marginTop: -8, marginBottom: 10, color: colors.text, fontSize: font(13) } });
