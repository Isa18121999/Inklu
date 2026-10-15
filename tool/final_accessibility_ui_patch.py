from pathlib import Path

# Company publishing form: derive structured accessibility from the selected modality
# while retaining the free-text accessibility field for detailed adjustments.
p = Path('flutter_app/lib/main.dart')
s = p.read_text(encoding='utf-8')
old = "          'preferredSkills': preferredSkills.text.split(',').map((skill) => skill.trim()).where((skill) => skill.isNotEmpty).take(40).toList(),\n          'accessibilityDetails': accessibilityDetails.text.trim(),"
new = "          'preferredSkills': preferredSkills.text.split(',').map((skill) => skill.trim()).where((skill) => skill.isNotEmpty).take(40).toList(),\n          'accessibilityDetails': accessibilityDetails.text.trim(),\n          'accessibility': {\n            'remote': modality.toLowerCase().contains('remoto'),\n            'hybrid': modality.toLowerCase().contains('híbrido') || modality.toLowerCase().contains('hibrido'),\n            'notes': accessibilityDetails.text.trim(),\n          },"
if old in s: s=s.replace(old,new,1)
p.write_text(s,encoding='utf-8')

# Include verification metadata in job/recommendation responses so the UI can show a badge.
p = Path('backend/server.js')
s = p.read_text(encoding='utf-8')
s = s.replace("populate('companyId', 'name companyProfile')", "populate('companyId', 'name companyProfile companyVerification')")
p.write_text(s,encoding='utf-8')
