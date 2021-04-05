# Dummy Device for IoTtalk v2 (Java)

## 需要的函式庫
使用指令 `make check_jar` 會自動下載所需 jar 的預設版本。
### iottalk.jar
* [原始碼連結](https://github.com/IoTtalk/iottalk-java)
* 更新最新版的 iottalk.jar : `make update_iottalk_jar`

### 其他的Maven函式庫
* [org.json](https://mvnrepository.com/artifact/org.json/json) : 版本需求 >= 20131018
* [org.eclipse.paho.client.mqttv3](https://mvnrepository.com/artifact/org.eclipse.paho/org.eclipse.paho.client.mqttv3/1.2.5) : 版本需求 >= 1.2.5

## 如何使用
1. 在 `src/SA.java` 裡面修改設定
    * 如果只是想跑 `Dummy Device`，可以設定 `src/SA.java` 中的 `api_url` 即可。
    * 如果要修改其他設定，請看 [詳細說明](#SA-說明)
2. 編譯 : `make compile`
3. 執行 : `make run` ( 用此方法會自動以 bin/SA.class 為SA的目標 )
   * 若想要執行的 SA 檔案名稱並非 `SA.java`，可以使用 `make run SA=<SA class file path>`， ex : `make run SA=bin/EventDriven.class`。
* 若想要更新所有的 jar 檔，可執行 `make update_iottalk_jar`。
* 如果需要在 DAI 後另外執行自定義的 Thread，可以參考 [這裡](#EventDriven介紹)
* 如果想要撰寫自己的 DAI ，可以看 [這裡](https://github.com/IoTtalk/iottalk-java) 有詳細說明。

## SA 說明
### 變數說明
* `public String api_url` : csm的url。 ex : `"http://localhost:9992/csm"`
* `public String device_model` : Device Model名稱。 ex : `"Dummy Device"`
* `public String device_name` : Device 的名稱，就是顯示在 iottalk GUI 上的名稱。 ex : `"Dummy_test"`
* `public String username` (OPTIONAL) : 設為某 user private 使用。
* `public String device_addr` (OPTIONAL) : 設定自訂的 UUID，需為 Hex String。 ex: `"aaaaa1234567890abcdef"`。
* `public boolean persistent_binding` (OPTIONAL) : 若為 `true`，DAN 將不會在 disconnect 後註銷該 Device，在 project 中的 binding 會被保留，下次此 Device 重連時，會自動 bind 上。**注意 : 設為 `true` 時，必需設定 `device_addr` 值!**

### Device Feature設定
IDF 與 ODF 設定需要用 `DeviceFeature` 這個 class 定義
IDF
---

```java=
public DeviceFeature <IDF object name> = new DeviceFeature("<IDF name>", "idf"){
    @Override
    public JSONArray getPushData() throws JSONException{
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
* **`<IDF object name>` 建議與 `<IDF name>` 相同，若 `<IDF name>` 中含有 `+`, `-` 等符號，可以將其改成 ` _ ` 。
* IDF 需要 override `public JSONArray getPushData()` 這個 function，DAI 會依照 push interval 的設定，定期像 server push 資料。
* Example
```java=
public DeviceFeature Dummy_Sensor = new DeviceFeature("Dummy_Sensor", "idf"){
    @Override
    public JSONArray getPushData() throws JSONException{
        int max = 100;
        int min = 1;
        int randomNum = min + (int)(Math.random() * ((max-min) + 1));
        int [] pushData = {randomNum};
        JSONArray r = new JSONArray(pushData);
        return r;
    }
};
```

* Push Interval 設定，DAI 會依據 `public double push_interval`, `public Map<String, Double> interval` 中的值，決定 push 資料的週期。
    * 每個 IDF push data 週期 = 如果 `interval` 中存在對應值，就使用該數值；若不存在就使用 `push_interval` 的數值。
    * `public double push_interval` : 單位為 `秒`。
    * `public Map<String, Double> interval` 格式，對應值單位為 `秒` : 
```java=
public Map<String, Double> interval = new HashMap<String, Double>() {{
    put("<IDF1 name>", new Double(<second>));
    put("<IDF2 name>", new Double(<second>));
    ...
}};
```
Example : 
此範例中，`Dummy_Sensor` push data 週期為 `0.6` 秒
```java=
public double push_interval = 2;

public Map<String, String> interval = new HashMap<String, String>() {{
    put("Dummy_Sensor", "0.3");  //assign feature interval
}};
```

ODF
---

```java=
public DeviceFeature <ODF object name> = new DeviceFeature("<ODF name>", "odf"){
    @Override
        public void pulDataCB(MqttMessage message, String df_name, String df_type){
            //Callback function body...
        }
};
```
* **`<ODF name>`必需和iottalk上的名稱相同。**
* **`<ODF object name>` 建議與 `<ODF name>` 相同，若 `<ODF name>` 中含有 `+`, `-` 等符號，可以將其改成 ` _ ` 。
* ODF 需要 override `public void pulDataCB(MqttMessage message, String df_name, String df_type)` 這個 function，當 ODF 值有更新時，此 function 會被呼叫，且可以在 `message` 中得到更新值。
* Example
```java=
public DeviceFeature Dummy_Control = new DeviceFeature("Dummy_Control", "odf"){
    @Override
    public void pulDataCB(MqttMessage message, String df_name, String df_type){
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
* `public void on_register()` : 在 `DAN` 註冊 Device 完成後會執行。
* `public void on_deregister()` : 在 `DAN` 註銷 Device 完成後會執行。
* `public void on_connect()` : 在 `DAN` 與 server 建立連線後會執行。
* `public void on_disconnect()` : 在 `DAN` 與 server 正常終止連線後會執行(意外終止則不會)。

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

## EventDriven 介紹
* 如果需要在 DAI 後另外執行自定義的 Thread，可以參考以下說明。
* 範例檔參考 `src/EventDriven.java`。
### Thread 物件建立
可以自行在 SA 中宣告，或是參考以下範例格式
```java
public class FuncThread extends Thread{
     public DAN dan;

     public void push(String idfName, JSONArray data) throws Exception{
         try{
             dan.push(idfName, data);
         } catch (Exception e){
             throw e;
         }
     }
 }
 public FuncThread funcThread1 = new FuncThread(){
     @Override
     public void run(){
         try{
             while (true){
                  // Your instructions ...
                 java.util.concurrent.TimeUnit.MILLISECONDS.sleep(500);
             }
         } catch(Error e){
             e.printStackTrace();
         } catch(Exception e){
             e.printStackTrace();
         }    
     }
 };
```

### Thread 的啟動與終止
啟動與終止需寫在 [Callback function](#Callback-function) 中。

#### 紀錄 DAN
由於在執行的過程，你可能會需要呼叫 DAN 的一些功能，像是 `push`，請在 `on_register` 完成
注意 ! 需將 `public void on_register()` 修改為 `public void on_register(DAN dan)`
```java
public void on_register(DAN dan){
     funcThread1.dan = dan;
     System.out.println("register successfully");
 }
```

#### 啟動
可以在 `on_register` 或是 `on_connect` 中宣告
```java
public void on_connect(){
     funcThread1.start();
     System.out.println("connect successfully");
 }
```

#### 終止
請在`on_disconnect` 中終止所有的 thread 。別寫在 `on_deregister` 中，因為 `on_deregister` 不一定會被觸發。
```java
public void on_disconnect(){
     funcThread1.interrupt();
     System.out.println("disconnect successfully");
 }
```
