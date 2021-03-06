import iottalk.DeviceFeature;
import iottalk.DAN;
import iottalk.DAI;

import java.lang.Math;
import java.lang.Thread;

import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;

import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.MqttException;

import java.util.Timer;
import java.util.TimerTask;

public class EventDriven{
    // The registeration api url, you can use IP or Domain.
    public String api_url = "http://localhost:9992/csm";
    
    // The Device Model in IoTtalk, please check IoTtalk document.
    public String device_model = "Dummy_Device";
    
    // [OPTIONAL] If not given or None, server will auto-generate.
    public String device_name = "Dummy_test";
    
    /*
    [OPTIONAL] If not given or None, DAN will register using a random UUID.
    Or you can use following code to set your own device_addr.
    This String MUST be a hex-string
    */
    // public String device_addr = "1234567890abedef"; //for example
    
    /*
    [OPTIONAL] If the device_addr is set as a fixed value, user can enable
    this option and make the DA register/deregister without rebinding on GUI
    */
    // public boolean persistent_binding = true;


    // [OPTIONAL] If not given or None, this device will be used by anyone.
    // public String username = "User-Name";
    
    
    //Set IDFs in this format
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
    
    //Set ODFs in this format
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
    
    /*
    Set the push interval, default = 1 (sec)
    Or you can set to 0, and control in your feature input function.
    */
    public double push_interval = 1;
    
    public Map<String, Double> interval = new HashMap<String, Double>() {{
        put("Dummy_Sensor", new Double(2.0));  //assign feature interval
    }};
    
    /*
    Set your own FuncThread
    Remember to set 
        dan/dai object     in callback function on_register
        thread.start()     in callback function on_connect or on_register
        thread interrput() in callback function on_disconnect
    */
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
                    int max = 1;
                    int min = -100;
                    int randomNum = min + (int)(Math.random() * ((max-min) + 1));
                    int [] pushData = {randomNum};
                    JSONArray r = new JSONArray(pushData);
                    push("Dummy_Sensor", r);
                    System.out.println("User define's FuncThread");
                    java.util.concurrent.TimeUnit.MILLISECONDS.sleep(500);
                }
            } catch(Error e){
                e.printStackTrace();
            } catch(Exception e){
                e.printStackTrace();
            }    
        }
    };
    
    /*
    [OPTIONAL] Set your own callback function if needed
    */
    
    //invoke after DAN finish register
    public void on_register(DAN dan){
        funcThread1.dan = dan;
        System.out.println("register successfully");
    }
    
    //invoke after DAN finish deregister
    public void on_deregister(){
        System.out.println("deregister successfully");
    }
    
    //invoke after DAN finish connect to server
    public void on_connect(){
        funcThread1.start();
        System.out.println("connect successfully");
    }
    
    //invoke after DAN finish disconnect to server, but NOT INCLUDED unexpected disconnection
    public void on_disconnect(){
        funcThread1.interrupt();
        System.out.println("disconnect successfully");
    }
    
}
