import React from "react";
import { Pressable, ScrollView, Text, View, StyleSheet } from "react-native";
import AccessibleButton from "../components/AccessibleButton";
import { colors } from "../theme/colors";

function DemoBottomBar({ navigation, active = "search" }) {
  const items = [
    { key: "search", label: "Buscar", icon: "⌕", route: "DemoJobs" },
    { key: "applications", label: "Postulaciones", icon: "➤", route: "DemoApplications" },
    { key: "favorites", label: "Favoritos", icon: "♡", route: "DemoFavorites" },
    { key: "alerts", label: "Alertas", icon: "♧", route: "DemoNotifications" },
    { key: "menu", label: "Menú", icon: "☰", route: "DemoProfile" }
  ];
  return <View style={styles.bottomBar} accessibilityRole="tablist">
    {items.map((item) => {
      const selected = active === item.key;
      return <Pressable key={item.key} style={styles.tab} onPress={() => navigation.navigate(item.route)} accessibilityRole="tab" accessibilityState={{ selected }} accessibilityLabel={item.label}>
        <View style={[styles.iconCircle, selected && styles.iconCircleActive]}><Text style={[styles.icon, selected && styles.iconActive]}>{item.icon}</Text></View>
        <Text style={[styles.tabLabel, selected && styles.tabLabelActive]}>{item.label}</Text>
      </Pressable>;
    })}
  </View>;
}

function DemoLayout({ children, navigation, active }) {
  return <View style={styles.screen}>{children}<DemoBottomBar navigation={navigation} active={active} /></View>;
}

const jobs = [
  { id: "demo-1", title: "Asistente administrativo", company: "Empresa Inclusiva Perú", score: 92, modality: "Híbrido" },
  { id: "demo-2", title: "Atención al cliente", company: "Servicios Andinos", score: 84, modality: "Remoto" },
  { id: "demo-3", title: "Auxiliar de oficina", company: "Grupo Lima", score: 76, modality: "Presencial" }
];

export default function DemoScreen({ navigation }) {
  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title} accessibilityRole="header">Demo de Inklu</Text>
      <Text style={styles.subtitle}>Modo demostración: puedes recorrer las pantallas sin conectar todavía el backend.</Text>

      <View style={styles.card}>
        <Text style={styles.greeting}>Hola, Isabella</Text>
        <Text style={styles.status}>🟢 Acreditación registrada</Text>
        <Text style={styles.sectionTitle}>Tus mejores coincidencias</Text>
        {jobs.map((job) => (
          <View key={job.id} style={styles.jobRow}>
            <View style={styles.jobInfo}>
              <Text style={styles.jobTitle}>{job.title}</Text>
              <Text>{job.company}</Text>
              <Text style={styles.modality}>{job.modality}</Text>
            </View>
            <Text style={styles.score}>{job.score}%</Text>
          </View>
        ))}
      </View>

      <AccessibleButton title="🔎 Ver empleos" onPress={() => navigation.navigate("DemoJobs")} />
      <AccessibleButton title="👤 Ver mi perfil" type="secondary" onPress={() => navigation.navigate("DemoProfile")} />
      <AccessibleButton title="📄 Ver postulaciones" type="secondary" onPress={() => navigation.navigate("DemoApplications")} />
      <AccessibleButton title="🔔 Ver notificaciones" type="secondary" onPress={() => navigation.navigate("DemoNotifications")} />
      <AccessibleButton title="← Volver" type="secondary" onPress={() => navigation.replace("Access")} />
    </ScrollView>
  );
}

export function DemoJobsScreen({ navigation }) {
  return <ScrollView contentContainerStyle={styles.container}>
    <Text style={styles.title}>Empleos</Text>
    <Text style={styles.subtitle}>Ofertas de ejemplo para visualizar el flujo.</Text>
    {jobs.map((job) => <View key={job.id} style={styles.card}>
      <Text style={styles.jobTitle}>{job.title}</Text>
      <Text>{job.company}</Text>
      <Text style={styles.modality}>Modalidad: {job.modality}</Text>
      <Text style={styles.scoreSmall}>Match integral: {job.score}%</Text>
      <AccessibleButton title="Ver oferta" onPress={() => navigation.navigate("DemoJobDetail", { job })} />
    </View>)}
    <AccessibleButton title="← Volver" type="secondary" onPress={() => navigation.goBack()} />
  </ScrollView>;
}

