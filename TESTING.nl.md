# Help testen: Belgisch AZERTY zoals op Windows, voor Linux Mint 22.3 en Zorin OS 18.1

*English: [TESTING.md](TESTING.md) · Français : [TESTING.fr.md](TESTING.fr.md)*

Bedankt om te helpen. Dit project is alleen getest in emulators en op één laptop, dus elke echte computer telt. Je
hoeft geen expert te zijn en je hoeft je naam niet te geven.

## Het meest gezocht

- **Een echte computer** (geen virtuele machine) met Linux Mint 22.3 of Zorin OS 18.1.
- **Linux Mint rechtstreeks op een computer geïnstalleerd** (nog helemaal niet getest).
- **Een tweede toetsenbord** via USB.
- **Een toetsenbord met ingebouwde touchpad** (één toestel, zoals sommige draadloze sets). Lees eerst "Voor je
  begint": dit geval is een gekend risico.
- Zorin OS in zijn gewone Wayland-sessie, en VS Code als je dat gebruikt.

Een virtuele machine (VirtualBox, GNOME Boxes) met Mint 22.3 of Zorin OS 18.1 helpt ook.

## Voor je begint (1 minuut)

- Dit verandert toetsenbordinstellingen. Eén commando haalt alles weer weg (stap 9); het toetsenbord blijft daarna
  Belgisch, want de Belgische indeling is een standaardinstelling van Linux.
- Alleen op **Linux Mint 22.3** of **Zorin OS 18.1**. Niet getest op andere versies of andere distributies.
- **Toetsenbord met ingebouwde touchpad**: zolang de fix draait, kunnen vloeiend scrollen en touchpadgebaren op dat
  ene toestel stoppen. De README ("Known issues") legt uit hoe je dat toestel uitsluit. Laat het ons weten als het
  gebeurt.
- **Als het toetsenbord ooit stopt terwijl de muis nog werkt** (nooit gezien bij het testen): herstart de computer
  met de muis via het systeemmenu.

## Test 1: op een geïnstalleerd systeem of een virtuele machine (ongeveer 20 minuten)

