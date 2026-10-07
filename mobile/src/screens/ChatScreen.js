import React, { useCallback, useState } from "react";
import { ActivityIndicator, Alert, KeyboardAvoidingView, Platform, Pressable, ScrollView, Text, TextInput, View, StyleSheet } from "react-native";
import { useFocusEffect } from "@react-navigation/native";
import { API_URL } from "../config/api";
import { authHeaders, getSessionUserId } from "../config/session";
import { colors } from "../theme/colors";
import AccessibleButton from "../components/AccessibleButton";

export default function ChatScreen({ route, navigation }) {
  const { applicationId } = route.params || {};
  const [messages, setMessages] = useState([]); const [companyName, setCompanyName] = useState("Empresa"); const [text, setText] = useState(""); const [loading, setLoading] = useState(true); const [sending, setSending] = useState(false); const currentUserId = getSessionUserId();
  const loadMessages = useCallback(async () => {
    if (!applicationId) return;
    setLoading(true);
    try { const response = await fetch(`${API_URL}/messages/${applicationId}`, { headers: authHeaders() }); const data = await response.json(); if (!response.ok) throw new Error(data.message || "No se pudo cargar el chat"); setMessages(data.messages || []); setCompanyName(data.companyName || "Empresa"); }
    catch (error) { Alert.alert("Chat", error.message || "No se pudo cargar la conversación."); }
    finally { setLoading(false); }
  }, [applicationId]);
  useFocusEffect(useCallback(() => { loadMessages(); }, [loadMessages]));
  const sendMessage = async () => { const value = text.trim(); if (!value || sending) return; setSending(true); try { const response = await fetch(`${API_URL}/messages/${applicationId}`, { method: "POST", headers: { ...authHeaders(), "Content-Type": "application/json" }, body: JSON.stringify({ text: value }) }); const data = await response.json(); if (!response.ok) throw new Error(data.message || "No se pudo enviar el mensaje"); setMessages((current) => [...current, data.message]); setText(""); } catch (error) { Alert.alert("No se pudo enviar", error.message || "Intenta nuevamente."); } finally { setSending(false); } };
  return <KeyboardAvoidingView style={styles.screen} behavior={Platform.OS === "ios" ? "padding" : undefined}>
    <View style={styles.header}><Pressable onPress={() => navigation.goBack()} accessibilityRole="button" accessibilityLabel="Volver"><Text style={styles.back}>‹</Text></Pressable><View style={styles.headerText}><Text style={styles.title}>Chat</Text><Text style={styles.company}>{companyName}</Text></View></View>
    <ScrollView contentContainerStyle={styles.messages} keyboardShouldPersistTaps="handled">
      {loading ? <ActivityIndicator color={colors.primary} style={{ marginTop: 24 }} /> : messages.length === 0 ? <Text style={styles.empty}>Aún no hay mensajes. Puedes iniciar la conversación.</Text> : messages.map((message) => { const mine = String(message.senderUserId) === String(currentUserId); return <View key={message._id || `${message.createdAt}-${message.text}`} style={[styles.bubble, mine ? styles.mine : styles.received]}><Text style={[styles.message, !mine && styles.receivedMessage]}>{message.text}</Text><Text style={[styles.time, !mine && styles.receivedTime]}>{message.createdAt ? new Date(message.createdAt).toLocaleString() : ""}</Text></View>; })}
    </ScrollView>
    <View style={styles.composer}><TextInput style={styles.input} value={text} onChangeText={setText} placeholder="Escribe un mensaje" maxLength={2000} multiline accessibilityLabel="Mensaje"/><View style={styles.send}><AccessibleButton title={sending ? "..." : "Enviar"} onPress={sendMessage} disabled={sending || !text.trim()} /></View></View>
  </KeyboardAvoidingView>;
}

const styles = StyleSheet.create({ screen: { flex: 1, backgroundColor: colors.background }, header: { flexDirection: "row", alignItems: "center", paddingHorizontal: 18, paddingTop: 16, paddingBottom: 12, backgroundColor: colors.white, borderBottomWidth: 1, borderBottomColor: "#E2E8F0" }, back: { fontSize: 38, color: colors.primary, width: 40 }, headerText: { flex: 1 }, title: { fontSize: 24, fontWeight: "800", color: colors.primary }, company: { marginTop: 2, color: "#64748B" }, messages: { flexGrow: 1, padding: 18, justifyContent: "flex-end" }, bubble: { maxWidth: "82%", borderRadius: 16, padding: 12, marginTop: 10 }, mine: { alignSelf: "flex-end", backgroundColor: colors.primary }, received: { alignSelf: "flex-start", backgroundColor: colors.white, borderWidth: 1, borderColor: "#E2E8F0" }, message: { color: colors.white, fontSize: 16, lineHeight: 22 }, receivedMessage: { color: colors.text }, time: { color: "#E2E8F0", fontSize: 10, marginTop: 4 }, receivedTime: { color: "#64748B" }, empty: { textAlign: "center", color: "#64748B", margin: 24 }, composer: { flexDirection: "row", alignItems: "flex-end", padding: 10, backgroundColor: colors.white, borderTopWidth: 1, borderTopColor: "#E2E8F0" }, input: { flex: 1, minHeight: 48, maxHeight: 110, borderWidth: 1, borderColor: "#CBD5E1", borderRadius: 14, paddingHorizontal: 13, paddingVertical: 10, fontSize: 16 }, send: { width: 95, marginLeft: 8 }
});
