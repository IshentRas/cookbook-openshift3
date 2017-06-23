#!groovy

def nodename='cage'
def builddir='cookbook-openshift3-test-' + env.BUILD_NUMBER
def branch=env.BRANCH_NAME


try {
  lock('cookbook_openshift3_tests') {
    stage('setupenv') {
      node(nodename) {
        sh 'mkdir -p ' + builddir
        dir(builddir) {
          ////when in source...
          checkout([$class: 'GitSCM', branches: [[name: '*/' + branch]], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'SubmoduleOption', disableSubmodules: false, parentCredentials: false, recursiveSubmodules: true, reference: '', trackingSubmodules: false]], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/IshentRas/cookbook-openshift3']]])
        }
      }
    }

    stage('rubocop') {
      node(nodename) {
        dir(builddir) {
          sh 'rubocop -r cookstyle -D'
        }
      }
    }

    stage('shutit_tests') {
      node(nodename) {
        dir(builddir) {
          sh 'git clone --recursive --depth 1 https://github.com/ianmiell/shutit-openshift-cluster'
          dir('shutit-openshift-cluster') {
            withEnv(["SHUTIT=/usr/local/bin/shutit"]) {
              sh 'COOKBOOK_VERSION=' + branch + ' ./run_tests.sh --interactive 0'
            }
          }
        }
      }
    }
    stage('kitchen') {
      node(nodename) {
        dir(builddir) {
          def l = sh(script: 'kitchen list -b', returnStdout: true).trim().tokenize()
          for (f in l) {
            // Seeing persistent 'SCP did not finish successfully (255):  (Net::SCP::Error)' errors, so retry added.
            retry(10) {
              sh('kitchen converge ' + f)
              sh('kitchen verify ' + f)
              sh('kitchen destroy ' + f)
            }
          }
        }
      }
    }
  }
  mail bcc: '', body: '''See: http://jenkins.meirionconsulting.tk/job/cookbook-openshift3-pipeline

RELEASE
=======
- document diff to last tag
- up the metadata value
- tag the cookbook app, commit push
- commit
- git push --tag
- knife cookbook site share cookbook-openshift3 # on rothko

''', cc: '', from: 'cookbook-openshift3@jenkins.meirionconsulting.tk', replyTo: '', subject: 'Build OK', to: 'ian.miell@gmail.com, william17.burton@gmail.com'
  stage('cleanup') {
    node(nodename) {
      dir(builddir) {
        dir('shutit-openshift-cluster') {
          sh('yes | ./destroy_vms.sh || true')
        }
      }
    }
  }
} catch(err) {
  mail bcc: '', body: '''See: http://jenkins.meirionconsulting.tk/job/cookbook-openshift3-pipeline

''' + err, cc: '', from: 'cookbook-openshift3@jenkins.meirionconsulting.tk', replyTo: '', subject: 'Build failure', to: 'ian.miell@gmail.com, william17.burton@gmail.com'
  throw(err)
  stage('cleanup') {
    node(nodename) {
      dir(builddir) {
        dir('shutit-openshift-cluster') {
          sh('yes | ./destroy_vms.sh || true')
        }
      }
    }
  }
}
