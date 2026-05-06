# Circuito Logisim en Web

## Ejecutar todo

```bash
python3 main.py
```

Abrir en navegador:

- http://localhost:8000

## Qué archivos debes conservar

- `CIRCUITOS_LOGISIM.md`
- `index.html`
- `main.py`
- `styles.css`

## Si GitHub muestra conflictos al hacer merge

Resuélvelos en este orden para que quede limpio:

1. En `CIRCUITOS_LOGISIM.md`, conserva la versión más reciente (guía final limpia).
2. En `index.html`, conserva la versión con SVG de bloques y fórmulas clave.
3. En `main.py`, conserva la versión que levanta `http://localhost:8000`.
4. Si `README.md` también entra en conflicto, deja esta versión.

Comandos típicos (local):

```bash
git checkout main
git pull
git checkout <tu-rama>
git merge main
# resolver archivos en conflicto

git add CIRCUITOS_LOGISIM.md index.html main.py README.md styles.css
git commit -m "Resolve merge conflicts"
```
