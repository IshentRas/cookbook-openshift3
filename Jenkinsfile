#!groovy


try {
  properties([parameters([
    string(name: 'BRANCH_NAME',                                  defaultValue: env.BRANCH_NAME,                                description: 'Branch to build'),
    string(name: 'builddir',                                     defaultValue: 'cookbook-openshift3-test-' + env.BUILD_NUMBER, description: 'Build directory'),
    string(name: 'nodename',                                     defaultValue: 'cage',                                         description: 'Node to build on'),
    string(name: 'CHEF_VERSION',                                 defaultValue: '12.16.42-1',                                   description: 'Chef version to use, eg 12.4.1-1'),
    string(name: 'OSE_VERSIONS',                                 defaultValue: '1.3 1.4 1.5 3.6',                                  description: 'OSE versions to build, separated by spaces'),
    string(name: 'CHEF_IPTABLES_COOKBOOK_VERSION',               defaultValue: 'latest',                                       description: 'iptables cookbook version, eg 1.0.0'),
    string(name: 'CHEF_SELINUX_COOKBOOK_VERSION',                defaultValue: 'latest',                                       description: 'selinux cookbook version, eg 0.7.2'),
    string(name: 'CHEF_YUM_COOKBOOK_VERSION',                    defaultValue: 'latest',                                       description: 'yum cookbook version, eg 3.6.1'),
    string(name: 'CHEF_COMPAT_RESOURCE_COOKBOOK_VERSION',        defaultValue: 'latest',                                       description: 'compat_resource cookbook version'),
    string(name: 'CHEF_INJECT_COMPAT_RESOURCE_COOKBOOK_VERSION', defaultValue: 'false',                                        description: 'whether to inject compat_resource cookbook version (eg true for some envs)'),
    booleanParam(name: 'dokitchen',                              defaultValue: true,                                           description: 'Whether to run kitchen tests'),
    booleanParam(name: 'doshutit',                               defaultValue: true,                                           description: 'Whether to run shutit tests'),
    booleanParam(name: 'dorubocop',                              defaultValue: true,                                           description: 'Whether to run rubocop tests')
  ])])
  lock('cookbook_openshift3_tests') {
    stage('setupenv') {
      node(nodename) {
        sh 'mkdir -p ' + builddir
        dir(builddir) {
          ////when in source...
          checkout([$class: 'GitSCM', branches: [[name: '*/' + env.BRANCH_NAME]], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'SubmoduleOption', disableSubmodules: false, parentCredentials: false, recursiveSubmodules: true, reference: '', trackingSubmodules: false]], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/IshentRas/cookbook-openshift3']]])
        }
      }
    }
    stage('debug') {
        node(nodename) {
            sh 'env'
            sh 'echo ' + dokitchen
            sh 'echo ' + doshutit
            sh 'echo ' + dorubocop
        }
    }
    if (params.dorubocop) {
      stage('rubocop') {
        node(nodename) {
          dir(builddir) {
            sh 'rubocop -r cookstyle -D'
          }
        }
      }
    }
    if (params.doshutit) {
      stage('shutit_tests') {
        node(nodename) {
          dir(builddir) {
            sh 'git clone --recursive --depth 1 https://github.com/ianmiell/shutit-openshift-cluster'
            dir('shutit-openshift-cluster') {
              withEnv(["SHUTIT=/usr/local/bin/shutit"]) {
                sh './run_tests.sh --interactive 0'
              }
            }
          }
        }
      }
    }
    if (params.dokitchen) {
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

''', cc: '', from: 'cookbook-openshift3@jenkins.meirionconsulting.tk', replyTo: '', subject: 'Build OK', to: 'ian.miell@gmail.com, william17.burton@gmail.com, julien.perville@perfect-memory.com'
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

''' + err, cc: '', from: 'cookbook-openshift3@jenkins.meirionconsulting.tk', replyTo: '', subject: 'Build failure', to: 'ian.miell@gmail.com, william17.burton@gmail.com, julien.perville@perfect-memory.com'
  throw(err)
  if (params.doshutit) {
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
}
