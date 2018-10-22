FROM jenkins/jenkinsfile-runner

LABEL "com.github.actions.name"="Jenkinsfile Runner LazyLoaded"
LABEL "com.github.actions.description"="Runs Jenkinsfile in a single-shot Jenkins master that still has to be downloaded"
LABEL "com.github.actions.icon"="battery-charging"
LABEL "com.github.actions.color"="purple"

LABEL "repository"="http://github.com/jonico/jenkinsfilerunner-github-actions"
LABEL "homepage"="http://github.com/actions"
LABEL "maintainer"="Johannes Nicolai <jonico@github.com>"

RUN mkdir -p /usr/share/maven && \
curl -fsSL https://archive.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz | tar -xzC /usr/share/maven --strip-components=1 && \
ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
ENV MAVEN_HOME /usr/share/maven

ENTRYPOINT ["/usr/local/bin/jenkinsfile-runner", \
            "-file", "/github/workspace/Jenkinsfile", \
            "-cache", "/github/workspace/.jenkinsfile-runner-cache", \
            "-config", "/github/workspace/jenkins.yaml" ]
