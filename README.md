# Hodný pes — veřejný web a osobní akademie

Web je rozdělen na samostatné adresy. Veřejná část slouží pouze k informacím a neobsahuje herní aktivity. Osobní profil a akademie jsou dostupné až po ověření relace.

## Stránky
- / — informační úvodní stránka
- /o-nas/ — informace o Hodném psovi
- /vycvik/ — výcvik a aktivity
- /akce/ — veřejně zveřejněné události
- /ucet/ — registrace, přihlášení, Google OAuth a obnova hesla
- /akademie/ — soukromý přehled
- /profil/, /postup/, /mise/, /lekce/, /kviz/, /dog-puller/, /historie/, /souteze/ — soukromé části akademie
- /administrace/ — správa obsahu, akcí a rolí správců

## Technologie a přístup
- Cloudflare Pages s Pages Functions v adresáři functions/.
- Supabase Auth, Postgres a RLS.
- functions/api/session.js ověřuje access token u Supabase a vydává host-only Secure; HttpOnly; SameSite=Lax cookie.
- functions/_middleware.js ověřuje cookie na serveru před vykreslením soukromých cest; administraci navíc chrání databázová role admin.
- Veřejný klíč Supabase je publishable key. Nikdy nevkládej service-role klíč ani Google Client Secret do veřejného kódu.
- Existující public.user_app_data a public.community_posts zůstávají zachovány. Nová migrace přidává public.user_roles, public.site_content, public.site_events, admin helper funkci a RLS politiky; nic nemaže.

## Ruční konfigurace přihlášení
1. V Supabase Authentication zkontroluj, že je zapnutá e-mailová registrace a zvol, zda vyžaduješ potvrzení e-mailu.
2. V Supabase URL Configuration nastav Site URL na https://hodnypes.pages.dev a přidej redirect URL https://hodnypes.pages.dev/ucet/ (případně i preview URL, kterou opravdu používáš).
3. Pro Google OAuth vytvoř OAuth Client ID typu Web application v Google Cloud. Do Authorized JavaScript origins přidej https://hodnypes.pages.dev, do Authorized redirect URIs vlož přesnou callback URL uvedenou v Supabase Google provider nastavení, následně zapni Google provider a Client ID/Secret vlož pouze do Supabase.
4. Po nasazení otestuj registraci e-mailem, potvrzení e-mailu (pokud je zapnuté), přihlášení, obnovu hesla, Google OAuth a odhlášení. Google OAuth nelze považovat za funkční, dokud se skutečně neotestuje po nastavení poskytovatele.
5. Vlastní doména musí být přidána do Supabase Site URL/Redirect URLs i do testů, pokud ji budeš používat.

## První správce
Role správce se záměrně nepřiděluje automaticky a žádný návštěvník si ji nemůže sám nastavit. Po vytvoření účtu otevři Supabase SQL Editor a nahraď UUID níže skutečným auth.users.id účtu, kterému důvěřuješ:

    insert into public.user_roles (user_id, role)
    values ('DOPLN_SKUTECNE_UUID_UZIVATELE', 'admin')
    on conflict (user_id) do update set role = excluded.role;

Po přidělení role se v /administrace/ zobrazí správa obsahu, akcí, rolí a seznamu profilů akademie. Změny rolí prováděj pouze pro ověřené účty.

## Akademie a katalogy (aktuální rozšíření)
- `public.dog_profiles` ukládá více profilů psů na jeden účet; původní `public.user_app_data.dog_profile` zůstává zachované. Pokud se při prvním otevření profilů najde starý JSON profil a žádný nový profil, aplikace jej zkopíruje do nového seznamu a původní záznam nemaže.
- `public.breed_catalog` poskytuje vyhledávání plemen, aliasů, registru a stavu uznání. Katalog je rozšiřitelný administrací; jsou zahrnuté kříženec, neznámé plemeno a ruční zadání. **Výchozí seznam zatím není úplný celosvětový soupis všech uznaných i místních plemen.** Záznam označ jako ověřený pouze po kontrole uvedeného zdroje. Hlavní referenční seznamy: [FCI nomenklatura](https://www.fci.be/en/nomenclature/Default.aspx), [FCI provizorně uznaná plemena](https://www.fci.be/EN/nomenclature/provisoire.aspx).
- `public.academy_catalog` uchovává katalogy barev, aktivit, vybavení, chování, zdravotních pojmů, soutěží, věkových etap a dovedností.
- `public.academy_content` uchovává spravované lekce, mise, kvízy, kurzy a soutěže. Publikovaný obsah se načítá v příslušných částech akademie.
- `public.academy_completions`, `public.dog_puller_sessions`, `public.quiz_attempts`, `public.academy_reminders` a `public.academy_certificates` uchovávají historii, záznamy Dog Puller, kvízy, připomínky a potvrzení dokončení.
- Administrace obsahuje správu veřejného obsahu, událostí, uživatelských rolí, katalogu plemen, dalších katalogů, obsahu akademie a souhrnu postupu.
- Připomínky se ukládají do databáze, ale **zatím neposílají push oznámení ani e-maily**. Fotografie psů lze nahrávat do soukromého bucketu `dog-media` v Supabase Storage; soubory jsou omezené na JPG/PNG/WebP do 15 MB a RLS politiky povolují přístup pouze vlastníkovi. Starší veřejné URL fotografií zůstávají podporované.
- Web záměrně neobsahuje mapu, geolokaci ani sdílení polohy. Adresa výcvikového centra může být uvedena jako prostý text bez mapového odkazu.
- `npm run build` a `npm test` spouštějí kontrolu syntaxe, požadovaných souborů, hlavních rout, mapových odkazů, konfigurace soukromého úložiště a systémového barevného režimu.
- Certifikáty jsou interní potvrzení aplikace, ne oficiální kvalifikace ani potvrzení od trenéra. Zdravotní a behaviorální informace v katalogu nenahrazují veterinární péči ani individuální doporučení kvalifikovaného odborníka.

## Nasazení
Projekt Cloudflare Pages hodnypes je propojený s repozitářem miroslavmanas94-blip/hodnypes, produkční větev main, výstupní adresář . a prázdný build příkaz. Push do main automaticky spustí nasazení; po změnách ve functions/ ověř stav v Cloudflare Pages.

## Poznámky a omezení
- Veřejné informace o konkrétních kurzech, cenách, trenérech a termínech se nevymýšlejí; stránka odkazuje na oficiální web Hodného psa. Akce se zobrazují až po zveřejnění správcem.
- Body a mise jsou motivační funkce aplikace, ne oficiální certifikace.
- Fotografie z původního generátoru kartiček nebyly převáděny do nového webu; původní soubory a data zůstávají v repozitáři/databázi.
- Po úpravě je nutné ověřit skutečné nasazení a interakční testy v prohlížeči. Samotný úspěšný build neprokazuje funkčnost OAuth.