#!/usr/bin/env bash

set -e

run() {
  local jenkinsfile="${1}"
  local pluginstxt="${2}"
  local command="${3}"

  if [[ ! -f ${jenkinsfile} ]]; then
      echo "jenkinsfile ${jenkinsfile} doesnt exist"
      exit 1
  fi

  if [[ ! -f ${pluginstxt} ]]; then
      echo "pluginstxt ${pluginstxt} doesnt exist"
      exit 1
  fi

  plugin_manager_ver=$(java -jar /app/bin/jenkins-plugin-manager.jar --version)
  runner_ver=$(/app/bin/jenkinsfile-runner-launcher --version)
  echo "jenkins-plugin-manager: ${plugin_manager_ver}"
  echo "jenkinsfile-runner: ${runner_ver}"

  echo
  echo "java -jar /app/bin/jenkins-plugin-manager.jar --war /app/jenkins-${JENKINS_VERSION}.war --plugin-file ${pluginstxt} --plugin-download-directory=/usr/share/jenkins/ref/plugins"
  java -jar /app/bin/jenkins-plugin-manager.jar --war /app/jenkins-${JENKINS_VERSION}.war --plugin-file ${pluginstxt} --plugin-download-directory=/usr/share/jenkins/ref/plugins

  echo
  ls -lrt /usr/share/jenkins/ref/plugins

  echo
  echo "/app/bin/jenkinsfile-runner-launcher ${command} --jenkins-war=/app/jenkins-${JENKINS_VERSION} --file=${jenkinsfile} --plugins=/usr/share/jenkins/ref/plugins"
  /app/bin/jenkinsfile-runner-launcher ${command} --jenkins-war=/app/jenkins-${JENKINS_VERSION} --file=${jenkinsfile} --plugins=/usr/share/jenkins/ref/plugins
}

run "${1}" "${2}" "${3}"