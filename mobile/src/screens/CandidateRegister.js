import React, { useState } from "react";
import { Alert, Text, TextInput, StyleSheet, ScrollView } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { API_URL } from "../config/api";
import { colors } from "../theme/colors";
import { setSessionToken } from "../config/session";
import { sanitizeName, sanitizePhone, validateName, validateEmail, validatePhone, validatePassword } from "../config/validation";

const AUTH_URL = `${API_URL}/auth`;

export default function CandidateRegister({ navigation }) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [conadisNumber, setConadisNumber] = useState("");
  const [disabilityType, setDisabilityType] = useState("");
  const [loading, setLoading] = useState(false);

  const submitRegistration = async () => {
    const n = name.trim(); const e = email.trim().toLowerCase(); const p = phone.trim(); const rui = conadisNumber.trim(); const disability = disabilityType.trim();
    if (!n || !e || !p || !password || !rui || !disability) { Alert.alert("Datos incompletos", "Completa todos los campos obligatorios."); return; }
    if (!/^\d{6}$/.test(rui)) { Alert.alert("RUI no válido", "Ingresa exactamente 6 dígitos del RUI de tu carné CONADIS."); return; }
    if (!validateName(n)) { Alert.alert("Nombre no válido", "Revisa el nombre."); return; }
    if (!validateEmail(e)) { Alert.alert("Correo no válido", "Ingresa un correo válido."); return; }
    if (!validatePhone(p)) { Alert.alert("Teléfono no válido", "Usa entre 7 y 15 dígitos."); return; }
    if (!validatePassword(password)) { Alert.alert("Contraseña no válida", "Debe cumplir los requisitos indicados."); return; }
    setLoading(true);
    try {
      const response = await fetch(`${AUTH_URL}/register`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name: n, email: e, phone: p, password, role: "candidate", country: "PE", accreditationType: "Carné CONADIS", accreditationNumber: rui, disabilityType: disability }) });
      const data = await response.json(); if (!response.ok) throw new Error(data.message || "No se pudo completar el registro");
      setSessionToken(data.token);
      Alert.alert("Registro correcto", "Tu cuenta y perfil de candidato fueron creados.", [{ text: "Continuar", onPress: () => navigation.replace("CandidateDashboard", { userId: data.user.id, token: data.token }) }]);
    } catch (error) { Alert.alert("Error de registro", error.message || "No se pudo conectar con el servidor."); } finally { setLoading(false); }
  };

  return <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
    <Text style={styles.title} accessibilityRole="header">Registro de candidato</Text>
    <Text style={styles.subtitle}>Inklu funciona actualmente en Perú. Para registrarte como candidato debes contar con carné CONADIS.</Text>
    <TextInput style={styles.input} placeholder="Nombre completo" value={name} onChangeText={(v) => setName(sanitizeName(v))} autoCapitalize="words" />
    <TextInput style={styles.input} placeholder="Correo electrónico" value={email} onChangeText={setEmail} keyboardType="email-address" autoCapitalize="none" autoCorrect={false} />
    <TextInput style={styles.input} placeholder="Teléfono (7 a 15 dígitos)" value={phone} onChangeText={(v) => setPhone(sanitizePhone(v))} keyboardType="phone-pad" maxLength={15} />
    <TextInput style={styles.input} placeholder="Contraseña" value={password} onChangeText={setPassword} secureTextEntry />
    <Text style={styles.passwordHint}>8–128 caracteres · mayúscula · minúscula · número · carácter especial</Text>
    <Text style={styles.label}>Número del carné CONADIS</Text>
    <TextInput style={styles.input} placeholder="RUI (6 dígitos)" value={conadisNumber} onChangeText={(v) => setConadisNumber(v.replace(/\D/g, "").slice(0, 6))} keyboardType="number-pad" maxLength={6} />
    <Text style={styles.label}>Tipo de discapacidad</Text>
    <TextInput style={styles.input} placeholder="Ej.: física, visual, auditiva..." value={disabilityType} onChangeText={setDisabilityType} />
    <AccessibleButton title={loading ? "Registrando..." : "Crear cuenta"} onPress={submitRegistration} disabled={loading} />
    <AccessibleButton title="Ya tengo una cuenta" type="secondary" onPress={() => navigation.navigate("Login")} disabled={loading} />
  </ScrollView>;
}

const styles = StyleSheet.create({ container: { flexGrow: 1, padding: 24, backgroundColor: colors.white }, title: { fontSize: 28, fontWeight: "800", color: colors.primary, marginBottom: 10 }, subtitle: { fontSize: 16, lineHeight: 23, color: colors.text, marginBottom: 18 }, label: { marginTop: 8, marginBottom: 8, fontWeight: "700", color: colors.text, fontSize: 16 }, input: { borderWidth: 1, borderColor: "#CBD5E1", borderRadius: 12, padding: 14, marginBottom: 12, fontSize: 16, backgroundColor: colors.white }, passwordHint: { marginTop: -6, marginBottom: 8, color: colors.text, fontSize: 13 } });
