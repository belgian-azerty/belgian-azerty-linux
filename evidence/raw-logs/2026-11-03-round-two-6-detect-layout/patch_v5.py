import sys
p = sys.argv[1]; s = open(p).read()
old = """            # If that didn't work, generate yes/no questions.
    for pri, sym in syms:"""
assert s.count(old) == 1
new = """    # Before asking whether a symbol that may exist only on an AltGr level
    # is present (such symbols are often not printed on the key caps, e.g.
    # oe on Belgian keyboards), try "press a key" choices with symbols on
    # plain or Shift levels that the depth limit above skipped.
    if depth:
        tried = set(sym for pri, sym in syms[:depth + 1])
        for pri, sym in syms_no_alt:
            if sym not in tried and sym not in xxsyms:
                if do_log and trace > 1:
                    print("Return1b", do_log, "".join(get_sym(sym)))
                yield sym, None

            # If that didn't work, generate yes/no questions.
    for pri, sym in syms:"""
open(p, "w").write(s.replace(old, new))
