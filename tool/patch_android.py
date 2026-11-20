"""يعدّل ملفات أندرويد اللي يولّدها `flutter create` حتى تناسب التطبيق.
يشتغل تلقائياً داخل GitHub Actions بعد flutter create.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, "android", "app")
LABEL = "مساعد الجم"


def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def write(p, s):
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)


# ---------------- AndroidManifest ----------------
man_p = os.path.join(APP, "src", "main", "AndroidManifest.xml")
man = read(man_p)
if "android.permission.INTERNET" not in man:
    man = man.replace(
        "<application",
        '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
        1,
    )
man = re.sub(r'android:label="[^"]*"', f'android:label="{LABEL}"', man, count=1)
write(man_p, man)

# ---------------- build.gradle(.kts) ----------------
kts = os.path.join(APP, "build.gradle.kts")
groovy = os.path.join(APP, "build.gradle")
signing = all(os.environ.get(k) for k in ("KS_PATH", "KS_PASS", "KS_ALIAS"))

if os.path.exists(kts):
    g = read(kts)
    g = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 24", g)
    g = re.sub(r"compileSdk\s*=\s*flutter\.compileSdkVersion", "compileSdk = 36", g)
    g = re.sub(r"targetSdk\s*=\s*flutter\.targetSdkVersion", "targetSdk = 36", g)
    if signing and 'create("release")' not in g:
        block = """
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KS_PATH")!!)
            storePassword = System.getenv("KS_PASS")
            keyAlias = System.getenv("KS_ALIAS")
            keyPassword = System.getenv("KS_PASS")
        }
    }

    buildTypes {"""
        g = g.replace("\n    buildTypes {", block, 1)
        g = g.replace('signingConfig = signingConfigs.getByName("debug")',
                      'signingConfig = signingConfigs.getByName("release")')
    write(kts, g)
elif os.path.exists(groovy):
    g = read(groovy)
    g = re.sub(r"minSdk(Version)?\s+flutter\.minSdkVersion", "minSdkVersion 24", g)
    g = re.sub(r"compileSdk(Version)?\s+flutter\.compileSdkVersion", "compileSdkVersion 36", g)
    g = re.sub(r"targetSdk(Version)?\s+flutter\.targetSdkVersion", "targetSdkVersion 36", g)
    if signing and "signingConfigs {" not in g:
        block = """
    signingConfigs {
        release {
            storeFile file(System.getenv("KS_PATH"))
            storePassword System.getenv("KS_PASS")
            keyAlias System.getenv("KS_ALIAS")
            keyPassword System.getenv("KS_PASS")
        }
    }

    buildTypes {"""
        g = g.replace("\n    buildTypes {", block, 1)
        g = g.replace("signingConfig signingConfigs.debug", "signingConfig signingConfigs.release")
    write(groovy, g)
else:
    sys.exit("ما لكيت build.gradle — شغّل flutter create أولاً")

gp = os.path.join(os.path.dirname(APP), "gradle.properties")
if os.path.exists(gp):
    t = read(gp)
    if "suppressUnsupportedCompileSdk" not in t:
        write(gp, t.rstrip("\n") + "\nandroid.suppressUnsupportedCompileSdk=36\n")

print("Android patched. release signing:", "ON" if signing else "OFF (debug key)")
