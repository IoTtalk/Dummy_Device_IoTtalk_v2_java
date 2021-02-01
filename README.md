# Dummy Device for IoTtalk v2 (Java)

## Dependent libraries
已經有放在`libs`裡面了，可以不用另外下載
* [org.json](https://mvnrepository.com/artifact/org.json/json)
    * [Download jar](https://repo1.maven.org/maven2/org/json/json/20201115/json-20201115.jar)
* [org.eclipse.paho.client.mqttv3](https://mvnrepository.com/artifact/org.eclipse.paho/org.eclipse.paho.client.mqttv3/1.2.5)
    * [Download jar](https://repo.eclipse.org/content/repositories/paho-releases/org/eclipse/paho/org.eclipse.paho.client.mqttv3/1.2.5/org.eclipse.paho.client.mqttv3-1.2.5.jar)

## 如何使用
1. 在 `src/sa/SA.java`裡面修改設定
    * 如果只是想跑`Dummy Device`，可以設定，`src/sa/SA.java`中的`api_url`即可。
    * 如果要修改其他設定，請看 [詳細說明](#SA-說明)
2. 編譯 : `./compile.sh`
3. 執行 : `./run.sh` 或 `java -cp "bin:libs/*" sa.Main`
* 若想要更新 `iottalk.jar`, 可執行 `./update_iottalk_jar.sh`.
* 如果想要撰寫自己的DAI, 可以看 [這裡 (iottalk-java)](https://github.com/IoTtalk/iottalk-java) 有詳細說明。

## SA 說明
### 變數說明
* `public String api_url` : csm的url。 ex : `"http://localhost:9992/csm"`
* `public String device_model` : Device Model名稱。 ex : `"Dummy Device"`
* `public String device_name` : Device的名稱，就是顯示在iottalk GUI上的名稱。 ex : `"Dummy_test"`
* `public String username` (OPTIONAL) : 設為某user private使用。
* `public String device_addr` (OPTIONAL) : 設定自訂的UUID，需為Hex String。 ex: `"aaaaa1234567890abcdef"`。
* `public boolean persistent_binding` (OPTIONAL) : 若為`true`，DAN將不會在disconnect後註銷該Device，在project中的binding會被保留，下次此Device重連時，會自動bind上。**注意 : 設為`true`時，必需設定`device_addr`值!**

### Device Feature設定
IDF 與 ODF 設定需要用 `DeviceFeature` 這個 class 定義
IDF
---

```java=
public DeviceFeature <IDF name> = new DeviceFeature("<IDF name>", "idf"){
    @Override
    public JSONArray publishData() throws JSONException{
        //Create push data...
        
        //Change data into JSONArray
        //int [] pushData = {1};
        //double [] pushData = {1.1};
        //String [] pushData = {"push data"};
        JSONArray r = new JSONArray(pushData);
        return r;
    }
};
```
* **`<IDF name>`必需和iottalk上的名稱相同。**
* IDF 需要 override `public JSONArray publishData()` 這個 function，DAI 會依照 push interval 的設定，定期像 server push 資料。
* Example
```java=
public DeviceFeature Dummy_Sensor = new DeviceFeature("Dummy_Sensor", "idf"){
    @Override
    public JSONArray publishData() throws JSONException{
        int max = 100;
        int min = 1;
        int randomNum = min + (int)(Math.random() * ((max-min) + 1));
        int [] pushData = {randomNum};
        JSONArray r = new JSONArray(pushData);
        return r;
    }
};
```

* Push Interval 設定，DAI會依據`public double push_interval`, `public Map<String, Double> interval`中的值，決定push資料的週期。
    * 每個 IDF push data週期 = 如果 `interval` 中存在對應值，就使用該數值；若不存在就使用 `push_interval` 的數值。
    * `public double push_interval` : 單位為`秒`。
    * `public Map<String, Double> interval`格式，對應值單位為`秒` : 
```java=
public Map<String, Double> interval = new HashMap<String, Double>() {{
    put("<IDF1 name>", new Double(<second>));
    put("<IDF2 name>", new Double(<second>));
    ...
}};
```
Example : 
此範例中，`Dummy_Sensor` push data週期為`2 x 0.3 = 0.6`秒
```java=
public double push_interval = 2;

public Map<String, String> interval = new HashMap<String, String>() {{
    put("Dummy_Sensor", "0.3");  //assign feature interval
}};
```

ODF
---

```java=
public DeviceFeature <ODF name> = new DeviceFeature("<ODF name>", "odf"){
    @Override
        public void onData(MqttMessage message, String df_name, String df_type){
            //Callback function body...
        }
};
```
* **`<ODF name>`必需和iottalk上的名稱相同。**
* ODF 需要 override `public void onData(MqttMessage message, String df_name, String df_type)` 這個 function，當 ODF 值有更新時，此 function 會被呼叫，且可以在 `message` 中得到更新值。
* Example
```java=
public DeviceFeature Dummy_Control = new DeviceFeature("Dummy_Control", "odf"){
    @Override
    public void onData(MqttMessage message, String df_name, String df_type){
        System.out.println(df_name);
        try{
            JSONArray so = new JSONArray(new String(message.getPayload(), "UTF-8"));
            System.out.println(so);
        } catch(Exception e){
            e.printStackTrace();
        }

    }
};
```

### Callback function
以下4個callback會在對應的時機被DAN呼叫，若有需求，可自行宣告。
* `public void on_register()` : 在`DAN`註冊 Device 完成後會執行。
* `public void on_deregister()` : 在`DAN`註銷 Device 完成後會執行。
* `public void on_connect()` : 在`DAN`與 server 建立連線後會執行。
* `public void on_disconnect()` : 在`DAN`與 server 正常終止連線後會執行(意外終止則不會)。

Example
```java=
public void on_register(){
    System.out.println("register successfully");
}

public void on_deregister(){
    System.out.println("deregister successfully");
}

public void on_connect(){
    System.out.println("connect successfully");
}

public void on_disconnect(){
    System.out.println("disconnect successfully");
}
```

## 架構圖
![](https://i.imgur.com/3xVnEsH.png)
