from pathlib import Path
p = Path('backend/server.js')
s = p.read_text(encoding='utf-8')
old = "if (withAccessibility) {\n      filter.accessibilityDetails = { $exists: true, $ne: '' };\n    }"
new = "if (withAccessibility) {\n      filter.$or = [\n        { accessibilityDetails: { $exists: true, $ne: '' } },\n        { 'accessibility.remote': true },\n        { 'accessibility.hybrid': true },\n        { 'accessibility.physicalAccess': true },\n        { 'accessibility.flexibleSchedule': true },\n        { 'accessibility.workplaceAdaptation': true },\n        { 'accessibility.assistiveTechnology': true },\n        { 'accessibility.accessibleRestroom': true },\n        { 'accessibility.elevator': true },\n        { 'accessibility.accessibleParking': true },\n        { 'accessibility.transportationSupport': true },\n        { 'accessibility.interpreter': true },\n        { 'accessibility.notes': { $exists: true, $ne: '' } }\n      ];\n    }"
if old not in s:
    raise SystemExit('No se encontró el filtro de accesibilidad esperado.')
p.write_text(s.replace(old, new, 1), encoding='utf-8')
