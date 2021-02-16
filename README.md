# GitHub Actions POC for Jenkins Single-shot master

![Docker](https://github.com/jenkinsci/jenkinsfile-runner-github-actions/workflows/Docker/badge.svg)
[![GitHubActions](https://img.shields.io/badge/listed%20on-GitHubActions-blue.svg)](https://github-actions.netlify.com/jenkins-single-shot)

This is a POC how to run _Jenkinsfiles_ inside [GitHub Actions](https://github.blog/2019-08-08-github-actions-now-supports-ci-cd/) - [GitHub's built-in CI/CD](https://github.com/features/actions) using embedded [Jenkins Single-shot masters](https://schd.ws/hosted_files/devopsworldjenkinsworld2018/8f/DWJW2018%20-%20A%20Cloud%20Native%20Jenkins.pdf).

![image](https://user-images.githubusercontent.com/1872314/62877764-0ca51e00-bd28-11e9-9f6e-afb3ee77c4f9.png)

![image](https://user-images.githubusercontent.com/1872314/47345918-3b280e80-d6ac-11e8-9f44-8cc02754f691.png)


Any GitHub project with a ```Jenkinsfile```can use those actions to execute its defined workflow inside a Docker container run by GitHub that spawns up a new Jenkins master, executes the tests and exits.

The commit that triggered the GitHub Action is [automatically mapped](https://help.github.com/en/articles/virtual-environments-for-github-actions#filesystems-on-github-hosted-machines) to ```/github/workspace``` in the Jenkins Docker container. Test results are reported back to the corresponding pull requests.

![image](https://user-images.githubusercontent.com/1872314/62881120-4fb6bf80-bd2f-11e9-8609-3f906b2c00f3.png)

![image](https://user-images.githubusercontent.com/1872314/62953641-2d37ab80-bdee-11e9-8624-1ce4bf413b07.png)



## Available GitHub Action

The POC comes with one action:

#### [jenkinsfile-runner-prepackaged](https://github.com/jenkinsci/jenkinsfile-runner-github-actions/tree/master/jenkinsfile-runner-prepackaged)

Uses the [official Jenkinsfile-Runner](https://github.com/jenkinsci/jenkinsfile-runner) and prepackages Jenkins 2.138.2 and Maven 3.5.2 with it. There is also a [Dockerfile](https://hub.docker.com/r/jonico/jenkinsfile-runner-prepackaged/) available you could refer to in [your workflow](https://help.github.com/articles/about-github-actions/#about-workflows) if you do not like to [refer to the source](https://github.com/jenkinsci/jenkinsfile-runner-github-actions/tree/master/jenkinsfile-runner-prepackaged).

## How to use the action

Here is an example [GitHub Action workflow](https://help.github.com/en/articles/configuring-a-workflow) that shows how to use the action:

```yaml
on: push
name: Jenkins single-shot master
jobs:
  jenkinsfile-runner-prepackaged:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: jenkinsfile-runner-prepackaged
      uses: jenkinsci/jenkinsfile-runner-github-actions/jenkinsfile-runner-prepackaged@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## An example Jenkinsfile that was tested with this

```groovy
#!groovy
import groovy.json.JsonOutput

node {
    // pull request or feature branch
    if  (env.GITHUB_REF != 'refs/heads/master') {
        checkoutSource()
        build()
        unitTest()
    } // master branch / production
    else {
        checkoutSource()
        build()
        allTests()
        createRelease("${env.GITHUB_ACTION}-${env.GITHUB_SHA}")
    }
}

def createRelease(name) {
  stage ('createRelease') {
        def payload = JsonOutput.toJson(["tag_name": "v-${name}", "name": "GitHub Action triggered release: ${name}", "body": "This release has been created with the help of a Jenkins single-shot master running inside of a GitHub Action. For more details visit https://github.com/jonico/jenkinsfile-runner-github-actions"])
        def apiUrl = "https://api.github.com/repos/${env.GITHUB_REPOSITORY}/releases"
        mysh("curl -s --output /dev/null -H \"Authorization: Token ${env.GITHUB_TOKEN}\" -H \"Accept: application/json\" -H \"Content-type: application/json\" -X POST -d '${payload}' ${apiUrl}")
    }
}

// prevent output of secrets and a globbing patterns by Jenkins
def mysh(cmd) {
    sh('#!/bin/sh -e\n' + cmd)
}

def checkoutSource() {
  stage ('checkoutSource') {
    // as the commit that triggered that Jenkins action is already mapped to /github/workspace, we just copy that to the workspace
    copyFilesToWorkSpace()
  }
}

def copyFilesToWorkSpace() {
  mysh "cp -r /github/workspace/* $WORKSPACE"
}

def build () {
    stage ('Build') {
      mvn 'clean install -DskipTests=true -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -B -V'
    }
}


def unitTest() {
    stage ('Unit tests') {
      mvn 'test -B -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true'
    }
}

def allTests() {
    stage ('All tests') {
      // don't skip anything
      mvn 'test -B'
    }
}

def mvn(args) {
    sh "mvn ${args} -Dmaven.repo.local=/github/workspace/.m2"
}
```

There are some things to point out with this example:
* the commit who triggered the action is placed by GitHub Actions into ```/github/workspace``` and the ```checkoutSource``` function is just doing a file copy of all files in this directory to the job's workspace (can probably be optimized)
* maven's local repo is set to ```/github/workspace/.m2``` as the workspace directory is [shared across actions](https://developer.github.com/actions/creating-github-actions/accessing-the-runtime-environment/#filesystem) of the same workflow
* so far, Jenkins environmental variables are not populated based on the [GitHub Actions context](https://developer.github.com/actions/creating-github-actions/accessing-the-runtime-environment/#environment-variables) - instead, the GitHub Action environmental variable ```GITHUB_REF```
* there is no need to explicitly set the commit status after the build finishes as GitHub Actions will do this automatically based on the exit code of the wrapped action
* the ```mysh```function is used to not show shell glob expansion or ```GITHUB_SECRET``` in the Jenkinsfile


![image](https://user-images.githubusercontent.com/1872314/47358580-64579780-d6ca-11e8-8f75-484bdc661a10.png)


## Local Trouble-shooting / customize the packaged Jenkins and plugins

#### Jenkinsfile-Runner Prepackaged

```bash
docker pull jonico/jenkinsfile-runner-prepackaged
```

or if you like to build the Docker image from scratch

```bash

git clone https://github.com/jenkinsci/jenkinsfile-runner-github-actions.git

cd jenkinsfile-runner-github-actions/jenkinsfile-runner-prepackaged

docker build -t jenkinsci/jenkinsfile-runner-prepackaged .
```

Then, cd to your git repo that contains your Jenkinsfile and mount it to ```/github/workspace``` while running the docker container

```bash
cd <your-repo>

docker run --rm -it -v $(pwd):/github/workspace  jenkinsci/jenkinsfile-runner-prepackaged
```

If you are using environmental variables in your ```Jenkinsfile```, you would have to specify them using the "-e" command line option for docker:

```bash
docker run --rm -it -v $(pwd):/github/workspace -e GITHUB_REPOSITORY=jenkinsci/reading-time-app -e GITUB_GITHUB_REF=refs/heads/create-releases -e GITHUB_ACTION=jenkinsfile-runner-prepackaged -e GITHUB_SHA=mysha-3 -e GITHUB_TOKEN=<redacted> jenkinsci/jenkinsfile-runner-prepackaged
```

In case you like to modify the [Docker base image](https://hub.docker.com/r/jonico/jenkinsfile-runner-github-action/) that defines which version of Jenkins and which plugins are included, you find the Dockerfile [here](https://github.com/jenkinsci/jenkinsfile-runner/blob/master/Dockerfile).


## Current Limitations / TODOs

This is just a POC, in order to productize this, you would probably
* [Automate](https://jenkins.io/blog/2018/10/16/custom-war-packager/#jenkinsfile-runner-packaging) the creation of the pre-packaged Jenkins Docker container
* populate Jenkins environmental variables based on the [GitHub Actions context](https://developer.github.com/actions/creating-github-actions/accessing-the-runtime-environment/#environment-variables)
* Find a better way to populate the job workspace with the content of ```/github/workspace``` other than manually copying the files over as part of your ```Jenkinsfile```
* Find a better way to package maven binaries and additional plugins
* Find a better way to share maven plugins other than manually mapping the local maven repo to ```/github/workspace/.m2``` in your ```Jenkinsfile```
* Find a better way to cache the lazy-loaded Jenkins as ```/github/workspace/.jenkinsfile-runner-cache``` as specified [here](https://github.com/jonico/jenkinsfile-runner-github-actions/blob/master/jenkinsfile-runner-lazyloaded/Dockerfile#L19)
* Add examples of how to work with [Jenkins secrets](https://github.com/ndeloof/jenkinsfile-runner#sensitive-data)
* Provide examples how to copy parts of the Jenkins results to an external storage
