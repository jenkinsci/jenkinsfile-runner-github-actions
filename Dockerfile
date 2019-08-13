FROM jonico/jenkinsfile-runner-github-action

LABEL "com.github.actions.name"="Jenkinsfile Runner Prepackaged"
LABEL "com.github.actions.description"="Runs Jenkinsfile in a pre-packaged single-shot master"
LABEL "com.github.actions.icon"="battery"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="http://github.com/jenkinsci/jenkinsfilerunner-github-actions"
LABEL "homepage"="http://github.com/actions"
LABEL "maintainer"="Johannes Nicolai <jonico@github.com>"

ENTRYPOINT ["/app/bin/jenkinsfile-runner", \
            "-w", "/app/jenkins",\
            "-p", "/usr/share/jenkins/ref/plugins",\
            "-f", "/github/workspace"]
