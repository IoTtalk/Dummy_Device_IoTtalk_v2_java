# Dummy Device for IoTtalk v2 (Java)

## 環境需求
* git
* make
* [OpenJDK](https://openjdk.java.net/install/) : JDK 版本需求 >= 8
* 需要的 jar 函式庫 <br> **使用指令 `make check_jar` 會自動下載所需 jar 的預設版本至 `./lib` 資料夾。**
   * [iottalk](https://github.com/IoTtalk/iottalk-java)
   * [org.json](https://mvnrepository.com/artifact/org.json/json) : 版本需求 >= 20131018 , 預設版本 : 20210307
   * [org.eclipse.paho.client.mqttv3](https://mvnrepository.com/artifact/org.eclipse.paho/org.eclipse.paho.client.mqttv3/1.2.5) : 版本需求 >= 1.2.5 , 預設版本 : 1.2.5

## 如何使用
1. 在 `src/SA.java` 裡面修改設定
    * 如果只是想跑 `Dummy Device`，可以設定 `src/SA.java` 中的 `api_url` 即可。
    * 如果要修改其他設定，請看 [進階使用 - SA 說明](#SA-說明)。
2. 編譯 : `make compile`
3. 執行 : `make run` ( 用此方法會自動以 bin/SA.class 為SA的目標 )
   * 若想要執行的 SA 檔案名稱並非 `SA`，可以使用 `make run SA=<SA class file path>`
   * 範例 : `make run SA=bin/EventDriven.class`

## 進階使用
* [SA 中其他變數的說明](#SA-說明)
* 如果想要更新所有的 jar 檔，可執行 `make update_jar` 。使用 `make check_jar` 只會檢查是否存在可用的 jar 檔，並不會更新至最新。
* 如果需要在 DAI 註冊後，另外執行自定義的 Thread，可以參考 [EventDriven 介紹](#EventDriven-介紹)。
* 如果想要撰寫自己的 DAI ，可以看 [iottalk-java](https://github.com/IoTtalk/iottalk-java) 的說明。

### SA 說明
#### 基本變數說明
* `public String api_url` : IoTtalk csm 的 url。 範例 : `"http://localhost:9992/csm"`
* `public String device_model` : Device Model 名稱。 範例 : `"Dummy Device"`
* `public String device_name` : Device 的名稱，就是顯示在 iottalk GUI 上的名稱。 範例 : `"Dummy_test"`
* `public String username` (OPTIONAL) : 設為某 user private 使用。
* `public String device_addr` (OPTIONAL) : 設定自訂的 UUID，需為 Hex String。 範例 : `"aaaaa1234567890abcdef"`。
* `public boolean persistent_binding` (OPTIONAL) : 若為 `true`，DAN 將不會在 disconnect 後註銷該 Device，在 project 中的 binding 會被保留，下次此 Device 重連時，會自動 bind 上。**注意 : 設為 `true` 時，必需設定 `device_addr` 值並且保持固定不可修改!**

#### Device Feature設定
IDF 與 ODF 設定需要用 `DeviceFeature` 這個 class 定義

**IDF**

  ```java
  public DeviceFeature <IDF object name> = new DeviceFeature("<IDF name>", "idf"){
      @Override
      public JSONArray getPushData() throws JSONException{
          //Create push data...

          return new JSONArray(pushData);
      }
  };
  ```
* **`<IDF name>`必需和iottalk上的名稱相同。**
* **`<IDF object name>` 建議與 `<IDF name>` 相同**，若 `<IDF name>` 中含有 `+`, `-` 等符號，可以將其改成 ` _ ` 。
* IDF 需要 override `public JSONArray getPushData()` 這個 function，DAI 會依照 push interval 的設定，定期向 server push 資料。
* Push Interval : DAI push 資料的週期。
  * DAI 會依以下順序來決定 push 資料的週期
    1. `public Map<String, Double> interval` 中對應的值。
    2. `public double push_interval` 的值。
  * `public Map<String, Double> interval` : 單位為 `秒`，此變數以鍵值對記錄個別 IDF push interval 的值。
  * `public double push_interval` : 單位為 `秒`，此變數為 push interval 的 global 預設值。
   
  ```java
  public double push_interval = <global push interval value>;
  public Map<String, Double> interval = new HashMap<String, Double>() {{
      put("<IDF1 name>", new Double(<second>));
      put("<IDF2 name>", new Double(<second>));
      ...
  }};
  ```
  
* 範例 <br>
此範例中，`Dummy_Sensor` 回傳 1 ~ 100 的整數亂數， push data 的週期為 0.3 秒
  ```java
  public DeviceFeature Dummy_Sensor = new DeviceFeature("Dummy_Sensor", "idf"){
      @Override
      public JSONArray getPushData() throws JSONException{
          //Change data into JSONArray
          //int [] pushData = {1};
          //double [] pushData = {1.1};
          //String [] pushData = {"push data"};
          int max = 100;
          int min = 1;
          int randomNum = min + (int)(Math.random() * ((max-min) + 1));
          int [] pushData = {randomNum};
          JSONArray r = new JSONArray(pushData);
          return r;
      }
  };

  public double push_interval = 2;

  public Map<String, String> interval = new HashMap<String, String>() {{
      put("Dummy_Sensor", "0.3");  //assign feature interval
  }};
  ```

**ODF**

  ```java
  public DeviceFeature <ODF object name> = new DeviceFeature("<ODF name>", "odf"){
      @Override
          public void pullDataCB(MqttMessage message, String df_name){
              //Callback function body...
          }
  };
  ```
* **`<ODF name>` 必需和 iottalk 上的名稱相同。**
* **`<ODF object name>` 建議與 `<ODF name>` 相同**，若 `<ODF name>` 中含有 `+`, `-` 等符號，可以將其改成 ` _ ` 。
* ODF 需要 override `public void pullDataCB(MqttMessage message, String df_name)` 這個 function，當 ODF 值有更新時，此 function 會被呼叫，且可以在 `message` 中得到更新值。
* 範例
  ```java
  public DeviceFeature Dummy_Control = new DeviceFeature("Dummy_Control", "odf"){
      @Override
      public void pullDataCB(MqttMessage message, String df_name){
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

#### Callback functions
* 以下 4 個 callback 會在對應的時機被程式自動呼叫，若有需求，可自行宣告。
  * `public void on_register()` : 在 Device 註冊 Device 完成後會執行。
  * `public void on_deregister()` : 在 Device 註銷 Device 完成後會執行。
  * `public void on_connect()` : 在 Device 與 server 建立連線後會執行。
  * `public void on_disconnect()` : 在 Device 與 server 正常終止連線後會執行(意外終止則不會)。

* 範例
  ```java
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

### EventDriven 介紹
* 如果需要在 Device 自動執行後另外執行自定義的 Thread，可以參考以下說明。
* 參考範例檔 : `src/EventDriven.java`
* 編譯 : `make compile`
* 執行 : `make run SA=bin/EventDriven.class`
#### Thread 物件建立
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

**注意 : thread 若使用 while 迴圈，務必加上 `sleep`** ，否則會無法被 `interrupt` 中止。

#### 啟動與終止自定義的 Thread
1. 取得 DAN 物件 (非必要)
2. 啟動 thread
3. 中止 thread
需寫在正確的 [Callback function](#Callback-function) 中，已確定程式行為正確。

**取得 DAN 物件 (非必要)**

* 在執行的過程，你可能會需要呼叫 DAN 的一些功能，像是 `push` 來自行發送資料。
* 需在 `on_register()` 中紀錄 DAN 物件。為了取得註冊後的 dan 物件，請將 `public void on_register()` 修改為 `public void on_register(DAN dan)`
* 範例
  ```java
  public void on_register(DAN dan){
     funcThread1.dan = dan;
     System.out.println("register successfully");
  }
  ```

**啟動**


* 可以在 `on_register` 或是 `on_connect` 中啟動 thread ，建議寫在 `on_connect` 中。 <br>
* 範例
  ```java
  public void on_connect(){
     funcThread1.start();
     System.out.println("connect successfully");
  }
  ```

**終止**

* 請在`on_disconnect` 中終止所有的 thread 。**不要**寫在 `on_deregister` 中，因為 `on_deregister` 不一定會被觸發。
* 範例
  ```java
  public void on_disconnect(){
     funcThread1.interrupt();
     System.out.println("disconnect successfully");
  }
  ```