export function DemoJobDetailScreen({ route, navigation }) {
  const job = route.params?.job || jobs[0];
  return <ScrollView contentContainerStyle={styles.container}>
    <Text style={styles.title}>{job.title}</Text>
    <Text style={styles.company}>{job.company}</Text>
    <View style={styles.card}>
      <Text style={styles.score}>{job.score}%</Text>
      <Text style={styles.sectionTitle}>Match integral</Text>
      <Text>• Habilidades: 100%</Text><Text>• Experiencia: 90%</Text><Text>• Educación: 100%</Text><Text>• Modalidad: 100%</Text><Text>• Accesibilidad: 80%</Text>
    </View>
    <Text style={styles.sectionTitle}>Información de la oferta</Text>
    <Text style={styles.body}>Área: Administración</Text>
    <Text style={styles.body}>Modalidad: {job.modality}</Text>
    <Text style={styles.body}>Experiencia mínima: 1 año</Text>
    <Text style={styles.sectionTitle}>Requisitos</Text>
    <Text style={styles.body}>Atención al cliente · Organización · Comunicación</Text>
    <Text style={styles.sectionTitle}>♿ Accesibilidad</Text>
    <Text style={styles.body}>Horario flexible · Entorno accesible</Text>
    <AccessibleButton title="📌 Postular (demo)" onPress={() => navigation.navigate("DemoApplications")} />
    <AccessibleButton title="← Volver" type="secondary" onPress={() => navigation.goBack()} />
  </ScrollView>;
}

export function DemoProfileScreen({ navigation }) {
  return <ScrollView contentContainerStyle={styles.container}>
    <Text style={styles.title}>Mi perfil</Text>
    <View style={styles.card}>
      <Text style={styles.label}>Nombre</Text><Text style={styles.body}>Isabella Montoya</Text>
      <Text style={styles.label}>Título profesional</Text><Text style={styles.body}>Asistente administrativa</Text>
      <Text style={styles.label}>Experiencia</Text><Text style={styles.body}>2 años</Text>
      <Text style={styles.label}>Habilidades</Text><Text style={styles.body}>Atención al cliente · Organización · Comunicación</Text>
      <Text style={styles.label}>Educación</Text><Text style={styles.body}>Técnico</Text>
      <Text style={styles.label}>Modalidad</Text><Text style={styles.body}>Híbrido</Text>
      <Text style={styles.label}>Accesibilidad</Text><Text style={styles.body}>Horario flexible</Text>
      <Text style={styles.label}>CV</Text><Text style={styles.body}>CV_Isabella.pdf</Text>
    </View>
    <AccessibleButton title="← Volver" type="secondary" onPress={() => navigation.goBack()} />
  </ScrollView>;
}

export function DemoApplicationsScreen({ navigation }) {
  return <ScrollView contentContainerStyle={styles.container}>
    <Text style={styles.title}>Mis postulaciones</Text>
    <View style={styles.card}><Text style={styles.jobTitle}>Asistente administrativo</Text><Text>Empresa Inclusiva Perú</Text><Text style={styles.scoreSmall}>Match: 92%</Text><Text style={styles.status}>Estado: CV visto</Text></View>
    <View style={styles.card}><Text style={styles.jobTitle}>Atención al cliente</Text><Text>Servicios Andinos</Text><Text style={styles.scoreSmall}>Match: 84%</Text><Text style={styles.status}>Estado: Postulado</Text></View>
    <AccessibleButton title="← Volver" type="secondary" onPress={() => navigation.goBack()} />
  </ScrollView>;
}

export function DemoNotificationsScreen({ navigation }) {
  return <ScrollView contentContainerStyle={styles.container}>
    <Text style={styles.title}>Notificaciones</Text>
    <View style={styles.card}><Text style={styles.jobTitle}>Tu CV fue visto</Text><Text>Empresa Inclusiva Perú revisó tu postulación.</Text></View>
    <View style={styles.card}><Text style={styles.jobTitle}>Nueva coincidencia</Text><Text>Encontramos una oferta con 84% de match.</Text></View>
    <AccessibleButton title="← Volver" type="secondary" onPress={() => navigation.goBack()} />
  </ScrollView>;
}

const styles = StyleSheet.create({
  screen:{flex:1,backgroundColor:colors.white},\n  container:{flexGrow:1,padding:24,paddingBottom:120,backgroundColor:colors.white},
  title:{fontSize:30,fontWeight:"800",color:colors.primary,marginBottom:10},
  subtitle:{fontSize:16,lineHeight:23,color:colors.text,marginBottom:20},
  card:{padding:18,borderRadius:16,backgroundColor:colors.background,marginBottom:16},
  greeting:{fontSize:22,fontWeight:"800",color:colors.text},
  status:{marginTop:8,color:colors.success,fontWeight:"700"},
  sectionTitle:{fontSize:18,fontWeight:"800",color:colors.secondary,marginTop:18,marginBottom:8},
  jobRow:{flexDirection:"row",justifyContent:"space-between",paddingVertical:14,borderTopWidth:1,borderTopColor:"#CBD5E1"},
  jobInfo:{flex:1,paddingRight:10},
  jobTitle:{fontSize:17,fontWeight:"700",color:colors.text},
  company:{fontSize:17,color:colors.text,marginBottom:14},
  modality:{marginTop:5,color:colors.text},
  score:{fontSize:30,fontWeight:"800",color:colors.secondary},
  scoreSmall:{fontSize:16,fontWeight:"800",color:colors.secondary,marginTop:8},
  label:{fontWeight:"800",color:colors.primary,marginTop:12},
  body:{fontSize:16,lineHeight:24,color:colors.text}
});
