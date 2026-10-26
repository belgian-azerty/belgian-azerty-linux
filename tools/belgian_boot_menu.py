#!/usr/bin/env python3
"""Boot menu "B" for the Belgian stick: language first, then keyboard (decided by Younes on 2026-10-24).

    belgian_boot_menu.py grub|isolinux WITH_PACKAGES < menu.cfg > menu.cfg.new

The first live entry of the menu (the "Try or Install" / "Start Linux Mint" one) becomes one submenu per language;
each submenu offers the keyboards. Every other entry (safe graphics, NVIDIA, compatibility mode, OEM, Power Off ...)
stays as the distribution wrote it, so the stick stays close to the stock one. Nederlands with the period is the
default and starts by itself after the usual timeout.

WITH_PACKAGES=1: the stick carries our packages (extra layer), so the Comma entries are offered and English gets
Belgian formats. WITH_PACKAGES=0: only the Period and QWERTZ entries (the live system cannot set the numpad comma at
boot by itself) and English keeps the formats of English (US).

isolinux/syslinux (legacy BIOS) cannot show UTF-8, so its titles are folded to ASCII (Belgie, Francais).
"""
import re
import sys
import unicodedata

LANGS = [
    ("nl_BE", "Nederlands (België)", "Terug", [
        ("period", "Belgisch AZERTY, punt op het numeriek klavier"),
        ("comma", "Belgisch AZERTY, komma op het numeriek klavier")]),
    ("fr_BE", "Français (Belgique)", "Retour", [
        ("period", "AZERTY belge, point sur le pavé numérique"),
        ("comma", "AZERTY belge, virgule sur le pavé numérique")]),
    ("de_BE", "Deutsch (Belgien)", "Zurück", [
        ("period", "Belgisch AZERTY, Punkt auf dem Ziffernblock"),
        ("comma", "Belgisch AZERTY, Komma auf dem Ziffernblock"),
        ("qwertz", "Deutsch QWERTZ")]),
    ("en_US", "English", "Back", [
        ("period", "Belgian AZERTY, period on the numpad"),
        ("comma", "Belgian AZERTY, comma on the numpad"),
        ("qwertz", "German QWERTZ")]),
]
# Kernel options that an earlier run of the repack tool (or this script) may have added; dropped from the template.
OURS = re.compile(r"\s(keyboard-configuration/\S+|locale=\S+|belgian\.\S+|maybe-ubiquity)(?=\s|$)")


def params(loc, kb, packages):
    p = ["keyboard-configuration/layoutcode=" + ("de" if kb == "qwertz" else "be"), "locale=%s.UTF-8" % loc,
         "belgian.keyboard=" + ("de" if kb == "qwertz" else "be")]
    if kb != "qwertz":
        p.append("belgian.decimal=" + kb)
    if loc == "en_US" and packages:
        p.append("belgian.formats=be")
    return " ".join(p)


def with_params(line, extra):
    """Put EXTRA before the ' ---' / ' --' separator (what follows it is copied to the installed system)."""
    line = OURS.sub("", line.rstrip("\n"))
    m = re.search(r" ---?(?= |$)", line)
    return (line[:m.start()] + " " + extra + line[m.start():] if m else line + " " + extra) + "\n"


def ascii_fold(s):
    return unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()


def entries(packages):
    for loc, title, back, kbs in LANGS:
        yield loc, title, back, [(kb, label) for kb, label in kbs if packages or kb != "comma"]


def grub(lines, packages):
    out, i, n, top = [], 0, len(lines), 0
    while i < n:
        line = lines[i]
        m = re.match(r'(\s*)menuentry\s+(["\'])(.*?)\2(.*)\{\s*$', line)
        if m and not out_done(out):
            j = i
            while not re.match(r"\s*\}\s*$", lines[j]):
                j += 1
            body = lines[i + 1:j]
            if any("casper" in b for b in body):
                ind, title, rest = m.group(1), m.group(3), m.group(4).rstrip()
                out.append('%sset default="%d>0"\n' % (ind, top))
                for loc, ltitle, _back, kbs in entries(packages):
                    out.append('%ssubmenu "%s - %s"%s {\n' % (ind, title, ltitle, (" " + rest.strip()) if rest.strip() else ""))
                    for kb, label in kbs:
                        out.append('%s\tmenuentry "%s"%s {\n' % (ind, label, (" " + rest.strip()) if rest.strip() else ""))
                        for b in body:
                            if re.match(r"\s*(linux|linuxefi)\s", b) and "casper" in b:
                                b = with_params(b, params(loc, kb, packages))
                            out.append("\t" + b)
                        out.append("%s\t}\n" % ind)
                    out.append("%s}\n" % ind)
                out.append("#belgian-menu-done\n")
                i = j + 1
                continue
        if re.match(r"\s*(menuentry|submenu)\s", line):
            top += 1
        out.append(line)
        i += 1
    return [l for l in out if l != "#belgian-menu-done\n"]


def out_done(out):
    return "#belgian-menu-done\n" in out


def isolinux(lines, packages):
    out, i, n, done, old_label, first_label = [], 0, len(lines), False, None, None
    while i < n:
        line = lines[i]
        m = re.match(r"\s*label\s+(\S+)", line, re.I)
        if m and not done:
            j = i + 1
            while j < n and lines[j].strip() and not re.match(r"\s*label\s", lines[j], re.I):
                j += 1
            block = lines[i:j]
            if any("casper" in b for b in block):
                done, old_label = True, m.group(1)
                prefix = ""
                for b in block:
                    mm = re.match(r"\s*menu\s+label\s+(.*)$", b, re.I)
                    if mm:
                        prefix = mm.group(1).replace("^", "").strip()
                for k, (loc, ltitle, back, kbs) in enumerate(entries(packages)):
                    out.append("MENU BEGIN %s\n" % loc)
                    out.append("  MENU TITLE %s - %s\n" % (prefix, ascii_fold(ltitle)))
                    for kk, (kb, label) in enumerate(kbs):
                        lab = "%s_%s" % (loc, kb)
                        first_label = first_label or lab
                        out.append("  LABEL %s\n" % lab)
                        out.append("    MENU LABEL %s\n" % ascii_fold(label))
                        for b in block[1:]:
                            if re.match(r"\s*menu\s+(label|default)\b", b, re.I):
                                continue
                            if re.match(r"\s*append\s", b, re.I) and "casper" in b:
                                b = with_params(b, params(loc, kb, packages))
                            out.append("    " + b.strip() + "\n")
                    out.append("  LABEL %s_back\n    MENU LABEL %s\n    MENU EXIT\n" % (loc, ascii_fold(back)))
                    out.append("MENU END\n")
                out.append("ONTIMEOUT %s\n" % first_label)
                i = j
                continue
        out.append(line)
        i += 1
    # No DEFAULT / MENU DEFAULT on an entry inside a submenu: vesamenu would then open in that submenu instead of the
    # language list (seen in the emulator). ONTIMEOUT alone starts Nederlands with the period after the timeout.
    if old_label:
        pat = re.compile(r"^\s*default\s+%s\s*$" % re.escape(old_label), re.I)
        out = ["# (default entry: see ONTIMEOUT below)\n" if pat.match(l) else l for l in out]
    return out


def main():
    kind, packages = sys.argv[1], sys.argv[2] == "1"
    lines = sys.stdin.readlines()
    sys.stdout.writelines(grub(lines, packages) if kind == "grub" else isolinux(lines, packages))


if __name__ == "__main__":
    main()
