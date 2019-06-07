#!/usr/bin/env groovy
import com.jobteaser.pipeline.GithubFlow
import com.jobteaser.pipeline.packager.DockerPackager

def packager = new DockerPackager()

new GithubFlow(this)
  .withPhase('package', packager)
  .run()
