# Hodný pes — interaktivní zážitek

Jednostránková responzivní česká aplikace pro Hodný pes (hodnypes.cz), publikovaná přes Cloudflare Pages.

## Funkce
- Interaktivní simulátor tří běžných situací při venčení s vysvětlující zpětnou vazbou.
- Generátor personalizované psí kartičky s exportem PNG a možností sdílení.
- Krátký kvíz s orientačním doporučením tréninku a pomůcky.
- Google OAuth přihlášení přes Supabase Auth; zobrazení profilu přihlášeného uživatele a odhlášení.
- Responzivní rozvržení, přístupné ovládání a podpora omezení pohybu.
- Statické HTML/CSS/JavaScript v `index.html`, bez build kroku.

## Google OAuth — nutné dokončení konfigurace

Kód přihlášení je připravený, ale Google provider se nedá bezpečně aktivovat jen z veřejného front-endu. Je potřeba jednorázově nastavit OAuth přihlašovací údaje:

1. V [Google Cloud Console](https://console.cloud.google.com/) vytvoř OAuth 2.0 Client ID pro aplikaci typu **Web application** a nakonfiguruj consent screen.
2. V Supabase Dashboard projektu `hodnypes` otevři **Authentication → Sign In / Providers → Google**. Zapni Google a vlož Client ID a Client Secret z Google Cloud Console.
3. V nastavení Google OAuth přidej do **Authorized redirect URIs** přesnou callback URL z nastavení Supabase Authentication (obvykle `https://krgtpruozlhygziwlwbt.supabase.co/auth/v1/callback`).
4. V Supabase **Authentication → URL Configuration** nastav Site URL na produkční doménu `https://hodnypes.pages.dev` a přidej mezi Redirect URLs:
   - `https://hodnypes.pages.dev/**`
   - `https://*.hodnypes.pages.dev/**` (jen pokud chceš používat i náhledové deploymenty)
   - případně vlastní doménu, až bude k projektu skutečně připojena.
5. Ulož nastavení a otestuj přihlášení v anonymním okně prohlížeče.

**Nikdy nedávej Google Client Secret do `index.html`, GitHubu ani do veřejných proměnných.** Secret patří pouze do nastavení Supabase. Veřejný Supabase publishable key v klientském kódu je určený pro front-end; databázové tabulky a ukládání osobních údajů vyžadují samostatné RLS zásady.

## Ukládání a soukromí
- Google přihlášení pracuje přes Supabase Auth.
- V této verzi se profil uživatele zobrazuje v prohlížeči po přihlášení; **osobní herní pokrok se zatím do databáze neukládá**.
- Nahraná fotka pro kartičku zůstává v prohlížeči a není uploadována na server.
- K ukládání psího profilu, výsledků a misí do cloudu je potřeba navrhnout tabulky a bezpečné Row Level Security (RLS) politiky.

## Spuštění
Otevři `index.html` nebo publikuj repozitář jako statický web na Cloudflare Pages (produkční větev `main`, výstupní adresář `.`, bez build příkazu).

Odkazy na kurzy a e-shop zatím vedou na obecnou domovskou stránku https://hodnypes.cz/, protože konkrétní URL kurzů a produktů je třeba ověřit a doplnit.

## Poznámka
Kartička a její odznak jsou hravým marketingovým prvkem, nikoli skutečnou certifikací. Doporučení k tréninku jsou orientační a nenahrazují individuální posouzení kvalifikovaným trenérem.