**1. Downloaden.** Download van de [releasepagina](https://github.com/belgian-azerty/belgian-azerty-linux/releases/latest) deze drie bestanden naar je map Downloads:
`keyd-belgian-windows_…_all.deb`, `belgian-azerty-windows_…_all.deb` en `SHA256SUMS`.

**2. Open daar een terminal.** Open de map Downloads, klik rechts op een lege plek, kies "Openen in terminal" (of gelijkaardig).

**3. Controleer de bestanden.** Typ:

```
sha256sum -c SHA256SUMS --ignore-missing
```

Elk van de twee regels moet eindigen op `OK` (op een Nederlandstalig systeem kan dat een vertaald woord zijn).

**4. Installeren.** Typ (het vraagt je wachtwoord):

```
sudo add-apt-repository ppa:keyd-team/ppa
sudo apt install keyd ./keyd-belgian-windows_*.deb ./belgian-azerty-windows_*.deb
sudo be-azerty-fix system
```

De eerste regel voegt de keyd-team PPA toe, die keyd levert (het programma achter Ctrl+Alt als AltGr) voor Mint 22 en
Zorin 18. Voor de komma op het numerieke klavier typ je `sudo DECIMAL=comma be-azerty-fix system` in plaats van de
laatste regel.

**5. Meld je af en weer aan.**

**6. Typ de testregels.** Open de teksteditor. Schrijf voor elke regel precies op wat er verschijnt.

| Regel | Wat je doet | Wat je zou moeten zien |
|---|---|---|
| A | Hou **linker Ctrl + linker Alt** ingedrukt, druk `1` `2` `3` `9` `0` `E`, laat los | `\|@#{}€` |
| B | Hou **AltGr** ingedrukt, druk `1` `2` `3` `9` `0` `E`, laat los | `\|@#{}€` |
| C | Druk één keer **Caps Lock**. Typ de letters `A` `Z` `E`, dan de toetsen `1` `2` `3` van de bovenste rij. Druk weer **Caps Lock** | Mint: `AZE123` · Zorin: `AZE&É"` (op Zorin staat de Windows-Caps Lock uit, tenzij je hem aanzet) |
| D | Num Lock aan, druk de decimale toets van het numerieke klavier | `.` (of `,` als je de komma koos) |
| E | Druk **Ctrl+Alt+T** | er opent een terminal |

**7. Herstart de computer.** Typ op het aanmeldscherm zoals altijd je wachtwoord. Typ na het aanmelden regel A
opnieuw.

**8. Verzamel de gegevens.** Typ in een terminal:

```
be-azerty-fix check 2>&1 | sed "s/\b$USER\b/USER/g" > ~/belgian-check.txt
echo "$XDG_SESSION_TYPE" >> ~/belgian-check.txt
```

Zo krijg je het bestand `belgian-check.txt` in je persoonlijke map, met je gebruikersnaam al vervangen door `USER`
(die staat in een paar regels en in mappaden). **Open het en kijk het na voor je het deelt**: staat je
gebruikersnaam er toch nog ergens in, vervang hem dan door `USER`. Verder staat er niets persoonlijks in.

**9. Verwijderen (of houden).** Wil je het weg:

```
sudo be-azerty-fix uninstall
```

Meld je dan af en weer aan. Regel B (AltGr) zou nog steeds `|@#{}€` moeten geven: dat is standaard Linux.

**Extra, als je het hebt:**
- Tweede USB-toetsenbord: sluit het aan en typ regel A erop.
- Snel typen: hou in de terminal linker Ctrl + linker Alt ingedrukt en druk `2` `E` `2` `E` … acht keer, zo snel als
  je gewoonlijk typt. Verwacht: `@€@€@€@€@€@€@€@€`. Noteer elk omgewisseld paar.
- VS Code: typ regel A in een leeg bestand.
- Zorin, Windows-Caps Lock: lees "Caps Lock on Zorin" in de README, dan `sudo CAPS=windows be-azerty-fix system`,
  meld je af en weer aan, en typ regel C (verwacht `AZE123`).

## Test 2: live-USB op een echte computer (voor wie al Linux gebruikt)

Er is geen kant-en-klaar image. Je maakt de stick op een Linux-computer, uit de officiële ISO die je zelf
downloadde, met één commando (README, "Live USB"). Start de computer van de stick, kies in het opstartmenu je taal
en "Belgisch", en doe de regels A tot E van Test 1 in de live-sessie (er wordt niets op de schijf van de computer
geschreven). Dan stap 8. **Klik niet op "Installeren"**, tenzij je Test 3 doet.

## Test 3: installeren vanaf de stick (alleen op een computer waarvan de schijf gewist mag worden)

Installeren wist de schijf die je kiest. Alleen op een reservecomputer of een lege schijf, nooit op een computer met
bestanden die je nodig hebt. Installeer vanaf de stick met het Belgische toetsenbord; de eerste start na de
installatie duurt langer (de installatie wordt één keer afgewerkt; laat ze lopen). Dan de regels A tot E, stap 7 en
stap 8.

## Stuur het resultaat

Kies wat het makkelijkst is:

- **Met een GitHub-account:** [open een testverslag](https://github.com/belgian-azerty/belgian-azerty-linux/issues/new?template=test-report.yml) (een formulier met dezelfde stappen).
- **Zonder account:** [het anonieme testformulier](https://cryptpad.fr/form/#/2/form/view/cT78QsJwrlkIgiaH7zAyEfyDp+wKDwmZIE1P98anqxs/) (geen account, naam of e-mail nodig).
- **Per e-mail:** linuxbelgiumkeyboard.rc0g4@aleeas.com, met de regels die je zag en `belgian-check.txt`.

Vermeld: Mint of Zorin, geïnstalleerd / virtuele machine / live-USB, wat je zag bij de regels A tot E, en alles wat
vreemd was. Het merk en model van de computer en het toetsenbord helpen, maar zijn niet verplicht. Stuur geen naam,
e-mailadres of gebruikersnaam, tenzij je een antwoord per e-mail wilt.

**Geen tijd om te testen?** De enquête van 2 minuten helpt ook: [English](https://cryptpad.fr/form/#/2/form/view/A9o2MXPQHcgJr0e6Y0eG3Qy0fjz13WeJ1IHy-JGxTy0/) · [Nederlands](https://cryptpad.fr/form/#/2/form/view/mLakgWAFAMsQhn1VkX+rnDxlHPSzbZiloRZxeS6IYlQ/) · [Français](https://cryptpad.fr/form/#/2/form/view/Vs07SGZoahOJOklE8G6wDZaC4Kjdl9mKyBwYAshSCQA/).

Bedankt!
