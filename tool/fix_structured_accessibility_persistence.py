from pathlib import Path
p=Path('backend/server.js')
s=p.read_text(encoding='utf-8')
old="const { title, description, category, modality, location, contractType, salary, requiredSkills, preferredSkills, experienceRequired, accessibilityDetails } = req.body || {};"
new="const { title, description, category, modality, location, contractType, salary, requiredSkills, preferredSkills, experienceRequired, accessibilityDetails, accessibility } = req.body || {};"
if old in s: s=s.replace(old,new,1)
old="      accessibilityDetails: String(accessibilityDetails || '').trim().slice(0, 1200),\n      experienceRequired: years"
new="      accessibilityDetails: String(accessibilityDetails || '').trim().slice(0, 1200),\n      accessibility: {\n        remote: accessibility?.remote === true, hybrid: accessibility?.hybrid === true, physicalAccess: accessibility?.physicalAccess === true,\n        flexibleSchedule: accessibility?.flexibleSchedule === true, workplaceAdaptation: accessibility?.workplaceAdaptation === true,\n        assistiveTechnology: accessibility?.assistiveTechnology === true, accessibleRestroom: accessibility?.accessibleRestroom === true,\n        elevator: accessibility?.elevator === true, accessibleParking: accessibility?.accessibleParking === true,\n        transportationSupport: accessibility?.transportationSupport === true, interpreter: accessibility?.interpreter === true,\n        notes: String(accessibility?.notes || '').trim().slice(0, 1200)\n      },\n      experienceRequired: years"
if old in s: s=s.replace(old,new,1)
old="    companyProfile: user.companyProfile,\n    profile: user.profile,"
new="    companyProfile: user.companyProfile,\n    companyVerification: user.companyVerification || { status: 'unverified', verifiedAt: null, verificationNote: '' },\n    profile: user.profile,"
if old in s: s=s.replace(old,new,1)
p.write_text(s,encoding='utf-8')
