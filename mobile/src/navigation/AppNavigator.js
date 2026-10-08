import React from "react";
import { NavigationContainer } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";

import WelcomeScreen from "../screens/WelcomeScreen";
import AccessScreen from "../screens/AccessScreen";
import LoginScreen from "../screens/LoginScreen";
import CreateAccountScreen from "../screens/CreateAccountScreen";
import CandidateRegister from "../screens/CandidateRegister";
import CompanyRegister from "../screens/CompanyRegister";
import CandidateDashboard from "../screens/CandidateDashboard";
import CandidateProfileScreen from "../screens/CandidateProfileScreen";
import CompanyProfileScreen from "../screens/CompanyProfileScreen";
import ChatScreen from "../screens/ChatScreen";
import MessagesScreen from "../screens/MessagesScreen";
import CVUpload from "../screens/CVUpload";
import JobsScreen from "../screens/JobsScreen";
import JobDetailScreen from "../screens/JobDetailScreen";
import CompanyDashboardScreen from "../screens/CompanyDashboardScreen";
import CreateJobScreen from "../screens/CreateJobScreen";
import CandidateCVScreen from "../screens/CandidateCVScreen";
import ApplicationsScreen from "../screens/ApplicationsScreen";
import NotificationsScreen from "../screens/NotificationsScreen";
import FavoritesScreen from "../screens/FavoritesScreen";
import MenuAreaScreen from "../screens/MenuAreaScreen";

const Stack = createNativeStackNavigator();

export default function AppNavigator({ initialRouteName = "Welcome" }) {
  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName={initialRouteName} screenOptions={{ headerShown: false }}>
        <Stack.Screen name="Welcome" component={WelcomeScreen} />
        <Stack.Screen name="Access" component={AccessScreen} />
        <Stack.Screen name="Login" component={LoginScreen} />
        <Stack.Screen name="CreateAccount" component={CreateAccountScreen} />
        <Stack.Screen name="CandidateRegister" component={CandidateRegister} />
        <Stack.Screen name="CompanyRegister" component={CompanyRegister} />
        <Stack.Screen name="CandidateDashboard" component={CandidateDashboard} />
        <Stack.Screen name="CandidateProfile" component={CandidateProfileScreen} />
        <Stack.Screen name="CompanyProfile" component={CompanyProfileScreen} />
        <Stack.Screen name="Chat" component={ChatScreen} />
        <Stack.Screen name="Messages" component={MessagesScreen} />
        <Stack.Screen name="CV" component={CVUpload} />
        <Stack.Screen name="Jobs" component={JobsScreen} />
        <Stack.Screen name="JobDetail" component={JobDetailScreen} />
        <Stack.Screen name="CompanyDashboard" component={CompanyDashboardScreen} />
        <Stack.Screen name="CreateJob" component={CreateJobScreen} />
        <Stack.Screen name="CandidateCV" component={CandidateCVScreen} />
        <Stack.Screen name="Applications" component={ApplicationsScreen} />
        <Stack.Screen name="Notifications" component={NotificationsScreen} />
        <Stack.Screen name="Favorites" component={FavoritesScreen} />
        <Stack.Screen name="MenuArea" component={MenuAreaScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
