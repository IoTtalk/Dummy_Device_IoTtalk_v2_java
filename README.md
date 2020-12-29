# Dummy Device for IoTtalk v2 (Java)

* Modify your setting at `src/iottalk/SA.java`

* Get/Update iottalk.jar file by
  ```bash=
  chmod +x get_iottalk_jar.sh
  ./update_iottalk_jar.sh
  ```

* Compile by 
  ```bash=
  mkdir bin
  javac -cp "libs/*" -d bin src/iottalk/*
  ```

* Run by
  ```bash=
  java -cp "bin:libs/*" iottalk.Main
  ```
