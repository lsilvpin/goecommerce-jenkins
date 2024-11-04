#!/bin/bash

docker run --rm -v jenkins_home:/data -v $(pwd):/backup busybox tar xzf /backup/jenkins_home_backup.tar.gz -C /data
