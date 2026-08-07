CORRECCIÓN v0.7.2 DEL PDF
=========================

Se corrigieron dos problemas del preámbulo LaTeX:

1. Se activaron las bibliotecas skins y breakable de tcolorbox.
   Esto corrige el error:
   Package pgfkeys Error: I do not know the key '/tcb/enhanced jigsaw'.

2. Se sustituyeron las fuentes DejaVu por TeX Gyre Pagella, Heros y Cursor.
   Estas fuentes normalmente están incluidas en TeX Live/TinyTeX y evitan
   depender de fuentes instaladas en Windows.

Para probar:
  render_pdf_editorial.bat

Si TinyTeX actualizó paquetes en el intento anterior, cierre la ventana de
comandos y vuelva a ejecutar el archivo BAT en una ventana nueva.
