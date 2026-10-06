import React from "react";
import { ScrollView, Text, View, StyleSheet } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import CandidateBottomNav from "../components/CandidateBottomNav";
import { colors } from "../theme/colors";

export default function FavoritesScreen({ navigation }) {
  return (
    <View style={styles.screen}>
      <ScrollView contentContainerStyle={styles.container}>
        <Text style={styles.title} accessibilityRole="header">Mis favoritos</Text>
        <View style={styles.illustration} accessibilityLabel="No hay ofertas guardadas">
          <Text style={styles.heart}>♡</Text>
          <Text style={styles.illustrationText}>Guarda las ofertas que más te interesen</Text>
        </View>
        <View style={styles.emptyBox}>
          <Text style={styles.emptyTitle}>Todavía no tienes ofertas guardadas en Mis Favoritos</Text>
          <Text style={styles.emptyText}>Marca con el ❤️ las ofertas que desees guardar para revisarlas después.</Text>
        </View>
        <AccessibleButton title="Buscar empleos" onPress={() => navigation.navigate("Jobs")} />
      </ScrollView>
      <CandidateBottomNav navigation={navigation} active="favorites" />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  container: { flexGrow: 1, padding: 24, paddingBottom: 110, alignItems: "center", backgroundColor: colors.background },
  title: { alignSelf: "stretch", textAlign: "center", fontSize: 28, fontWeight: "500", color: colors.white, backgroundColor: colors.secondary, marginHorizontal: -24, marginTop: -24, paddingVertical: 22, marginBottom: 32 },
  illustration: { width: "90%", minHeight: 300, borderRadius: 28, backgroundColor: "#EAF2FF", alignItems: "center", justifyContent: "center", marginBottom: 28 },
  heart: { fontSize: 110, color: colors.primary, fontWeight: "300" },
  illustrationText: { fontSize: 18, fontWeight: "700", color: colors.secondary, textAlign: "center", paddingHorizontal: 30 },
  emptyBox: { alignItems: "center", marginBottom: 28 },
  emptyTitle: { fontSize: 24, lineHeight: 31, fontWeight: "800", color: colors.text, textAlign: "center", marginBottom: 18 },
  emptyText: { fontSize: 18, lineHeight: 27, color: colors.text, textAlign: "center", paddingHorizontal: 12 }
});
