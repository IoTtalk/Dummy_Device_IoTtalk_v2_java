git clone https://github.com/IoTtalk/iottalk-java
mkdir iottalk-java/bin
javac -cp "iottalk-java/libs/*" -d iottalk-java/bin/ iottalk-java/src/iottalk/*
cd iottalk-java/bin
jar cvf iottalk.jar iottalk/*
cd ../..
mv iottalk-java/bin/iottalk.jar libs
rm -rf iottalk-java
