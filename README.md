# CaSSAndRA native

(A native UI for your CaSSAndRA instances)

CaSSAndRA native is a UI for your CaSSAndRA instances that allows you to manage multiple CaSSAndRA instances from a single app.

[![introduction](https://img.youtube.com/vi/hRQSuVfvbvE/0.jpg)](https://www.youtube.com/watch?v=hRQSuVfvbvE)

## Requirements
- You have at least one  [CaSSAndRA](https://github.com/EinEinfach/CaSSAndRA) instance successfully running.
- You have an MQTT server running in your local network (if not, you can use this [guide](https://medium.com/gravio-edge-iot-platform/how-to-set-up-a-mosquitto-mqtt-broker-securely-using-client-certificates-82b2aaaef9c8) to install a Mosquitto server, e.g., on your CaSSAndRA hardware).
- You have an iOS or Android device (Windows, Linux, and macOS support coming soon).

## Installation
### Android:

Go to /builds/Android download for your device compatible apk file and install it.

### iOS:

Use the sideloading method of your choice (e.g., AltStore). You can find the IPA file under /builds/iOS. If you choose AltStore (not AltStore PAL!!!), it makes installing and updating the app especially easy.

To do this, go to Sources in AltStore and add my app store as a possible app source. Simply use this link as the source:
https://eineinfach.github.io/CaSSAndRA_native/builds/iOS/AltStore/altstore.json

From there, you can install the app and will be notified whenever a new version is available.

## Preparation

To control your CaSSAndRA instance with CaSSAndRA native, you need to enable the API in the settings.

To do this, go to your CaSSAndRA interface and enable the MQTT API under Settings. Enter the details of your MQTT server.
- For Client ID, enter any name you like, but make sure it is unique within your environment.
- For Cassandra server name with prefix, also choose any unique name. Make sure to remember these.

## Add a CaSSAndRA instance to CaSSAndRA native

Switch to Cassandra Native and press the plus button at the bottom right. An input form will appear.
- For Alias, enter any name that best describes your robot/server for you.
- Under Cassandra API name with prefix, enter the data you noted down in the previous step.
- Select your robot type in dropdown menu.
- Finally, add your MQTT server details and press save.

![first start](https://raw.githubusercontent.com/EinEinfach/CaSSAndRA_native/master/docs/server_instance_template.png)

A successful connection is indicated by a neutral color on the dashboard.

## Donation

If you enjoyed CaSSAndRA native project — or just feeling generous, consider buying me a beer. Cheers!

[![](https://www.paypalobjects.com/en_US/DK/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate/?hosted_button_id=DTLYLLR45ZMPW)

## Authors

- [@EinEinfach](https://www.github.com/EinEinfach)