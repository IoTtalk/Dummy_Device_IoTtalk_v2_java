JAVA = java
JC = javac

BIN_DIR = bin
SRC_DIR = src
LIB_DIR = libs

SRCS = $(wildcard $(SRC_DIR)/SA.java)
CPFLAG = -cp "libs/*"
DFLAG = -d $(BIN_DIR)

JSON_JAR_URL = https://repo1.maven.org/maven2/org/json/json/20201115/json-20201115.jar
PAHO_JAR_URL = https://repo.eclipse.org/content/repositories/paho-releases/org/eclipse/paho/org.eclipse.paho.client.mqttv3/1.2.5/org.eclipse.paho.client.mqttv3-1.2.5.jar
IOTTALK_JAR_REPO = https://github.com/EricPwg/iottalk-java

JSON_JAR_NAME = $(LIB_DIR)/json-20201115.jar
PAHO_JAR_NAME = $(LIB_DIR)/org.eclipse.paho.client.mqttv3-1.2.5.jar
IOTTALK_JAR_NAME = $(LIB_DIR)/iottalk.jar

JAR_FILES = $(JSON_JAR_NAME) $(PAHO_JAR_NAME) $(IOTTALK_JAR_NAME)

all:
	make check_jar
	$(JAVA) $(CPFLAG) iottalk.DAI $(SA)

update_jar: $(JAR_FILES)
	echo 2

compile: $(BIN_DIR)/SA.class

run: $(BIN_DIR)/SA.class
	make check_jar
	$(JAVA) $(CPFLAG) iottalk.DAI $(BIN_DIR)/SA.class

$(BIN_DIR)/SA.class: $(BIN_DIR) $(SRCS)
	make check_jar
	$(JC) $(CPFLAG) $(DFLAG) $(SRCS)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

check_jar: $(JSON_JAR_NAME) $(PAHO_JAR_NAME) $(IOTTALK_JAR_NAME)

$(JSON_JAR_NAME):
	@if [ ! -f $(JSON_JAR_NAME) ]; then \
	  wget $(JSON_JAR_URL) -P $(LIB_DIR);\
	fi

$(PAHO_JAR_NAME):
	@if [ ! -f $(PAHO_JAR_NAME) ]; then\
	  wget $(PAHO_JAR_URL) -P $(LIB_DIR); \
	fi

$(IOTTALK_JAR_NAME):
	@if [ ! -f $(IOTTALK_JAR_NAME) ]; then\
	  make update_iottalk.jar; \
	fi

update_iottalk.jar:
	@if [ -f "$(IOTTALK_JAR_NAME)" ] ; then rm $(IOTTALK_JAR_NAME); fi
	@if [ -d "iottalk-java" ] ; then rm -rf iottalk-java; fi
	git clone $(IOTTALK_JAR_REPO)
	cd iottalk-java; \
	make iottalk.jar; \
	mv iottalk.jar ../libs; \
	cd ..
	rm -rf iottalk-java
