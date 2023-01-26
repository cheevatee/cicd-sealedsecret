pipeline {
  agent any
  environment{
      APP_NAME = "demo-app01"
      GIT_REPO = "gitlab.apps.cluster-f5kff.sandbox229.opentlc.com/gitlab-instance-8f5c09e5/cicd-sealedsecret.git"
      GIT_BRANCH = "main"
      OPENSHIFT_DOMAIN = "cluster-f5kff.sandbox229.opentlc.com"
      OPENSHIFT_PROJECT = "demo-poc"
      OPENSHIFT_REGISTRY_ROUTE = "default-route-openshift-image-registry.apps.cluster-f5kff.sandbox229.opentlc.com"
      KUBESEAL_DOWNLOAD_URL = "https://github.com/bitnami-labs/sealed-secrets/releases/download"
      KUBESEAL_VERSION = "0.18.2"
            EMAIL_RECIPIENT = "root@bastion.f5kff.internal"
}
  stages {
    stage ("Prompt for input Secret") {
      steps {
        script {
          env.SECRET = input message: 'Please enter the secret value.',
                             parameters: [string(defaultValue: '',
                                          description: '',
                                          name: 'Secret')]
        }
        echo "Secret: $SECRET"
      }
    }
    stage('Login to OpenShift') {
      steps {
        withCredentials([usernamePassword(
                  credentialsId: 'openshift-login-api',
                  usernameVariable: 'OCP_USERNAME',
                  passwordVariable: 'OCP_PASSWORD',
                )]) {
                sh "oc login api.${OPENSHIFT_DOMAIN}:6443 --insecure-skip-tls-verify -u ${OCP_USERNAME} -p ${OCP_PASSWORD}"
                }
      }
    }
    stage('Delete Project') {
      steps {
          sh 'oc delete project $OPENSHIFT_PROJECT; sleep 60'
      }
    }
    stage('Create Project') {
      steps {
        echo 'Create Project'
        script {
            sh 'oc new-project $OPENSHIFT_PROJECT'
            sh 'oc project $OPENSHIFT_PROJECT'
            echo "Using project: $OPENSHIFT_PROJECT"
        }
      }
    }
    stage('Build Application') {
      steps {
        echo 'Build container image'
        script {
            sh 'oc new-build --name $APP_NAME --binary=true --strategy=docker'
            sh 'oc start-build $APP_NAME --from-dir=. --wait --follow'
        }
      }
    }
    stage('Verify Application') {
      steps {
        echo 'Run check container image created'
        sh 'oc get is|grep -i "latest"'
      }
    }
    stage('Deploy Approval'){
      steps {
                emailext body: 'Project - $PROJECT_NAME - Build # $BUILD_NUMBER : Wait for deploy approval', subject: 'Project $PROJECT_NAME wait for deploy approval!!!', to: "$EMAIL_RECIPIENT"
        input "Deploy $APP_NAME application into $OPENSHIFT_PROJECT project?"
      }
    }
    stage('Deploy Application') {
      steps {
        echo 'Deploy application'
        script {
            sh 'oc new-app --insecure-registry=true --name $APP_NAME $OPENSHIFT_REGISTRY_ROUTE/$OPENSHIFT_PROJECT/$APP_NAME'
        }
      }
    }
    stage('Sealed & Inject Application Secret') {
      steps {
        echo 'Create application secret'
        script {
            sh 'wget $KUBESEAL_DOWNLOAD_URL/v$KUBESEAL_VERSION/kubeseal-$KUBESEAL_VERSION-linux-amd64.tar.gz'
            sh 'ls -l kubeseal-$KUBESEAL_VERSION-linux-amd64.tar.gz'
            sh 'tar -xzvf kubeseal-$KUBESEAL_VERSION-linux-amd64.tar.gz kubeseal'
            sh 'ls -l kubeseal'
            sh 'oc create secret generic $APP_NAME --dry-run=client --from-literal=$APP_NAME=$SECRET -o yaml|./kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets --format yaml > $APP_NAME-sealedsecret.yaml'
            sh 'ls -l $APP_NAME-sealedsecret.yaml'
            sh 'cat $APP_NAME-sealedsecret.yaml'
            sh 'rm -rf kubeseal-$KUBESEAL_VERSION-linux-amd64.tar.gz kubeseal'
            sh 'oc create -f $APP_NAME-sealedsecret.yaml'
            sh 'oc set volume deploy/$APP_NAME --add --name $APP_NAME --type secret --secret-name $APP_NAME --mount-path=/var/www/html/$APP_NAME --sub-path=$APP_NAME --read-only=true'
        }
      }
    }

    stage('Update GIT') {
      steps {
        script {
          catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
            withCredentials([usernamePassword(credentialsId: 'git-login', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                def encodedPassword = URLEncoder.encode("$GIT_PASSWORD",'UTF-8')
                sh "git config user.email ${GIT_USERNAME}@$OPENSHIFT_DOMAIN"
                sh "git config user.name ${GIT_USERNAME}"
                sh 'git status'
//                sh "git add ."
                sh "git add $APP_NAME-sealedsecret.yaml"
                sh "git commit -m 'Triggered Build: ${env.BUILD_NUMBER}'"
                sh "git -c http.sslVerify=false push https://${GIT_USERNAME}:${encodedPassword}@$GIT_REPO HEAD:$GIT_BRANCH"
                sh 'git status'
            }
          }
        }
      }
    }


    stage('Expose Application') {
      steps {
        echo 'Expose Route'
        script {
            sh 'oc expose svc/$APP_NAME'
        }
      }
    }
  }
}
