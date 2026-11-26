import subprocess, time, re, sys, xml.etree.ElementTree as ET
PKG = "com.dalil.maroc"
fails = []
def adb(*a):
    return subprocess.run(["adb", *a], capture_output=True, text=True).stdout
def shot(name):
    subprocess.run("adb exec-out screencap -p > shots-android/%s.png" % name, shell=True)
def dump():
    for _ in range(3):
        adb("shell", "uiautomator", "dump", "/sdcard/u.xml")
        x = adb("shell", "cat", "/sdcard/u.xml")
        try:
            return ET.fromstring(x[x.index("<"):])
        except Exception:
            time.sleep(1)
    return None
def nodes():
    r = dump(); out = []
    if r is None: return out
    for n in r.iter("node"):
        t = (n.get("text") or "") or (n.get("content-desc") or "") or ("<edit>" if n.get("class","").endswith("EditText") else "")
        m = re.findall(r"\d+", n.get("bounds") or "")
        if len(m) == 4:
            x1, y1, x2, y2 = map(int, m)
            out.append((t, (x1 + x2) // 2, (y1 + y2) // 2, x2 - x1, y2 - y1))
    return out
def texts():
    return [n[0] for n in nodes() if n[0]]
def tap(label, exact=False, required=True):
    for _ in range(2):
        ns = nodes()
        c = [n for n in ns if n[0].strip().lower() == label.lower()] or ([] if exact else [n for n in ns if label.lower() in n[0].lower()])
        if c:
            adb("shell", "input", "tap", str(c[0][1]), str(c[0][2]))
            time.sleep(1.5); return True
        time.sleep(1)
    if required:
        fails.append("TAP not found: " + label)
        print("FAIL tap", label, "| visible:", [n[0] for n in ns if n[0]][:25])
    return False
def scroll():
    adb("shell", "input", "swipe", "540", "1700", "540", "700", "300"); time.sleep(1)
def check(label):
    ok = any(label.lower() in t.lower() for t in texts())
    print(("OK   " if ok else "FAIL ") + "visible: " + label)
    if not ok: fails.append("not visible: " + label)
def edit_taps(i=0):
    es = [n for n in nodes() if n[0] in ("<edit>",) or False]
    return es
def tap_edit(i=0):
    r = dump(); out = []
    if r is None: return False
    for n in r.iter("node"):
        if n.get("class","").endswith("EditText"):
            m = re.findall(r"\d+", n.get("bounds") or ""); x1,y1,x2,y2 = map(int, m); out.append(((x1+x2)//2,(y1+y2)//2))
    if len(out) > i:
        adb("shell","input","tap",str(out[i][0]),str(out[i][1])); time.sleep(1); return True
    fails.append("no EditText %d" % i); return False
def typ(s):
    adb("shell","input","text",s); time.sleep(1)
def menu():
    if not tap("Menu", required=False):
        adb("shell","input","tap","988","197"); time.sleep(1.5)
def launch():
    adb("shell", "am", "force-stop", PKG)
    adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1"); time.sleep(5)
def back():
    adb("shell", "input", "keyevent", "4"); time.sleep(1.5)

exec(open("android/tests/steps.py").read())
print("FAILS:", fails)
open("shots-android/RESULT.txt","w").write("FAILS: "+repr(fails)+"\n")
sys.exit(1 if fails else 0)
