from os import listdir
import json

def makeManifest():
	paths = listdir("lib")
	paths.remove("manifest.json")

	modules = {}

	for path in paths:
		name = path[:-4] # cut off .lua
		loc = "lib/" + path
		modules[name] = path

	return modules

def saveManifest(modules):
	mfile = open("lib/manifest.json", 'w')
	j = json.dumps(modules)
	mfile.write(j)


m = makeManifest()
print(m)
saveManifest(m)
