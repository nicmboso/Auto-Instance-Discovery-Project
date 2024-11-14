pipeline {
  agent any
  tools {
    terraform 'terraform'
  }
  // stages {
  //   stage('trivy scan') {
  //     steps {
  //       // Run the Trivy scan and save the output in HTML format
  //       sh 'trivy fs --scanners misconfig --format json -o trivy-report.html . || true'
  //       // Archive the HTML report as a build artifact
  //       archiveArtifacts artifacts: 'trivy-report.html', allowEmptyArchive: true
  //       // Publish the HTML report
  //       publishHTML(target: [
  //         reportDir: '.', 
  //         reportFiles: 'trivy-report.html',
  //         reportName: "Trivy CVE Report", 
  //         keepAll: true, 
  //         alwaysLinkToLastBuild: true, 
  //         includeInIndex: true, 
  //         indexFilename: 'index.html'
  //       ])
  //     }
  //   }
    stage('terraform init') {
      steps {
        sh 'terraform init'
      }
    }
    stage('terraform format') {
      steps {
        sh 'terraform fmt --recursive'
      }
    }
    stage('terraform validate') {
      steps {
        sh 'terraform validate'
      }
    }
    stage('terraform plan') {
      steps {
        sh 'terraform plan'
      }
    }
    stage('terraform action') {
      steps {
        sh 'terraform ${action} -auto-approve'
      }
    }
  }
