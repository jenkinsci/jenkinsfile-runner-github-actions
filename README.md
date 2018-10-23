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

Here is an example workflow how to use the actions:

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


## Current Limitations / TODOs

This is just a POC, in order to productize this, you would probably
* [Automate](https://jenkins.io/blog/2018/10/16/custom-war-packager/#jenkinsfile-runner-packaging) the creation of the pre-packaged Jenkins Docker container
* populate Jenkins environmental variables based on the [GitHub Actions context](https://developer.github.com/actions/creating-github-actions/accessing-the-runtime-environment/#environment-variables)
* Find a better way to populate the job workspace with the content of ```/github/workspace``` other than manually copying the files over as part of your ```Jenkinsfile```
* Find a better way to package maven binaries and additional plugins
* Find a better way to share maven plugins other than manually mapping the local maven repo to ```/github/workspace/.m2``` in your ```Jenkinsfile```
* Add examples of how to work with [injected GitHub Action secrets](https://developer.github.com/actions/creating-workflows/storing-secrets/) and additional [Jenkins secrets](https://github.com/ndeloof/jenkinsfile-runner#sensitive-data)
* Provide examples how to copy parts of the Jenkins results to an external storage
