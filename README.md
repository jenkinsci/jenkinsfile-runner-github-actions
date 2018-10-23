# GitHub Actions POC for Jenkins Single-shot master

This is an unofficial POC how to run [Jenkins Single-shot masters](https://schd.ws/hosted_files/devopsworldjenkinsworld2018/8f/DWJW2018%20-%20A%20Cloud%20Native%20Jenkins.pdf) inside a [GitHub Action Workflow](https://blog.github.com/2018-10-17-action-demos/).

![image](https://user-images.githubusercontent.com/1872314/47345918-3b280e80-d6ac-11e8-9f44-8cc02754f691.png)

Any GitHub project with a ```Jenkinsfile```can use those actions to execute its defined workflow inside a Docker container run by GitHub that spawns up a new Jenkins master, executes the tests and exits.

The commit that triggered the GitHub Action is [automatically mapped](https://developer.github.com/actions/creating-github-actions/accessing-the-runtime-environment/#filesystem) to ```/github/workspace``` in the Jenkins Docker container. Test results are reported back to the corresponding pull requests.

![image](https://user-images.githubusercontent.com/1872314/47347618-ed150a00-d6af-11e8-87f7-e425c6a43867.png)


![image](https://user-images.githubusercontent.com/1872314/47346015-732f5180-d6ac-11e8-9fbd-9c534e7b3f34.png)

## Available GitHub Actions

The POC comes with two actions:

#### [jenkinsfile-runner-prepackaged](https://github.com/jonico/jenkinsfile-runner-github-actions/tree/master/jenkinsfile-runner-prepackaged) (recommended)

Uses the [official Jenkinsfile-Runner](https://github.com/jenkinsci/jenkinsfile-runner) and prepackages Jenkins 2.138.2 and Maven 3.5.2 with it. There is also a [Dockerfile](https://hub.docker.com/r/jonico/jenkinsfile-runner-prepackaged/) available you could refer to in [your workflow](https://help.github.com/articles/about-github-actions/#about-workflows) if you do not like to [refer to the source](https://github.com/jonico/jenkinsfile-runner-github-actions/tree/master/jenkinsfile-runner-prepackaged).

#### [jenkinsfile-runner-lazyloaded](https://github.com/jonico/jenkinsfile-runner-github-actions/tree/master/jenkinsfile-runner-lazyloaded)

Uses [an alternative Jenkinsfile-Runner implementation](https://github.com/ndeloof/jenkinsfile-runner) that first downloads the latest version of Jenkins LTS and all plugins specified in ```plugins.txt``` in the commit that is triggering the GitHub Action. There is also a [Dockerfile](https://hub.docker.com/r/jonico/jenkinsfile-runner-lazyloaded/) available you could refer to in [your workflow](https://help.github.com/articles/about-github-actions/#about-workflows) if you do not like to [refer to the source](https://github.com/jonico/jenkinsfile-runner-github-actions/tree/master/jenkinsfile-runner-lazyloaded).

## How to use the actions

Here is an example [GitHub Action workflow](https://help.github.com/articles/about-github-actions/#about-workflows) that shows how to use the actions in parallel:

```
workflow "Jenkins single-shot master" {
  on = "push"
  resolves = ["jenkinsfile-runner-lazyloaded", "jenkinsfile-runner-prepackaged"]
}

action "jenkinsfile-runner-prepackaged" {
  uses = "jonico/jenkinsfile-runner-github-actions/jenkinsfile-runner-prepackaged@master"
}

action "jenkinsfile-runner-lazyloaded" {
  uses = "docker://jonico/jenkinsfile-runner-lazyloaded"
}
```

For anything else but demonstration purposes, you probably only want to run one approach (and not both in parallel).

For this case, just remove the action you do not need from the [```resolves```](https://developer.github.com/actions/creating-workflows/workflow-configuration-options/#workflow-blocks) attribute of the workflow.

## An example Jenkinsfile that was tested with this

```groovy
#!groovy

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
    }
}

def checkoutSource() {
  stage ('checkoutSource') {
    // as the commit that triggered that Jenkins action is already mapped to /github/workspace, we just copy that to the workspace
    copyFilesToWorkSpace()
  }
}

def copyFilesToWorkSpace() {
  sh "cp -r /github/workspace/* $WORKSPACE"
}

def build () {
    stage ('Build') {
      mvn 'clean install -DskipTests=true -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -B -V'
    }
}


def unitTest() {
    stage ('Unit tests') {
      mvn 'test -B -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true'
      step([$class: 'JUnitResultArchiver', testResults: '**/target/surefire-reports/TEST-*.xml'])
      if (currentBuild.result == "UNSTABLE") {
          sh "exit 1"
      }
    }
}

def allTests() {
    stage ('All tests') {
      // don't skip anything
      mvn 'test -B'
      step([$class: 'JUnitResultArchiver', testResults: '**/target/surefire-reports/TEST-*.xml'])
      if (currentBuild.result == "UNSTABLE") {
          // input "Unit tests are failing, proceed?"
          sh "exit 1"
      }
    }
}

def mvn(args) {
    sh "mvn ${args} -Dmaven.test.failure.ignore -Dmaven.repo.local=/github/workspace/.m2"
}
```

There are some things to point out with this example:
* the commit who triggered the action is placed by GitHub Actions into ```/github/workspace``` and the ```checkoutSource``` function is just doing a file copy of all files in this directory to the job's workspace (can probably be optimized)
* maven's local repo is set to ```/github/workspace/.m2``` as the workspace directory is [shared across actions](https://developer.github.com/actions/creating-github-actions/accessing-the-runtime-environment/#filesystem) of the same workflow
* so far, Jenkins environmental variables are not populated based on the [GitHub Actions context](https://developer.github.com/actions/creating-github-actions/accessing-the-runtime-environment/#environment-variables) - instead, the GitHub Action environmental variable ```GITHUB_REF```
* there is no need to explicitly set the commit status after the build finishes as GitHub Actions will do this automatically based on the exit code of the wrapped action


![image](https://user-images.githubusercontent.com/1872314/47358580-64579780-d6ca-11e8-8f75-484bdc661a10.png)


## Local Trouble-shooting / customize the packaged Jenkins and plugins

#### Jenkinsfile-Runner Prepackaged

```bash
docker pull jonico/jenkinsfile-runner-prepackaged
```

or if you like to build the Docker image from scratch

```bash

git clone https://github.com/jonico/jenkinsfile-runner-github-actions.git

cd jenkinsfile-runner-github-actions/jenkinsfile-runner-prepackaged

docker build -t jonico/jenkinsfile-runner-prepackaged .
```

Then, cd to your git repo that contains your Jenkinsfile and mount it to ```/github/workspace``` while running the docker container

```bash
cd <your-repo>

docker run --rm -it -v $(pwd):/github/workspace  jonico/jenkinsfile-runner-prepackaged
```

In case you like to modify the [Docker base image](https://hub.docker.com/r/jonico/jenkinsfile-runner-github-action/) that defines which version of Jenkins and which plugins are included, you find the Dockerfile [here](https://github.com/jonico/jenkinsfile-runner/blob/master/Dockerfile).

#### Jenkinsfile-Runner Lazyloaded

```bash
docker pull jonico/jenkinsfile-runner-lazyloaded
```

or if you like to build the Docker image from scratch

```bash

git clone https://github.com/jonico/jenkinsfile-runner-github-actions.git

cd jenkinsfile-runner-github-actions/jenkinsfile-runner-lazyloaded

docker build -t jonico/jenkinsfile-runner-lazyloaded .
```

Then, cd to your git repo that contains your Jenkinsfile and mount it to ```/github/workspace``` while running the docker container

```bash
cd <your-repo>

docker run --rm -it -v $(pwd):/github/workspace  jonico/jenkinsfile-runner-lazyloaded
```

The customization of the [underlying Docker base image](https://hub.docker.com/r/jenkins/jenkinsfile-runner/) can be done [by customizing this repo](https://github.com/ndeloof/jenkinsfile-runner).

## Current Limitations / TODOs

This is just a POC, in order to productize this, you would probably
* [Automate](https://jenkins.io/blog/2018/10/16/custom-war-packager/#jenkinsfile-runner-packaging) the creation of the pre-packaged Jenkins Docker container
* populate Jenkins environmental variables based on the [GitHub Actions context](https://developer.github.com/actions/creating-github-actions/accessing-the-runtime-environment/#environment-variables)
* Find a better way to populate the job workspace with the content of ```/github/workspace``` other than manually copying the files over as part of your ```Jenkinsfile```
* Find a better way to package maven binaries and additional plugins
* Find a better way to share maven plugins other than manually mapping the local maven repo to ```/github/workspace/.m2``` in your ```Jenkinsfile```
* Find a better way to cache the lazy-loaded Jenkins as ```/github/workspace/.jenkinsfile-runner-cache``` as specified [here](https://github.com/jonico/jenkinsfile-runner-github-actions/blob/master/jenkinsfile-runner-lazyloaded/Dockerfile#L19)
* Add examples of how to work with [injected GitHub Action secrets](https://developer.github.com/actions/creating-workflows/storing-secrets/) and additional [Jenkins secrets](https://github.com/ndeloof/jenkinsfile-runner#sensitive-data)
* Provide examples how to copy parts of the Jenkins results to an external storage
