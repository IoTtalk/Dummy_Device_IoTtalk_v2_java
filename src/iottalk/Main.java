package iottalk;

import sun.misc.Signal;
import sun.misc.SignalHandler;

import java.util.logging.Logger;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import java.lang.Thread;

import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.MqttException;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.InterruptedIOException;

import java.net.URL;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;


import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

public class Main{
    
    public static void main(String[] args)throws Exception{
        SA sa = new SA();
        DAI dai = new DAI(sa);
        //Set signal handler to catch Ctrl+C
        Signal.handle(new Signal("INT"), new SignalHandler() {
            public void handle(Signal sig) {
                System.out.println("Interrupt");
                dai.terminate();
            }
        });
        dai.start();
        dai.join();
    }
}