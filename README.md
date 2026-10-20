# Hodný pes — osobní psí dashboard

Responzivní česká aplikace pro Hodný pes (hodnypes.cz), publikovaná přes Cloudflare Pages.

## Co aplikace obsahuje
- Dashboard s body pohody, úrovní, aktivitami a denními misemi.
- Interaktivní simulátor tří situací při venčení s vysvětlující zpětnou vazbou.
- Profil psa a generátor psí kartičky s exportem PNG a sdílením.
- Kvíz s orientačními doporučeními pro trénink a výbavu.
- Krátké tréninkové lekce, sbírku odznaků a odkazy na kurzy/e-shop.
- Komunitní příspěvky; číst je lze veřejně, zveřejňovat může přihlášený uživatel.
- Přihlášení přes Google OAuth nebo e-mail/heslo pomocí Supabase Auth.
- Uložený profil psa, postup, mise, kartička a výsledky kvízu v Supabase. Pro návštěvníky bez účtu se používá lokální uložení v prohlížeči.
- Responzivní navigaci včetně spodní navigace na mobilu.

## Cloudflare Pages
- Projekt: `hodnypes`
- Produkční větev: `main`
- Výstupní adresář: `.`
- Build příkaz: prázdný (statický HTML/CSS/JavaScript)

## Supabase databáze a bezpečnost
Projekt `hodnypes` obsahuje:
- `public.user_app_data` — řádek pro každého uživatele, jehož přístup chrání RLS; uživatel může číst a upravovat pouze svůj vlastní řádek.
- `public.community_posts` — veřejně čitelné příspěvky; zápis a mazání jsou omezeny na vlastníka přihlášeného účtu.

Fotografie z generátoru kartiček zůstává lokálně v prohlížeči a není nahrávána do cloudu. Cloudový profil uchovává textové údaje a výsledky aktivit. Nikdy nevkládej Supabase service-role klíč ani OAuth secret do veřejného HTML.

## Google OAuth — nutný ruční krok
Kód volá Supabase OAuth, ale poskytovatele Google nelze dokončit bez Client ID a Client Secret vytvořených ve tvém Google Cloud projektu. Tyto údaje nebyly vygenerovány ani vloženy do repozitáře.

1. Otevři [Google Cloud Console](https://console.cloud.google.com/) a vytvoř OAuth Client ID typu **Web application**. Nakonfiguruj obrazovku souhlasu (OAuth consent screen / Google Auth Platform).
2. Do **Authorized JavaScript origins** přidej `https://hodnypes.pages.dev`.
3. V Supabase Dashboard projektu `hodnypes` otevři **Authentication → Sign In / Providers → Google**. Zkopíruj z této obrazovky přesnou callback URL projektu.
4. Přesnou callback URL vlož do Google Cloud pole **Authorized redirect URIs**. Obvykle má tvar `https://krgtpruozlhygziwlwbt.supabase.co/auth/v1/callback`; použij hodnotu z aktuálního Supabase Dashboardu.
5. Vrať se do Supabase, zapni Google provider a vlož Google Client ID a Client Secret.
6. V **Authentication → URL Configuration** nastav Site URL na `https://hodnypes.pages.dev` a do Redirect URLs přidej `https://hodnypes.pages.dev/**`. Pokud budeš používat vlastní doménu, přidej její konkrétní HTTPS URL.
7. Otestuj přihlášení přes Google v anonymním okně.

**Client Secret patří pouze do Supabase, nikdy do GitHubu ani do `index.html`.** Přesný návod v dokumentaci: [Supabase — Sign in with Google](https://supabase.com/docs/guides/auth/social-login/auth-google).

## E-mail a heslo
Aplikace používá Supabase Auth `signUp`, `signInWithPassword` a obnovu hesla. V Supabase Dashboard zkontroluj, že je povolený e-mailový provider, registrace nových uživatelů a nastavení potvrzení e-mailu. Pokud je potvrzení vyžadováno, uživatel musí kliknout na odkaz v e-mailu. Pro spolehlivé doručování v produkci může být potřeba nakonfigurovat SMTP.

## Ověření a omezení
- Cloudflare Pages deployment pro commit `76e71de43cf0da89bc0715737a76608e18342662` byl potvrzen jako úspěšný.
- Databázové tabulky byly ověřeny přes Supabase a mají zapnuté RLS.
- Skutečné přihlášení Google nelze potvrdit do dokončení ruční OAuth konfigurace v Google Cloud a Supabase.
- Automatizované interakční testy v prohlížeči nebyly provedeny.
- Odkazy na kurzy a produkty vedou na hlavní stránku https://hodnypes.cz/, protože přesné cílové URL nebyly ověřeny.
- Odznaky jsou herní prvky, nikoli skutečná certifikace. Tréninková doporučení jsou orientační a nenahrazují individuální radu kvalifikovaného trenéra.
