import React, { useCallback, useState } from "react";
import { Alert, ScrollView, Text, TextInput, StyleSheet } from "react-native";
import { useFocusEffect } from "@react-navigation/native";
import AccessibleButton from "../components/AccessibleButton";
import { API_URL } from "../config/api";
import { authHeaders } from "../config/session";
import { colors } from "../theme/colors";

export default function CompanyProfileScreen() {
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [sector, setSector] = useState("");
  const [country, setCountry] = useState("PE");
  const [description, setDescription] = useState("");
  const [inclusionPolicy, setInclusionPolicy] = useState("");
  const [accessibilityOptions, setAccessibilityOptions] = useState("");
  const [loading, setLoading] = useState(false);

  const loadProfile = useCallback(async () => {
    try {
      const response = await fetch(`${API_URL}/profile/me`, { headers: authHeaders() });
      if (!response.ok) return;
      const profile = await response.json();
      setName(profile.name || ""); setPhone(profile.phone || ""); setSector(profile.sector || "");
      setCountry(profile.country || "PE"); setDescription(profile.description || "");
      setInclusionPolicy(profile.inclusionPolicy || ""); setAccessibilityOptions((profile.accessibilityOptions || []).join(", "));
    } catch (_error) {}
  }, []);

  useFocusEffect(useCallback(() => { loadProfile(); }, [loadProfile]));

  const saveProfile = async () => {
    const normalizedName = name.trim(); const normalizedPhone = phone.trim();
    if (normalizedName.length < 2 || normalizedName.length > 150) return Alert.alert("Nombre no válido", "Ingresa un nombre de empresa válido.");
    if (!/^\d{7,15}$/.test(normalizedPhone)) return Alert.alert("Teléfono no válido", "El teléfono debe contener solo números (7 a 15 dígitos).");
    const accessibilityList = accessibilityOptions.split(",").map((item) => item.trim()).filter(Boolean);
    if (accessibilityList.length > 30 || accessibilityList.some((item) => item.length > 100)) return Alert.alert("Accesibilidad no válida", "Puedes registrar hasta 30 opciones de máximo 100 caracteres.");
    setLoading(true);
    try {
      const response = await fetch(`${API_URL}/profile/me`, { method: "PATCH", headers: { ...authHeaders(), "Content-Type": "application/json" }, body: JSON.stringify({ name: normalizedName, phone: normalizedPhone, sector: sector.trim(), country: country.trim() || "PE", description: description.trim(), inclusionPolicy: inclusionPolicy.trim(), accessibilityOptions: accessibilityList }) });
      const data = await response.json();
      if (!response.ok) throw new Error(data.message || "No se pudo guardar el perfil");
      Alert.alert("Perfil actualizado", "La información de tu empresa se guardó correctamente.");
    } catch (error) { Alert.alert("Error", error.message || "No se pudo conectar con el servidor."); }
    finally { setLoading(false); }
  };

  return <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
    <Text style={styles.title} accessibilityRole="header">Perfil de empresa</Text>
    <Text style={styles.subtitle}>Completa la información para presentar tu empresa y sus condiciones de inclusión.</Text>
    <TextInput style={styles.input} placeholder="Nombre de la empresa" value={name} onChangeText={setName} maxLength={150} accessibilityLabel="Nombre de la empresa" />
    <TextInput style={styles.input} placeholder="Teléfono (7 a 15 dígitos)" value={phone} onChangeText={(value) => setPhone(value.replace(/\D/g, "").slice(0, 15))} keyboardType="phone-pad" maxLength={15} accessibilityLabel="Teléfono de la empresa" />
    <TextInput style={styles.input} placeholder="Sector o actividad" value={sector} onChangeText={setSector} maxLength={500} accessibilityLabel="Sector o actividad" />
    <TextInput style={styles.input} placeholder="País" value={country} onChangeText={setCountry} maxLength={10} accessibilityLabel="País" />
    <TextInput style={[styles.input, styles.multiline]} placeholder="Descripción de la empresa" value={description} onChangeText={setDescription} maxLength={500} multiline accessibilityLabel="Descripción de la empresa" />
    <TextInput style={[styles.input, styles.multiline]} placeholder="Política de inclusión" value={inclusionPolicy} onChangeText={setInclusionPolicy} maxLength={500} multiline accessibilityLabel="Política de inclusión" />
    <TextInput style={[styles.input, styles.multiline]} placeholder="Medidas de accesibilidad (separadas por comas)" value={accessibilityOptions} onChangeText={setAccessibilityOptions} maxLength={3000} multiline accessibilityLabel="Medidas de accesibilidad" />
    <AccessibleButton title={loading ? "Guardando..." : "Guardar perfil"} onPress={saveProfile} disabled={loading} />
  </ScrollView>;
}

const styles = StyleSheet.create({ container: { flexGrow: 1, padding: 24, backgroundColor: colors.white }, title: { fontSize: 28, fontWeight: "800", color: colors.primary, marginBottom: 10 }, subtitle: { fontSize: 16, lineHeight: 23, color: colors.text, marginBottom: 18 }, input: { borderWidth: 1, borderColor: "#CBD5E1", borderRadius: 12, padding: 14, marginBottom: 12, fontSize: 16, backgroundColor: colors.white }, multiline: { minHeight: 90, textAlignVertical: "top" }
});
