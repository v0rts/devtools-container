/**
 * Jenkins Job DSL Script for DevTools Container Pipeline
 *
 * This script creates a multi-branch pipeline job for building and scanning
 * the DevTools Docker container.
 *
 * Prerequisites:
 * - Job DSL Plugin
 * - Docker Pipeline Plugin
 * - Git Plugin
 * - Pipeline Plugin
 */

pipelineJob('devtools-container') {
    displayName('DevTools Container Build')
    description('Builds, scans, and publishes the secure DevOps tools container')

    // Keep build history
    logRotator {
        numToKeep(30)
        daysToKeep(90)
        artifactNumToKeep(10)
    }

    // Pipeline definition
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/your-org/devtools-container.git')
                        credentials('github-credentials')
                    }
                    branches('main', 'develop')

                    // Extensions
                    extensions {
                        // Clean before checkout
                        cleanBeforeCheckout()

                        // Prune remote branches
                        pruneStaleBranch()

                        // Shallow clone for faster checkout
                        cloneOptions {
                            shallow(true)
                            depth(1)
                            noTags(false)
                        }
                    }
                }
            }
            scriptPath('Jenkinsfile')
            lightweight(true)
        }
    }

    // Triggers
    triggers {
        // Poll SCM every 5 minutes
        scm('H/5 * * * *')

        // GitHub webhook trigger
        githubPush()
    }

    // Parameters
    parameters {
        booleanParam('SKIP_TESTS', false, 'Skip verification tests')
        booleanParam('SKIP_SECURITY_SCAN', false, 'Skip security scanning')
        choiceParam('BUILD_TYPE', ['full', 'quick'], 'Build type (quick skips some layers)')
        stringParam('DOCKER_REGISTRY', 'docker.io', 'Docker registry to push images')
        stringParam('IMAGE_TAG', 'latest', 'Additional tag for the image')
    }

    // Properties
    properties {
        // Disable concurrent builds
        disableConcurrentBuilds()

        // Build discarder
        buildDiscarder {
            strategy {
                logRotator {
                    numToKeepStr('30')
                    daysToKeepStr('90')
                    artifactNumToKeepStr('10')
                }
            }
        }

        // GitHub project
        githubProjectUrl('https://github.com/your-org/devtools-container')
    }

    // Configure the pipeline
    configure { project ->
        // Add build wrapper for timestamps
        project / buildWrappers << 'hudson.plugins.timestamper.TimestamperBuildWrapper'{}

        // Add ANSI color output
        project / buildWrappers << 'hudson.plugins.ansicolor.AnsiColorBuildWrapper' {
            colorMapName('xterm')
        }
    }
}

// Create a separate job for scheduled security scans
pipelineJob('devtools-container-security-scan') {
    displayName('DevTools Container - Security Scan')
    description('Scheduled security scanning of the DevTools container image')

    logRotator {
        numToKeep(20)
        daysToKeep(60)
    }

    definition {
        cps {
            script('''
                pipeline {
                    agent {
                        label 'docker'
                    }

                    options {
                        timestamps()
                        ansiColor('xterm')
                        buildDiscarder(logRotator(numToKeep: 20))
                    }

                    stages {
                        stage('Pull Latest Image') {
                            steps {
                                script {
                                    docker.image('devtools:latest').pull()
                                }
                            }
                        }

                        stage('Security Scan') {
                            steps {
                                sh """
                                    trivy image --severity HIGH,CRITICAL \\
                                        --format json \\
                                        --output trivy-scheduled-scan.json \\
                                        devtools:latest

                                    trivy image --severity HIGH,CRITICAL \\
                                        --format table \\
                                        devtools:latest
                                """
                            }
                        }
                    }

                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-scheduled-scan.json',
                                allowEmptyArchive: true
                        }
                        failure {
                            emailext(
                                subject: "Security Scan Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                                body: "Security vulnerabilities detected in devtools:latest. Check ${env.BUILD_URL}",
                                to: 'devops-team@example.com'
                            )
                        }
                    }
                }
            '''.stripIndent())
            sandbox(true)
        }
    }

    triggers {
        // Run every Sunday at 2 AM
        cron('0 2 * * 0')
    }
}

// Create a folder for DevTools jobs
folder('devtools') {
    displayName('DevTools Container')
    description('Jobs related to the DevTools container')
}

// Create multibranch pipeline for PR testing
multibranchPipelineJob('devtools/devtools-container-pr') {
    displayName('DevTools Container - Pull Requests')
    description('Automated testing for DevTools container pull requests')

    branchSources {
        github {
            id('devtools-container')
            repoOwner('your-org')
            repository('devtools-container')

            // Scan for branches and PRs
            buildOriginBranch(true)
            buildOriginBranchWithPR(false)
            buildOriginPRMerge(true)
            buildOriginPRHead(false)
            buildForkPRMerge(false)
            buildForkPRHead(false)

            // API credentials
            credentialsId('github-credentials')

            // Configure traits
            configure { node ->
                def traits = node / 'sources' / 'data' / 'jenkins.branch.BranchSource' / 'source' / 'traits'

                // Only build PRs
                traits << 'org.jenkinsci.plugins.github__branch__source.BranchDiscoveryTrait' {
                    strategyId(3) // Only pull requests
                }

                // Trust members only
                traits << 'org.jenkinsci.plugins.github__branch__source.ForkPullRequestDiscoveryTrait' {
                    strategyId(1)
                    trust(class: 'org.jenkinsci.plugins.github_branch_source.ForkPullRequestDiscoveryTrait$TrustContributors')
                }
            }
        }
    }

    orphanedItemStrategy {
        discardOldItems {
            numToKeep(10)
        }
    }

    triggers {
        periodicFolderTrigger {
            interval('1h')
        }
    }
}

// View configuration
listView('DevTools Pipelines') {
    description('All DevTools container related pipelines')
    jobs {
        name('devtools-container')
        name('devtools-container-security-scan')
        regex('devtools/.*')
    }
    columns {
        status()
        weather()
        name()
        lastSuccess()
        lastFailure()
        lastDuration()
        buildButton()
    }
}
