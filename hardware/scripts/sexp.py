# Minimaler S-Expression-Parser/Writer fuer KiCad-Dateien
import re

def parse(text):
    tokens = re.findall(r'\(|\)|"(?:[^"\\]|\\.)*"|[^\s()"]+', text)
    stack = [[]]
    for t in tokens:
        if t == '(':
            stack.append([])
        elif t == ')':
            e = stack.pop()
            stack[-1].append(e)
        else:
            stack[-1].append(t)
    return stack[0]

def dump(e, ind=0):
    if not isinstance(e, list):
        return e
    if all(not isinstance(x, list) for x in e):
        return '(' + ' '.join(e) + ')'
    head = []
    i = 0
    while i < len(e) and not isinstance(e[i], list):
        head.append(e[i]); i += 1
    s = '(' + ' '.join(head)
    for x in e[i:]:
        if isinstance(x, list):
            s += '\n' + '\t' * (ind + 1) + dump(x, ind + 1)
        else:
            s += ' ' + x
    return s + '\n' + '\t' * ind + ')'

def q(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

def unq(s):
    return s[1:-1] if s.startswith('"') else s

def find(e, key):
    return [x for x in e if isinstance(x, list) and x and x[0] == key]

def lib_symbol(libdir, lib, name):
    """Symbol aus Bibliothek holen, abgeleitete Symbole (extends) flachklopfen,
    Namen fuer die Einbettung in den Schaltplan anpassen."""
    tree = parse(open(f'{libdir}/{lib}.kicad_sym', encoding='utf-8').read())[0]
    syms = {unq(s[1]): s for s in find(tree, 'symbol')}
    s = syms[name]
    ext = find(s, 'extends')
    if ext:
        parent = syms[unq(ext[0][1])]
        pname = unq(parent[1])
        props = find(s, 'property')
        new = ['symbol', q(f'{lib}:{name}')]
        for x in parent[2:]:
            if isinstance(x, list) and x[0] == 'property':
                continue
            if isinstance(x, list) and x[0] == 'symbol':
                sub = list(x)
                sub[1] = q(unq(x[1]).replace(pname, name, 1))
                new.append(sub)
            else:
                new.append(x)
        # Eigenschaften des abgeleiteten Symbols vor die Grafik setzen
        idx = next(i for i, x in enumerate(new) if isinstance(x, list) and x[0] == 'symbol')
        new[idx:idx] = props
        return new
    s = list(s)
    s[1] = q(f'{lib}:{name}')
    return s

def pins(sym):
    """Pins (Nummer -> (x, y, winkel)) eines eingebetteten Symbols, Einheit 1."""
    res = {}
    for sub in find(sym, 'symbol'):
        for p in find(sub, 'pin'):
            at = find(p, 'at')[0]
            num = unq(find(p, 'number')[0][1])
            res.setdefault(num, (float(at[1]), float(at[2]), float(at[3])))
    return res
