import React, { useState } from "react";
import { Alert, View, Text, TextInput, StyleSheet, ScrollView, Pressable } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { API_URL } from "../config/api";
import { colors } from "../theme/colors";
import { setSessionToken } from "../config/session";
import { sanitizeName, sanitizePhone, validateName, validateEmail, validatePhone, validatePassword } from "../config/validation";

const AUTH_URL = `${API_URL}/auth`;
const SUPPORT_OPTIONS = ["Entrenamiento en braille", "Entrenamiento con bastón", "Compañía", "Capacidades diarias (cocinar, limpiar, etc)", "Otras"];

export default function CandidateRegister({ navigation }) {
  const [name, setName] = useState(""); const [email, setEmail] = useState(""); const [phone, setPhone] = useState(""); const [password, setPassword] = useState("");
  const [candidateType, setCandidateType] = useState(""); const [conadisNumber, setConadisNumber] = useState(""); const [disabilityType, setDisabilityType] = useState(""); const [supportSelection, setSupportSelection] = useState([]); const [loading, setLoading] = useState(false);

  const handleConadisNumber = (value) => setConadisNumber(value.replace(/\D/g, "").slice(0, 6));
  const toggleSupport = (item) => setSupportSelection((current) => current.includes(item) ? current.filter((value) => value !== item) : [...current, item]);

  const submitRegistration = async () => {
    const normalizedName = name.trim(); const normalizedEmail = email.trim().toLowerCase(); const normalizedPhone = phone.trim(); const normalizedConadis = conadisNumber.trim();
    if (!normalizedName || !normalizedEmail || !normalizedPhone || !password || !candidateType) { Alert.alert("Datos incompletos", "Completa los datos y selecciona cómo quieres usar Inklu."); return; }
    if (candidateType === "CONADIS" && (!/^\d{6}$/.test(normalizedConadis) || !disabilityType.trim() || !supportSelection.length)) { Alert.alert("Datos CONADIS incompletos", "Ingresa tu RUI, tipo de discapacidad y al menos una ayuda que requieres."); return; }
    if (candidateType === "Voluntario" && !supportSelection.length) { Alert.alert("Datos incompletos", "Selecciona al menos una ayuda que puedes brindar."); return; }
    if (!validateName(normalizedName)) { Alert.alert("Nombre no válido", "El nombre solo puede contener letras, espacios, guiones y apóstrofes."); return; }
    if (!validateEmail(normalizedEmail)) { Alert.alert("Correo no válido", "Ingresa un correo electrónico válido."); return; }
    if (!validatePhone(normalizedPhone)) { Alert.alert("Teléfono no válido", "El teléfono debe contener solo números (7 a 15 dígitos)."); return; }
    if (!validatePassword(password)) { Alert.alert("Contraseña no válida", "Debe tener 8 a 128 caracteres, una mayúscula, una minúscula, un número y un carácter especial."); return; }
    setLoading(true);
    try {
      const response = await fetch(`${AUTH_URL}/register`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name: normalizedName, email: normalizedEmail, phone: normalizedPhone, password, role: "candidate", country: "PE", candidateType, accreditationType: candidateType === "CONADIS" ? "Carné CONADIS" : undefined, accreditationNumber: candidateType === "CONADIS" ? normalizedConadis : undefined, disabilityType: candidateType === "CONADIS" ? disabilityType.trim() : undefined, supportNeeds: candidateType === "CONADIS" ? supportSelection : [], supportOfferings: candidateType === "Voluntario" ? supportSelection : [] }) });
      const data = await response.json(); if (!response.ok) throw new Error(data.message || "No se pudo completar el registro"); setSessionToken(data.token);
      Alert.alert("Registro correcto", "Tu cuenta y perfil de candidato fueron creados.", [{ text: "Continuar", onPress: () => navigation.replace("CandidateDashboard", { userId: data.user.id, token: data.token }) }]);
    } catch (error) { Alert.alert("Error de registro", error.message || "No se pudo conectar con el servidor."); } finally { setLoading(false); }
  };

  return <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
    <Text style={styles.title} accessibilityRole="header">Registro de candidato</Text>
    <Text style={styles.subtitle}>Inklu funciona actualmente en Perú. Completa tus datos y elige si eres una persona con CONADIS o voluntario/a.</Text>
    <TextInput style={styles.input} placeholder="Nombre completo" value={name} onChangeText={(value) => setName(sanitizeName(value))} autoCapitalize="words" accessibilityLabel="Nombre completo" />
    <TextInput style={styles.input} placeholder="Correo electrónico" value={email} onChangeText={setEmail} keyboardType="email-address" autoCapitalize="none" autoCorrect={false} accessibilityLabel="Correo electrónico" />
    <TextInput style={styles.input} placeholder="Teléfono (7 a 15 dígitos)" value={phone} onChangeText={(value) => setPhone(sanitizePhone(value))} keyboardType="phone-pad" accessibilityLabel="Teléfono" maxLength={15} />
    <TextInput style={styles.input} placeholder="Contraseña" value={password} onChangeText={setPassword} secureTextEntry accessibilityLabel="Contraseña" />
    <Text style={styles.passwordHint}>8–128 caracteres · mayúscula · minúscula · número · carácter especial</Text>

    <Text style={styles.label}>¿Cómo usarás Inklu?</Text>
    <View style={styles.choiceRow}>
      {["CONADIS", "Voluntario"].map((type) => <Pressable key={type} onPress={() => { setCandidateType(type); setSupportSelection([]); }} style={[styles.choice, candidateType === type && styles.choiceSelected]} accessibilityRole="radio" accessibilityState={{ selected: candidateType === type }}><Text style={[styles.choiceText, candidateType === type && styles.choiceTextSelected]}>{type === "CONADIS" ? "Tengo carné CONADIS" : "Soy voluntario/a"}</Text></Pressable>)}
    </View>

    {candidateType === "CONADIS" && <>
      <Text style={styles.label}>Número del carné CONADIS</Text>
      <TextInput style={styles.input} placeholder="RUI (6 dígitos)" value={conadisNumber} onChangeText={handleConadisNumber} keyboardType="number-pad" maxLength={6} accessibilityLabel="Número del carné CONADIS" />
      <Text style={styles.label}>Tipo de discapacidad</Text>
      <TextInput style={styles.input} placeholder="Ej.: física, visual, auditiva..." value={disabilityType} onChangeText={setDisabilityType} accessibilityLabel="Tipo de discapacidad" />
      <Text style={styles.label}>¿Qué ayuda requieres?</Text>
    </>}
    {candidateType === "Voluntario" && <Text style={styles.label}>¿Qué ayuda puedes brindar?</Text>}
    {!!candidateType && <View style={styles.options}>{SUPPORT_OPTIONS.map((item) => <Pressable key={item} onPress={() => toggleSupport(item)} style={[styles.option, supportSelection.includes(item) && styles.optionSelected]} accessibilityRole="checkbox" accessibilityState={{ checked: supportSelection.includes(item) }}><Text style={[styles.optionText, supportSelection.includes(item) && styles.optionTextSelected]}>{supportSelection.includes(item) ? "✓ " : "□ "}{item}</Text></Pressable>)}</View>}

    <AccessibleButton title={loading ? "Registrando..." : "Crear cuenta"} onPress={submitRegistration} disabled={loading} />
    <AccessibleButton title="Ya tengo una cuenta" type="secondary" onPress={() => navigation.navigate("Login")} disabled={loading} />
  </ScrollView>;
}

