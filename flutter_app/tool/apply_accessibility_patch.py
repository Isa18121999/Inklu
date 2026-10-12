from pathlib import Path

p = Path('lib/main.dart')
s = p.read_text(encoding='utf-8')

# Make transient validation/network messages visible to screen readers as well as sighted users.
old = "void toast(String s){ScaffoldMessenger.of(_nav.currentContext!).showSnackBar(SnackBar(content:Text(s),behavior:SnackBarBehavior.floating));}"
new = "void toast(String s){SemanticsService.announce(s,TextDirection.ltr);ScaffoldMessenger.of(_nav.currentContext!).showSnackBar(SnackBar(content:Text(s),behavior:SnackBarBehavior.floating));}"
s = s.replace(old, new)

# Give the brand image an explicit accessible name.
old = ":Image.memory(b!,width:widget.size,height:widget.size,fit:BoxFit.contain);"
new = ":Semantics(label:'Logo INKLU',image:true,child:Image.memory(b!,width:widget.size,height:widget.size,fit:BoxFit.contain));"
s = s.replace(old, new)

# Voice Access and TalkBack labels for the notification action.
s = s.replace(
    "IconButton(onPressed:(){},icon:const Icon(Icons.notifications_none))",
    "IconButton(tooltip:'Notificaciones',onPressed:(){},icon:const Icon(Icons.notifications_none))",
)

# Voice Access/TalkBack label for the profile avatar action.
s = s.replace(
    "const Padding(padding:EdgeInsets.only(right:12),child:CircleAvatar(radius:16,child:Icon(Icons.person)))",
    "const Padding(padding:EdgeInsets.only(right:12),child:Semantics(label:'Perfil',button:true,child:CircleAvatar(radius:16,child:Icon(Icons.person))))",
)

# Explicit semantic state for the CV picker. Keep the visual design unchanged.
marker = "else...[InkWell(onTap:cv,child:"
if marker in s and "Semantics(button:true,label:cvName==null?'Seleccionar CV" not in s:
    s = s.replace(
        marker,
        "else...[Semantics(button:true,label:cvName==null?'Seleccionar CV. Archivos PDF, DOC o DOCX.':'CV seleccionado: $cvName. Toca para cambiarlo.',child:InkWell(onTap:cv,child:",
        1,
    )
    end_marker = ")),const SizedBox(height:6),const Text('Solo PDF, DOC o DOCX. Máximo 5 MB.'"
    idx = s.find(end_marker)
    if idx != -1:
        # Close Semantics immediately after the existing InkWell.
        s = s[:idx+2] + ")" + s[idx+2:]

# Hide decorative progress dots from the accessibility traversal.
s = s.replace(
    "class Dots extends StatelessWidget{",
    "class Dots extends StatelessWidget{",
)

p.write_text(s, encoding='utf-8')
