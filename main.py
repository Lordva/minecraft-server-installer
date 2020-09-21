import subprocess
import sys
from time import sleep
import wget
from distutils.spawn import find_executable

NameList = []
ProxyURL = "https://papermc.io/ci/job/Waterfall/lastStableBuild/artifact/Waterfall-Proxy/bootstrap/target/Waterfall.jar"
PaperURL = "https://papermc.io/ci/job/paper/lastStableBuild/artifact/paperclip.jar"

def startup():
    if sys.argv[1] == "-c" and len(sys.argv) >= 4:
        try:
            int(sys.argv[2])
            if len(sys.argv) >= int(sys.argv[2]) + 3:
                i = 0
                while i < int(sys.argv[2]):
                    n = 3+i
                    NameList.append(sys.argv[n])
                    i += 1
                print(NameList)
                create()
            else:
                print("[ERROR] all servers must have a name")
        except ValueError:
            print("[ERROR] number of servers must be an int")
    else:
        print("[ERROR] Unknown argument!")


def create():
    if CheckDependencies("screen"):
       print("screen is installed")
    else:
        print("installing screen")
        subprocess.run(["sudo", "apt-get", "install", "screen", "-y"])
    for x in range(0, len(NameList)):
        path = "/srv/mc/%s" % NameList[x]
        create_srv_dir = subprocess.run(["mkdir", "-p", path])
        if create_srv_dir.returncode !=0:
            print("[ERROR] Could not create server folder")
            sleep(2)
            return False
        else:
            print("Sucessfully created ", path)
            subprocess.Popen(["cd", path], shell=True)
            subprocess.run(["wget", PaperURL])
            fullpath = path+"/server.jar"
            subprocess.run(["mv", "paperclip.jar", fullpath])
            subprocess.run(["wget", ])

        x += 1
    if len(NameList) > 1:
        create_proxy_dir = subprocess.run(["mkdir", "/srv/proxy"])
        if create_proxy_dir.returncode != 0:
            print("[ERROR] Could not create proxy folder unexpected error")
            sleep(2)
            return False
        else:
            print("Proxy folder successfully created")
            subprocess.run(["wget", "-O", "/srv/proxy/Waterfall.jar", ProxyURL])


    else:
        print("Only one server, no proxy required")


def CheckDependencies(name):
    return find_executable(name) is not None

startup()
