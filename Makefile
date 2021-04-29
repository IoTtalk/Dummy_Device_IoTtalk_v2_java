JSON_JAR_DEFAULT_VERSION := 20210307
PAHO_JAR_DEFAULT_VERSION := 1.2.5
SHELL := /bin/bash

JAVA = java
JC = javac

BIN_DIR = bin
SRC_DIR = src
LIB_DIR = libs

SA = $(BIN_DIR)/SA.class

SRCS = $(wildcard $(SRC_DIR)/*.java)
CLASSES = $(SRCS:$(SRC_DIR)/%.java=$(BIN_DIR)/%.class)
CPFLAG = -cp "libs/*"
DFLAG = -d $(BIN_DIR)

JSON_JAR_URL_BASE = https://repo1.maven.org/maven2/org/json/json
PAHO_JAR_URL_BASE = https://repo.eclipse.org/content/repositories/paho-releases/org/eclipse/paho/org.eclipse.paho.client.mqttv3

JSON_JAR_MVN = $(JSON_JAR_URL_BASE)/maven-metadata.xml
PAHO_JAR_MVN = $(PAHO_JAR_URL_BASE)/maven-metadata.xml

JSON_JAR_NAME_BASE = json
PAHO_JAR_NAME_BASE = org.eclipse.paho.client.mqttv3

JSON_JAR_URL = $(JSON_JAR_URL_BASE)/$(JSON_JAR_DEFAULT_VERSION)/$(JSON_JAR_NAME_BASE)-$(JSON_JAR_DEFAULT_VERSION).jar
PAHO_JAR_URL = $(PAHO_JAR_URL_BASE)/$(PAHO_JAR_DEFAULT_VERSION)/$(PAHO_JAR_NAME_BASE)-$(PAHO_JAR_DEFAULT_VERSION).jar
IOTTALK_JAR_REPO = https://github.com/EricPwg/iottalk-java

JSON_JAR_NAME = $(LIB_DIR)/$(JSON_JAR_NAME_BASE)-$(JSON_JAR_DEFAULT_VERSION).jar
PAHO_JAR_NAME = $(LIB_DIR)/$(PAHO_JAR_NAME_BASE)-$(PAHO_JAR_DEFAULT_VERSION).jar
IOTTALK_JAR_NAME = $(LIB_DIR)/iottalk.jar

RDOM = rdom () { local IFS=\> ; read -d \< E C ;};
CHECK = $(RDOM) while rdom; do if [[ $$E = "release" ]]; then echo $$C; fi done

.PHONY : run clean $(wildcard check_*_jar) $(wildcard update_*_jar)

run: check_jar
	$(JAVA) $(CPFLAG) iottalk.DAI $(SA)

compile: check_jar $(CLASSES)

clean:
	rm $(LIB_DIR)/.maventmp

$(CLASSES): $(BIN_DIR) $(SRCS)
	$(JC) $(CPFLAG) $(DFLAG) $(SRCS)

check_jar: check_json_jar check_paho_jar check_iottalk_jar

check_json_jar: $(LIB_DIR)
	@if [ ! -f $(LIB_DIR)/$(JSON_JAR_NAME_BASE)* ]; then \
	  wget $(JSON_JAR_URL) -P $(LIB_DIR);\
	else echo Found json jar in $(LIB_DIR)/;\
	fi

check_paho_jar: $(LIB_DIR)
	@if [ ! -f $(LIB_DIR)/$(PAHO_JAR_NAME_BASE)* ]; then\
	  wget $(PAHO_JAR_URL) -P $(LIB_DIR); \
	  else echo Found paho jar in $(LIB_DIR)/;\
	fi

check_iottalk_jar: $(LIB_DIR)
	@if [ ! -f $(IOTTALK_JAR_NAME) ]; then\
	  make update_iottalk_jar; \
	  else echo Found iottalk jar in $(LIB_DIR)/;\
	fi

update_jar: update_json_jar update_paho_jar update_iottalk_jar

update_json_jar: $(LIB_DIR)
	$(shell wget $(JSON_JAR_MVN) -O $(LIB_DIR)/.maventmp )
	$(eval JSON_VERSION = $(shell $(CHECK) < $(LIB_DIR)/.maventmp ))
	$(eval JSON_JAR_NAME = $(LIB_DIR)/$(JSON_JAR_NAME_BASE)-$(JSON_VERSION).jar)
	$(eval JSON_JAR_URL = $(JSON_JAR_URL_BASE)/$(JSON_VERSION)/$(JSON_JAR_NAME_BASE)-$(JSON_VERSION).jar)
	@if [ ! -f $(JSON_JAR_NAME) ]; then \
	  rm $(LIB_DIR)/$(JSON_JAR_NAME_BASE)-*.jar*; \
	  wget $(JSON_JAR_URL) -P $(LIB_DIR);\
	fi

update_paho_jar: $(LIB_DIR)
	$(shell wget $(PAHO_JAR_MVN) -O $(LIB_DIR)/.maventmp)
	$(eval PAHO_VERSION = $(shell $(CHECK) < $(LIB_DIR)/.maventmp ))
	$(eval PAHO_JAR_NAME = $(LIB_DIR)/$(PAHO_JAR_NAME_BASE)-$(PAHO_VERSION).jar)
	$(eval PAHO_JAR_URL = $(PAHO_JAR_URL_BASE)/$(PAHO_VERSION)/$(PAHO_JAR_NAME_BASE)-$(PAHO_VERSION).jar)
	@if [ ! -f $(PAHO_JAR_NAME) ]; then \
	  rm $(LIB_DIR)/$(PAHO_JAR_NAME_BASE)-*.jar*; \
	  wget $(PAHO_JAR_URL) -P $(LIB_DIR);\
	fi
    
update_iottalk_jar: $(LIB_DIR)
	@if [ -f "$(IOTTALK_JAR_NAME)" ] ; then rm $(IOTTALK_JAR_NAME); fi
	@if [ -d "iottalk-java" ] ; then rm -rf iottalk-java; fi
	git clone $(IOTTALK_JAR_REPO)
	cd iottalk-java; \
	make iottalk.jar; \
	mv iottalk.jar ../libs; \
	cd ..
	rm -rf iottalk-java

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(LIB_DIR):
	mkdir -p $(LIB_DIR)
