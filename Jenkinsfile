#!/usr/bin/env groovy

def scmCredentialsID = '804df528-14cc-4b95-ab95-18a208048c84'
library identifier: 'jenkins-shared@MA30-511-normalize-knative-install',
    retriever: modernSCM([
      $class: 'GitSCMSource',
      credentialsId: scmCredentialsID,
      remote: 'https://github.com/mscripts-adherence/jenkins-shared.git'
])

def agents = [ K8S: 'k8s', DOCKER: 'docker', NPM: 'npm' ]

pipeline {
    triggers {
        upstream(
            upstreamProjects: "adherence/shared-schemas/main",
            threshold: hudson.model.Result.SUCCESS)
    }
    agent {
        label agents.NPM
    }
    stages {
        stage('Setup') {
            steps {
                script {
                    env.RT_HOST = 'artifactory.remscripts.com'
                    env.RT_PORT = '5001'
                    env.RT_URL = "https://${env.RT_HOST}/artifactory"
                    env.DOCKER_BASE = 'artifactory.remscripts.com:5001'
                    env.RT_CRED_ID = 'jenkins-artifactory-credentials'
                    env.AWS_ROLE = 'JenkinsMasterTaskRole'
                    env.BRANCH_PATTERN_EXCLUDE_BUILD = 'main|version|develop|PR-\\d+'
                    env.REGEXP = 'REGEXP'
                    env.DEPLOY_ENV = environmentForBranch(env.BRANCH_NAME)
                    env.CONTEXT = awsContextForEnvironment(env.DEPLOY_ENV)
                    env.ROLE_ACCOUNT = awsAccountForContext(env.CONTEXT)
                    env.PREFIX = 'adherence'
                    env.appName = 'knative-starter'
                    env.appVersion = sh returnStdout: true, script: "node -e 'console.log(require(\"./package.json\").version)'"
                }
                withAWS(role: AWS_ROLE, roleAccount: ROLE_ACCOUNT) {
                    script {
                        env.GH_TOKEN = sh returnStdout: true, script: "aws ssm get-parameters --names '/adherence/semantic-release/gh-token' --with-decryption --output text | cut -d\$'\t' -f 7 | tr -d '\n'"
                    }
                }
            }
        }
        stage('KNative test') {
            agent { label agents.K8S }
            steps {
                withAWS(role: AWS_ROLE, roleAccount: ROLE_ACCOUNT) {
                    script {
                        sh "aws eks --region us-east-1 update-kubeconfig --name adherence-${DEPLOY_ENV}"
                        ensureKNativeInstallation()
                    }
                }
            }
        }
        stage('Docker Build and Push') {
            agent { label agents.DOCKER }
            when {
                not {
                    anyOf {
                        branch pattern: BRANCH_PATTERN_EXCLUDE_BUILD, comparator: REGEXP
                    }
                }
            }
            environment {
                ARTIFACTORY = credentials("$RT_CRED_ID")
            }
            steps {
                withDockerRegistry(url: "https://$DOCKER_BASE", credentialsId: "$RT_CRED_ID") {
                    script {
                        sh "./cicd/build/build.docker.sh ${env.appName} ${env.appVersion}"
                        def image = readFile encoding: 'UTF-8', file: "docker.version"
                        sh "docker push ${image}"
                        sh "docker image prune -af"
                        env.IMAGE = sh returnStdout: true, script: 'printf "$(cat "build.version" | cut -d\':\' -f2 | xargs)"'
                    }
                }
            }
        }
    }
}
