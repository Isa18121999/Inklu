import React, { useEffect } from "react";
import { ActivityIndicator, Text, View } from "react-native";
import { setSessionToken } from "../config/session";
import { colors } from "../theme/colors";

export default function AuthCallbackScreen({ navigation, route }) {
  useEffect(() => {
    const token = route?.params?.token;
    const role = route?.params?.role;
    if (!token || !role) {
      navigation.replace("Login");
      return;
    }
    setSessionToken(token);
    navigation.replace(role === "candidate" ? "CandidateDashboard" : role === "company" ? "CompanyDashboard" : "Login");
  }, [navigation, route]);

  return <View style={{ flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.white, padding: 24 }}>
    <ActivityIndicator size="large" color={colors.primary} />
    <Text style={{ marginTop: 16, color: colors.text }}>Completando inicio de sesión con Google...</Text>
  </View>;
}
