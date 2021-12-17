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
        stage('Helm Build and Push') {
            agent { label agents.K8S }
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
                script {
                    sh "./cicd/build/create.values.sh ${image}"
                    sh "helm package ./charts"
                    env.CHART_VERSION = sh returnStdout: true, script: 'printf "$(cat "./charts/Chart.yaml" | grep version | cut -d\':\' -f2 | xargs)"'
                    env.CHART_PACKAGE = "knative-starter-${CHART_VERSION}.tgz"

                    echo 'Pushing helm chart to artifactory'
                    // def fileSHA = sha1 "./${CHART_PACKAGE}" TODO: Add checksum to artifactory push
                    sh 'curl -u "${ARTIFACTORY_USR}":"${ARTIFACTORY_PSW}" -T ./"${CHART_PACKAGE}" -X PUT https://artifactory.remscripts.com/artifactory/helm-virtual/'
                }
            }
        }
        stage('Build from version branch') {
            agent { label agents.K8S }
            when {
                not {
                    anyOf {
                        branch pattern: BRANCH_PATTERN_EXCLUDE_BUILD, comparator: REGEXP
                    }
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: '804df528-14cc-4b95-ab95-18a208048c84', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                    script {
                        sh "./cicd/build/build.version.sh dev ${appName} ${appVersion}"
                        env.IMAGE_VERSION = readFile 'build.version'
                        env.IMAGE_VERSION = env.IMAGE_VERSION.trim()
                        build job: '/adherence/deploy-service', parameters: [string(name: 'APPLICATION', value: "${appName}"), string(name: 'VERSION', value: "${IMAGE_VERSION}"), string(name: 'ENVIRONMENT', value: "dev")]
                    }
                }
                withAWS(role: AWS_ROLE, roleAccount: ROLE) {
                    script {
                        // Fetching the URL
                        sh "aws eks --region us-east-1 update-kubeconfig --name adherence-dev"
                        sh "./cicd/deploy/verify.deploy.sh ${PROJECT_NAME} ${PROJECT_NAME} 0"
                        env.BASE_URL = readFile 'host.url'
                        env.BASE_URL = env.BASE_URL.trim()
                    }
                }
            }
        }
    }
}