const styles = StyleSheet.create({ container: { flexGrow: 1, padding: 24, backgroundColor: colors.white }, title: { fontSize: 28, fontWeight: "800", color: colors.primary, marginBottom: 10 }, subtitle: { fontSize: 16, lineHeight: 23, color: colors.text, marginBottom: 18 }, label: { marginTop: 8, marginBottom: 8, fontWeight: "700", color: colors.text, fontSize: 16 }, input: { borderWidth: 1, borderColor: "#CBD5E1", borderRadius: 12, padding: 14, marginBottom: 12, fontSize: 16, backgroundColor: colors.white }, passwordHint: { marginTop: -6, marginBottom: 8, color: colors.text, fontSize: 13 }, choiceRow: { flexDirection: "row", gap: 10, marginBottom: 10 }, choice: { flex: 1, minHeight: 58, borderWidth: 1, borderColor: "#CBD5E1", borderRadius: 14, padding: 12, alignItems: "center", justifyContent: "center", backgroundColor: colors.white }, choiceSelected: { backgroundColor: "#EDE9FE", borderColor: colors.primary, borderWidth: 2 }, choiceText: { textAlign: "center", fontWeight: "700", color: colors.text }, choiceTextSelected: { color: colors.primary }, options: { marginBottom: 8 }, option: { borderWidth: 1, borderColor: "#CBD5E1", borderRadius: 12, padding: 12, marginBottom: 8, backgroundColor: colors.white }, optionSelected: { backgroundColor: "#EDE9FE", borderColor: colors.primary }, optionText: { color: colors.text, fontSize: 15 }, optionTextSelected: { color: colors.primary, fontWeight: "700" }
});
