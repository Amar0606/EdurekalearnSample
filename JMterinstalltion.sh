#!/bin/bash
set -e

# ==============================
# Configurable variables
# ==============================
JMETER_VERSION="5.6.3"
JMETER_INSTALL_DIR="/opt"
JMETER_HOME="${JMETER_INSTALL_DIR}/apache-jmeter-${JMETER_VERSION}"
JMETER_DOWNLOAD_URL="https://downloads.apache.org/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz"
JAVA_VERSION ="17"

# JMeter Plugins Manager and cmdrunner
PLUGINS_MANAGER_JAR_URL="https://jmeter-plugins.org/get/"
CMDRUNNER_JAR_URL="https://repo1.maven.org/maven2/kg/apc/cmdrunner/2.2.1/cmdrunner-2.2.1.jar"

# Plugins to install:
# jpgc-dummy     -> Dummy Sampler
# jpgc-functions -> Custom Functions
# jpgc-casutg    -> Custom Thread Groups
JMETER_PLUGINS="jpgc-dummy,jpgc-functions,jpgc-casutg"

echo "============================="
echo " Updating apt and installing prerequisites"
echo "============================="
sudo apt-get update -y
sudo apt-get install -y wget curl tar gnupg software-properties-common

echo "============================="
echo " Installing Java (OpenJDK 11)"
echo "============================="
sudo apt-get install -y openjdk-${JAVA_VERSION}-jdk

echo "Java version:"
java -version || echo "Java not installed correctly!"

echo "============================="
echo " Downloading Apache JMeter ${JMETER_VERSION}"
echo "============================="

sudo mkdir -p "${JMETER_INSTALL_DIR}"
cd /tmp

if [ ! -f "apache-jmeter-${JMETER_VERSION}.tgz" ]; then
  wget "${JMETER_DOWNLOAD_URL}"
fi

echo "============================="
echo " Extracting JMeter to ${JMETER_INSTALL_DIR}"
echo "============================="
sudo tar -xzf "apache-jmeter-${JMETER_VERSION}.tgz" -C "${JMETER_INSTALL_DIR}"

# Change ownership to current user so you can edit files without sudo
sudo chown -R "$USER":"$USER" "${JMETER_HOME}"

echo "============================="
echo " Creating jmeter symlink in /usr/local/bin"
echo "============================="
if [ ! -L /usr/local/bin/jmeter ]; then
  sudo ln -s "${JMETER_HOME}/bin/jmeter" /usr/local/bin/jmeter
fi

echo "JMeter version:"
jmeter -v || echo "JMeter not found in PATH!"

echo "============================="
echo " Installing JMeter Plugins Manager and cmdrunner"
echo "============================="
mkdir -p "${JMETER_HOME}/lib/ext"
mkdir -p "${JMETER_HOME}/lib"

# Download Plugin Manager JAR
wget -O "${JMETER_HOME}/lib/ext/jmeter-plugins-manager.jar" "${PLUGINS_MANAGER_JAR_URL}"

# Download cmdrunner JAR (2.2.1 recommended)
wget -O "${JMETER_HOME}/lib/cmdrunner-2.2.1.jar" "${CMDRUNNER_JAR_URL}"

echo "============================="
echo " Creating PluginsManagerCMD.sh via PluginManagerCMDInstaller"
echo "============================="
(
  cd "${JMETER_HOME}"
  java -cp "lib/ext/jmeter-plugins-manager.jar" \
    org.jmeterplugins.repository.PluginManagerCMDInstaller
)

# Make sure the script is executable
chmod +x "${JMETER_HOME}/bin/PluginsManagerCMD.sh"

echo "============================="
echo " Installing JMeter plugins: ${JMETER_PLUGINS}"
echo "============================="
"${JMETER_HOME}/bin/PluginsManagerCMD.sh" install ${JMETER_PLUGINS}

echo "============================="
echo " Installation complete!"
echo " JMeter home: ${JMETER_HOME}"
echo " Run JMeter with: jmeter"
echo "============================="
