{
  "ConfigValues": {
    "gamepipe_test": {"copyToTargets":"3035461389054378222",},
  },
  "optionsFile": "options.json",
  "options": [],
  "exportToGame": true,
  "supportedTargets": -1,
  "extensionVersion": "0.0.1",
  "packageId": "",
  "productId": "",
  "author": "",
  "date": "2022-05-27T10:59:46.2251242-05:00",
  "license": "",
  "description": "",
  "helpfile": "",
  "iosProps": false,
  "tvosProps": false,
  "androidProps": true,
  "installdir": "",
  "files": [
    {"filename":"_olympus_extension.ext","origname":"","init":"_olympus_android_init","final":"","kind":4,"uncompress":false,"functions":[
        {"externalName":"_olympus_android_init","kind":4,"help":"","hidden":false,"returnType":1,"argCount":0,"args":[],"resourceVersion":"1.0","name":"_olympus_android_init","tags":[],"resourceType":"GMExtensionFunction",},
        {"externalName":"_olympus_android_game_end","kind":4,"help":"","hidden":false,"returnType":1,"argCount":0,"args":[],"resourceVersion":"1.0","name":"_olympus_android_game_end","tags":[],"resourceType":"GMExtensionFunction",},
      ],"constants":[],"ProxyFiles":[],"copyToTargets":8,"order":[
        {"name":"_olympus_android_init","path":"extensions/_olympus_extension/_olympus_extension.yy",},
        {"name":"_olympus_android_game_end","path":"extensions/_olympus_extension/_olympus_extension.yy",},
      ],"resourceVersion":"1.0","name":"","tags":[],"resourceType":"GMExtensionFile",},
  ],
  "classname": "",
  "tvosclassname": null,
  "tvosdelegatename": null,
  "iosdelegatename": "",
  "androidclassname": "Olympus",
  "sourcedir": "",
  "androidsourcedir": "",
  "macsourcedir": "",
  "maccompilerflags": "",
  "tvosmaccompilerflags": "",
  "maclinkerflags": "",
  "tvosmaclinkerflags": "",
  "iosplistinject": "",
  "tvosplistinject": "",
  "androidinject": "\r\n<meta-data android:name=\"com.google.test.loops\" android:value=\"5\"></meta-data>\r\n",
  "androidmanifestinject": "",
  "androidactivityinject": "\r\n   <intent-filter>\r\n       <action android:name=\"com.google.intent.action.TEST_LOOP\"></action>\r\n       <category android:name=\"android.intent.category.DEFAULT\"></category>\r\n       <data android:mimeType=\"application/javascript\"></data>\r\n   </intent-filter>\r\n",
  "gradleinject": "",
  "androidcodeinjection": "<YYAndroidManifestActivityInject>\r\n   <intent-filter>\r\n       <action android:name=\"com.google.intent.action.TEST_LOOP\"/>\r\n       <category android:name=\"android.intent.category.DEFAULT\"/>\r\n       <data android:mimeType=\"application/javascript\"/>\r\n   </intent-filter>\r\n</YYAndroidManifestActivityInject>\r\n\r\n<YYAndroidManifestApplicationInject>\r\n<meta-data\r\n  android:name=\"com.google.test.loops\"\r\n  android:value=\"5\" />\r\n</YYAndroidManifestApplicationInject>\r\n",
  "hasConvertedCodeInjection": true,
  "ioscodeinjection": "",
  "tvoscodeinjection": "",
  "iosSystemFrameworkEntries": [],
  "tvosSystemFrameworkEntries": [],
  "iosThirdPartyFrameworkEntries": [],
  "tvosThirdPartyFrameworkEntries": [],
  "IncludedResources": [],
  "androidPermissions": [],
  "copyToTargets": 8,
  "iosCocoaPods": "",
  "tvosCocoaPods": "",
  "iosCocoaPodDependencies": "",
  "tvosCocoaPodDependencies": "",
  "parent": {
    "name": "Olympus",
    "path": "folders/Modules/Olympus.yy",
  },
  "resourceVersion": "1.2",
  "name": "_olympus_extension",
  "tags": [],
  "resourceType": "GMExtension",
}