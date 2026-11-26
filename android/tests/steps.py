launch(); shot("00-welcome"); print(texts())
tap("Get started"); shot("01-home"); print(texts())
for t in ["Explore", "Trips", "Saved", "Guide", "Home"]:
    tap(t, exact=True); shot("02-tab-" + t.lower())
tap("Guide", exact=True); tap("Darija", required=False); shot("03-guide-darija")
back(); tap("Home", exact=True)
tap("Marrakech", required=False); shot("04-city"); back()
# offline + relaunch
adb("shell", "cmd", "connectivity", "airplane-mode", "enable"); time.sleep(3)
launch(); shot("05-offline-home"); check("Home")
adb("shell", "cmd", "connectivity", "airplane-mode", "disable")
