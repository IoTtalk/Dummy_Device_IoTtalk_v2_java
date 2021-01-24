# Dummy Device for IoTtalk v2 (Java)

## Dependent libraries
* [org.json](https://mvnrepository.com/artifact/org.json/json)
    * [Download jar](https://repo1.maven.org/maven2/org/json/json/20201115/json-20201115.jar)
* [org.eclipse.paho.client.mqttv3](https://mvnrepository.com/artifact/org.eclipse.paho/org.eclipse.paho.client.mqttv3/1.2.5)
    * [Download jar](https://repo.eclipse.org/content/repositories/paho-releases/org/eclipse/paho/org.eclipse.paho.client.mqttv3/1.2.5/org.eclipse.paho.client.mqttv3-1.2.5.jar)

## How to use
1. Modify your setting at `src/sa/SA.java`
    * 如果只是想跑`Dummy Device`，可以設定，`src/sa/SA.java`中的`api_url`即可。
    * 如果要修改其他設定，請看 [詳細說明](#SA-說明)
2. Compile by : `./compile.sh`
3. Run by : `./run.sh` or `java -cp "bin:libs/*" sa.Main`
* If you want to update `iottalk.jar`, run `./update_iottalk_jar.sh`.

## SA 說明
### 變數說明
* `public String api_url` : csm的url。ex : `"http://localhost:9992/csm"`
* `public String device_model` : Device Model名稱。ex : `"Dummy Device"`
* `public String device_name` : Device的名稱，就是顯示在iottalk GUI上的名稱。ex : `"Dummy_test"`
* OPTIONAL variablies，需要使用時，取消註解並填上正確值 :
    * `public String username` : 設為某user private使用。
    * `public String device_addr` : 設定自訂的UUID，需為Hex String。ex: `"aaaaa1234567890abcdef"`。
    * `public boolean persistent_binding` : 若為`true`，DAN將不會在disconnect後註銷該Device，在project中的binding會被保留，下次此Device重連時，會自動bind上。**注意 : 設為`true`時，必需設定`device_addr`值!**

### Device Feature設定
IDF
---
**`<IDF name>`必需和iottalk上的名稱相同。**
```java=
public DeviceFeature <ODF name> = new DeviceFeature("<ODF name>", "idf"){
    @Override
    public JSONArray publishData() throws JSONException{
        //Create push data...
        
        //Change data into JSONArray
        //int [] pushData = 1;
        //double [] pushData = 1.1;
        //String [] pushData = "push data";
        JSONArray r = new JSONArray(pushData);
        return r;
    }
};
```
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

* Push Interval 設定，DAI會依據`public double push_interval`, `public Map<String, String> interval`中的值，決定push資料的週期。
    * push data週期 = `push_interval x interval中對應值 (second)`
    * `public double push_interval` : Unit is `second`.
    * `public Map<String, String> interval`格式，對應值單位為`秒`，**注意 : 後方秒數為String格式** : 
```java=
public Map<String, String> interval = new HashMap<String, String>() {{
    put("<IDF1 name>", "<second>");
    put("<IDF2 name>", "<second>");
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
**`<ODF name>`必需和iottalk上的名稱相同。**
```java=
public DeviceFeature <ODF name> = new DeviceFeature("<ODF name>", "odf"){
    @Override
        public void onData(MqttMessage message, String df_name, String df_type){
            //Callback function body...
        }
};
```
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

### 其他Callback function
以下4個callback會在對應的時機被DAN呼叫，若有需求，可自行宣告。
* `public void on_register()`
* `public void on_deregister()`
* `public void on_connect()`
* `public void on_disconnect()`

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
